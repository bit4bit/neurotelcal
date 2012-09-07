# -*- coding: utf-8 -*-
class Message < ActiveRecord::Base
  attr_accessible :group_id, :description, :name, :processed, :call, :entered, :listened, :anonymous, :call_end, :retries, :hangup_on_ring, :time_limit
  validates :name, :description, :call, :presence => true
  validates :name, :uniqueness => true

  validate :validate_description_call_language

  belongs_to :group
  has_many :message_calendar, :dependent => :destroy


  def validate_description_line(line)
    verbs = ['Reproducir', 
             'ReproducirLocal',
             'Decir',
             'Registrar',
             'Si', #toma el resultado de lo ultimo evaluado
             'Colgar'
            ]

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
    when 'ReproducirLocal'
      #no se evalua ya que estos archivo estan en el servidor freeswitch
    when 'Registrar'
      register = arg.split[0]
      if register == 'digitos'
      elsif register == 'voz'
      end
    when 'Si'
      condiciones = ["=", ">=", "<="]
      begin
        arg.strip.scan(/ *([^a-zA-Z0-9 ]+) *([^\(]+) *\(([^\)]+)\) *\(([^\)]*)\)/) do |condicion, valor, sicontinuar, nocontinuar|
          errors.add(:description, 'Condicion invalida solo = >= <=' ) unless condiciones.include?(condicion)
          sicontinuar.split('>').each do |linesi|
            validate_description_line(linesi)
          end
          nocontinuar.split('>').each do |lineno|
            validate_description_line(lineno)
          end
        end
      rescue
        errors.add(:description, 'Expresion invalida')
      end
    end
  end
  #Validación del lenguaje para llamadas
  #es muy sencillo se tiene los 2 verbos: Reproducir, Decir
  #Reproducir busca un recurso con el nombre indicado y reproduce
  #Decir intenta usar un sistema de voz para decir lo pasado
  #y variables de tipo
  # $... para valor de campo en tabla cliente. Ej: $nombre
  # <%= %> para ejecutar ruby exp
  #@todo validar lo anterior
  def validate_description_call_language
   

    if not description.nil?

      lines = description.split("\n")
      
      lines.each do |line|
        validate_description_line(line)
      end

    end
  end


  def description_line_to_call_sequence(line, replaces)
    words = line.split
    verb = words[0]
    arg = words[1..-1].join(' ')
    
    case verb
    when 'Si'
      arg.strip.scan(/ *([^a-zA-Z0-9 ]+) *([^\(]+) *\(([^\)]+)\) *\(([^\)]*)\)/) do |condicion, valor, sicontinuar, nocontinuar|
        sicontinuar.strip!
        nocontinuar.strip!

        sicontinuar_sequence = []
        nocontinuar_sequence = []
        sicontinuar.split('>').each do |siexp|
          sicontinuar_sequence << description_line_to_call_sequence(siexp, replaces)
        end

        nocontinuar.split('>').each do |noexp|
          nocontinuar_sequence << description_line_to_call_sequence(noexp, replaces)
        end

        return {:si => {:condicion => condicion, :valor => valor.strip}, :sicontinuar => sicontinuar_sequence, :nocontinuar => nocontinuar_sequence}
      end
    when 'Colgar'
      return {:colgar => true, :segundos => 0}
    when 'ReproducirLocal'
      return {:audio_local => arg}
    when 'Reproducir'
      resource = Resource.where(:campaign_id => group.campaign.id, :type_file => 'audio', :name => arg).first
      return {:audio => resource.file}
    when 'Decir'
      replaces.each do |key, value|
        arg = arg.gsub(key.to_s, value.to_s)
      end
      erb = ERB.new(arg)
      decir_str = erb.result
      logger.debug(decir_str)
      return {:decir => decir_str }
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
            when 'audio'
              options[:audio] = option[2].to_s
            end
          end
        end
        
        logger.debug("Options for get digits " + options.to_s)
        
        return {:register => :digits, :options => options}
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
      sequence << description_line_to_call_sequence(line, replaces)
    end    
    return sequence
  end
end
