# -*- coding: utf-8 -*-
class Message < ActiveRecord::Base
  attr_accessible :group_id, :description, :name, :processed, :call, :entered, :listened, :anonymous, :call_end, :retries, :hangup_on_ring, :time_limit, :priority
  attr_accessible :max_clients
  attr_accessible :notes
  attr_accessible :last_client_parse_id
  validates :name, :description, :call, :presence => true
  validates :name, :uniqueness => true
  validates :max_clients, :numericality => { :greater_than_or_equal_to => 0 }
  validate :validate_description_call_language

  belongs_to :group
  has_many :message_calendar, :dependent => :destroy

  #?Ya se realizaron las llamadas a todos los clientes?
  def done_calls_clients?
    ncalls = Call.where(:message_id => self.id, :hangup_enumeration => PlivoCall::ANSWER_ENUMERATION).count
    #logger.debug("N %d done calls for message %d for max clients %d cumple %s" % [ncalls, self.id, self.max_clients, (ncalls >= self.max_clients).to_s])
    return ncalls >= self.max_clients
  end
  
  def time_to_process_calendar?
    message_calendar.each{|mc| 
      next unless Time.now >= mc.start and Time.now <= mc.stop
      next if self.max_clients > 0 and (Call.where(:message_calendar_id => self.id, :hangup_enumeration => PlivoCall::ANSWER_ENUMERATION).count + Call.where(:message_calendar_id => self.id, :terminate => nil).count) >= self.max_clients 
      return true
    }
    return false
  end

  def time_to_process?
    return true if Time.now >= call and Time.now <= call_end
    return false
  end
  
  def over_limit_process_channels?(extra_channels = 0)
    return Call.in_process_for_message(id).count >= total_channels_today() + extra_channels
  end
  
  def total_channels_today
    total = 0
    message_calendar.each{|mc| 
      next unless Time.now >= mc.start and Time.now <= mc.stop
      total += mc.channels
    }
    return total
  end
  
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
    when 'Colgar'
      
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

      begin
        def validar_si_exp(exp)
          condiciones = ["=", ">=", "<="]
          exp.strip.scan(/ *(=) *([^\/]+)(.+)$/) do |condicion, valor, subexp|
            subexp[0]  = ''; subexp.strip!; 

            errors.add(:description, 'Condicion invalida solo =' ) unless condiciones.include?(condicion)
            errors.add(:description, 'Invalida sub expresion de Si') if subexp.empty?
            if not subexp.include? '|'
              errors.add(:description, subexp.to_s)
            end            
            errors.add(:description, 'Falta separador de si y no |') unless subexp.include? '|'
            subsexp = subexp.split('|')
            noexp = subexp.slice(subexp.length - subexp.reverse.index('|'), subexp.length)
            siexp = subexp.slice(0, subexp.length - subexp.reverse.index('|') -1)


            asiexp = siexp.split('>')
            asiexp.each_index do |isexp|
              sexp = asiexp[isexp]
              if sexp.include?('Si')
                validar_si_exp(asiexp[isexp..-1].join('>'))
                break
              else
                validate_description_line(sexp)
              end
            end
            
            anoexp = noexp.split('>')
            anoexp.each_index do |isexp|
              sexp = anoexp[isexp]
              if sexp.include?('Si')
                validar_si_exp(anoexp[isexp..-1].join('>'))
                break
              else
                validate_description_line(sexp)
              end
            end
          end
        end
        validar_si_exp(arg)
      rescue Exception => e
        errors.add(:description, e.message)
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
    words = line.gsub(/ +/," ").split
    verb = words[0]
    arg = words[1..-1].join(' ')
    
    case verb
    when 'Si'
      def evaluar_si_exp(exp, replaces)
        condiciones = ["=", ">=", "<="]
        sequencesi = {}
        exp.strip.scan(/ *Si *(=) *([^\/]+)(.+)$/) do |condicion, valor, subexp|
          subexp[0]  = ''; subexp.strip!; 
          sequencesi[:si] = {:condicion => condicion, :valor => valor.strip!}
          sequencesi[:sicontinuar] = [] unless sequencesi[:sicontinuar].is_a? Array
          sequencesi[:nocontinuar] = [] unless sequencesi[:nocontinuar].is_a? Array
          subsexp = subexp.split('|')
          noexp = subexp.slice(subexp.length - subexp.reverse.index('|'), subexp.length); noexp.strip!
          siexp = subexp.slice(0, subexp.length - subexp.reverse.index('|')); siexp.slice!(siexp.length-1,1); siexp.strip!
          asiexp = siexp.split('>')
          asiexp.each_index do |isexp|
            sexp = asiexp[isexp]
            if sexp.include?('Si')
              sexp = asiexp[isexp..-1].join('>')
              sequencesi[:sicontinuar] << evaluar_si_exp(sexp,  replaces)
              break
            else
              sequencesi[:sicontinuar] << description_line_to_call_sequence(sexp, replaces)
            end
          end

          anoexp = noexp.split('>')
          anoexp.each_index do |isexp|
            sexp = anoexp[isexp]
            if sexp.include?('Si')
              sexp = anoexp[isexp..-1].join('>')
              sequencesi[:nocontinuar] << evaluar_si_exp(sexp,  replaces)
              break
            else
              sequencesi[:nocontinuar] << description_line_to_call_sequence(sexp, replaces)
            end
          end
        end
        return sequencesi
      end
      sequencesi = {}
      return evaluar_si_exp('Si ' + arg.to_s, replaces)
      when 'Colgar'
      options = {:colgar => true, :razon => '', :segundos => 0}
      words = arg.scan(/([0-9a-zA-Z\-_\/\\\.ñÑáéíóúÁÉÍÓÚ]+)=([0-9a-zA-Z\-_\/\\\.ñÑáéíóúÁÉÍÓÚ]+|\'[^\']+)/)
      words.each do |word|
        option = word
        option[1][0] = "" if option[1][0] == "'"
        option[1].strip!
        option[0].strip!
        case option[0]
          when 'segundos'
          options[:segundos] = option[1].to_i
          when 'razon'
          options[:razon] = option[1].to_s
        end
      end
      return options
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
          words = arg.scan(/([0-9a-zA-Z\-_\/\\\.ñÑáéíóúÁÉÍÓÚ]+)=([0-9a-zA-Z\-_\/\\\.ñÑáéíóúÁÉÍÓÚ]+|\'[^\']+)/)
          words.each do |word|
            option = word
            option[1][0] = "" if option[1][0] == "'"
            option[1].strip!
            option[0].strip!
            case option[0]
            when 'intentos'
              options[:retries] = option[1].to_i
            when 'duracion'
              options[:timeout] = option[1].to_i
            when 'cantidad'
              options[:numDigits] = option[1].to_i
            when 'digitosValidos'
              options[:validDigits] = option[1].to_s
            when 'audio'
              options[:audio] = option[1].to_s
            when 'decir'
              options[:decir] = option[1]
            else
              #se permite almacenar variables para despues
              begin
                options[option[0].to_s] = option[1]
              rescue
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
