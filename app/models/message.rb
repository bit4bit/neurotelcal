# -*- coding: utf-8 -*-
class Message < ActiveRecord::Base
  attr_accessible :group_id, :description, :name, :processed, :call, :entered, :listened, :anonymous, :call_end, :retries, :hangup_on_ring, :time_limit
  validates :name, :description, :call, :presence => true
  validates :name, :uniqueness => true

  validate :validate_description_call_language

  belongs_to :group
  has_many :message_calendar, :dependent => :destroy

  #Validación del lenguaje para llamadas
  #es muy sencillo se tiene los 2 verbos: Reproducir, Decir
  #Reproducir busca un recurso con el nombre indicado y reproduce
  #Decir intenta usar un sistema de voz para decir lo pasado
  #y variables de tipo
  # $... para valor de campo en tabla cliente. Ej: $nombre
  # <%= %> para ejecutar ruby exp
  #@todo validar lo anterior
  def validate_description_call_language
    verbs = ['Reproducir', 
             'ReproducirLocal',
             'Decir',
             'Registrar'
            ]

    if not description.nil?

      lines = description.split("\n")
      
      lines.each do |line|
        words = line.split
        verb = words[0]
        arg = words[1..-1].join(' ')
        unless verbs.include? verb
          errors.add(:description, "Solo verbos %s" % verbs.join(','))
          return false
        end

        case verb
          #Si se indica reproducir se verifica
          #que si exista un recurso audio con el nombre
          #indicado.
        when 'Reproducir'
          resource = Resource.where(:campaign_id => group.campaign.id, :type_file => 'audio', :name => arg).first
          if resource.nil?
            errors.add(:description, 'Recurso [%s] para reproducir no encontrado.' % arg);
          end
        when 'Registrar'
          register = arg.split[0]
          if register == 'digitos'
          elsif register == 'voz'
          end
          
        end
      end

    end
  end


  #Parsea :description y retorna arreglo con la secuencia indicada
  #Se tiene las siguientes acciones:
  # * Decir .... usa speak para decir algo, se puede incluir código ruby <%= %> para consultar en otras tablas, o lo que se quiera
  # * Reproducir Reproduce archivo remoto
  # * ReproducirLocal reproudce archivo donde se encuentre el servidor freeswitch
  #@return array
  def description_to_call_sequence(replaces = {})
    return false unless description
    sequence = []

    lines = description.split("\n")
      
    lines.each do |line|
      words = line.split
      verb = words[0]
      arg = words[1..-1].join(' ')
      
      case verb
      when 'ReproducirLocal'
        sequence << {:audio_local => arg}
      when 'Reproducir'
        resource = Resource.where(:campaign_id => group.campaign.id, :type_file => 'audio', :name => arg).first
        sequence << {:audio => resource.file}
      when 'Decir'
        replaces.each do |key, value|
          arg = arg.gsub(key.to_s, value.to_s)
        end
        erb = ERB.new(arg)
        decir_str = erb.result
        logger.debug(decir_str)
        sequence << {:decir => decir_str }
      when 'Registrar'
        register = arg.split[0]
        case register
          when 'digitos'
          options = {:retries => 1, :timeout => 5, :numDigits => 99, :validDigits => '0123456789*#'}
          words.each do |word|
            if option = word.to_s.match(/([0-9a-zA-Z\-_\/\\\.ñÑáéíóúÁÉÍÓÚ]+)=([0-9a-zA-Z\-_\/\\\.ñÑáéíóúÁÉÍÓÚ]+)/)
              case option[1]
                when 'intentos'
                options[:retries] = option[2].to_i
                when 'duracion'
                options[:timeout] = option[2].to_i
                when 'cantidad'
                options[:numDigits] = option[2].to_i
                when 'digitosValidos'
                options[:validDigits] = option[2].to_s
              end
            end
          end
          
          logger.debug("Options for get digits " + options.to_s)

          sequence << {:register => :digits, :options => options}
          end
      end
    end    
    
    return sequence
  end
end
