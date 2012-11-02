# -*- coding: utf-8 -*-
require 'net/http'
require 'uri'


class PlivoCannotCall < Exception
end

class PlivoChannelFull < Exception
end

class PlivoNotFound < Exception
end


class Plivo < ActiveRecord::Base
  attr_accessible :app_url, :api_url, :auth_token, :campaign_id, :sid, :status, :gateways, :caller_name, :gateway_timeouts, :gateway_retries, :gateway_codecs, :channels, :phonenumber, :enable

  #Plan de marcado, indica como se debe usar
  #los gateway del plivo para el numero a marcar
  #por ejemplo se puede registrir el plivo para ciertos numeros
  attr_accessible :dial_plan
  attr_accessible :dial_plan_desc

  belongs_to :campaign
  has_many :plivo_call

  validates :app_url, :api_url, :sid, :auth_token, :campaign_id, :gateways, :gateway_timeouts, :gateway_retries, :caller_name, :presence => true
  validates :channels, :numericality => true
  validates :gateway_retries, :gateway_timeouts, :numericality => true
  validate :validate_dial_plan

  before_save :verificar_conexion
  before_save :verificar_conexion_app

  #Realiza prueba de conexion
  #al servidor plivo
  def verificar_conexion
    begin
      plivor = PlivoHelper::Rest.new(self.api_url, self.sid, self.auth_token)
      extra_dial_string = "leg_delay_start=1,bridge_early_media=true,hangup_after_bridge=true" 
      call_params = {
        'From' => self.caller_name,
        'To' => '',
        'Gateways' => self.gateways,
        'GatewayCodecs' => self.gateway_codecs,
        'GatewayTimeouts' => self.gateway_timeouts,
        'GatewayRetries' => self.gateway_retries,
        #'AnswerUrl' => answer_client_self_url(),
        #'HangupUrl' => hangup_client_self_url(),
        #'RingUrl' => ringing_client_self_url()
        'ExtraDialString' => extra_dial_string,
        'AnswerUrl' => "%s/0/answer_client" % self.app_url,
        'HangupUrl' => "%s/selfs/0/hangup_client" % self.app_url,
        'RingUrl' => "%s/selfs/0/ringing_client" % self.app_url
      }
      result = ActiveSupport::JSON.decode(plivor.call(call_params).body)
    rescue Errno::ECONNREFUSED => e
      errors.add(:api_url, "Conexion rechazada")
      return false
    rescue Exception => e
      errors.add(:sid, "Fallo autenticación")
      errors.add(:auth_token, "Fallo autenticación")
      errors.add(:api_url, e)
      return false
    end

    return true
  end

  #@todo no funciona
  def verificar_conexion_app
    #Siempre retorna timeout???
    #desde terminal funciona pero desde aqui pailas
    return true
    begin
      uri = URI.parse("%s" % self.app_url.strip)
      r = Net::HTTP.get_response(uri)
      
      
      if not r.body.include?("NeuroTelCal")
        errorsrs.add(:app_url, "Invalido") 
        return false
      end
    rescue Errno::ECONNREFUSED => e
      errors.add(:app_url, "Conexion rechazada")
      return false
    rescue Exception => e
      errors.add(:app_url, "Invalido %s" % e.message)
      return false
    end
    
    return true
  end
    
  
  #Encommila la cadena de los codecs
  def gateway_codecs_quote
    return "'%s'" % gateway_codecs
  end

  def status
    return verificar_conexion ? "Conectado" : "Desconectado"
  end

  def status_app
    return verificar_conexion_app ? "Conectado" : "Desconectado"
  end
  
  #Canales en uso
  def using_channels
    PlivoCall.where(:end => false, :plivo_id => self.id).count()
  end
  
  #pregunta si puede llamara
  #en caso de estar todas los canales ocupados se retorna no
  def can_call?
    uchannels = using_channels
    #logger.debug("Channels %d for plivo %s and now using %s" % [channels, caller_name, using_channels])
    return false if uchannels >= channels
    return true
  end
  


  #LLamar con el mensaje al cliente
  #@throw PlivoCannotCall
  def call_client(client, message, message_calendar = nil)
    raise PlivoChannelFull, "No hay canales disponibles" unless can_call?
    
    return false if client.nil?
    return false if message.nil?

    #http://wiki.freeswitch.org/wiki/Channel_Variables#monitor_early_media_ring
    extra_dial_string = "leg_delay_start=1,bridge_early_media=true,hangup_after_bridge=true" 
    
    phonenumber_client = client.phonenumber
    #el cliente tiene multiples numeros para ubicarle
    if client.phonenumber.include?(',')
      logger.debug('plivo: client have multiple phonenumbers')
      phonenumbers = client.phonenumber.split(',')
      
      all_phonenumbers_calleds = true
      #se busca un numero que no se alla llamado
      phonenumbers.each{|phonenumber|
        unless PlivoCall.where(:number => phonenumber).exists?
          all_phonenumbers_calleds = false
          phonenumber_client = phonenumber
          break
        end
      }
      logger.debug('plivo: phonenumber client %s' % phonenumber_client)
      #se escoge uno aleatorio
      if all_phonenumbers_calleds
        phonenumber_client = phonenumbers[SecureRandom.random_number(phonenumbers.size)]
        logger.debug('plivo: random picked %s' % phonenumber_client)
      end
    end

    #se agrega prefijo
    phonenumber_client = message.prefix + phonenumber_client.to_s if message.prefix
    return false if phonenumber_client.nil?

    call_params = {
      'From' => self.phonenumber,
      'CallerName' => self.caller_name,
      'To' => phonenumber_client,
      #'Gateways' => self.gateways,
      'Gateways' => gateway_by_client(client),
      'GatewayCodecs' => self.gateway_codecs_quote,
      'GatewayTimeouts' => timeout_by_client(client),
      'GatewayRetries' => self.gateway_retries,
      'ExtraDialString' => extra_dial_string,
      'AnswerUrl' => "%s/plivos/0/answer_client" % self.app_url,
      'HangupUrl' => "%s/plivos/0/hangup_client" % self.app_url,
      'RingUrl' => "%s/plivos/0/ringing_client" % self.app_url,
      
    }
    
    if message.retries > 0
      call_params['GatewayRetries'] = message.retries
    end
    
    if message.time_limit > 0
      call_params['TimeLimit'] = message.time_limit.to_i
    end
    
    if message.hangup_on_ring > 0
      #NO FUNCIONA
      #call_params['HangupOnRing'] = message.hangup_on_ring
      call_params['GatewayTimeouts'] = message.hangup_on_ring
    end
    
    client.update_column(:calling, true) 

    
      
    call = Call.new
    call.message_id = message.id
    call.client_id = client.id
    call.length = 0
    call.completed_p = false
    call.enter = Time.now
    call.terminate = nil
    call.enter_listen = nil
    call.terminate_listen = nil
    call.status = 'calling'
    call.hangup_enumeration = nil
    call.message_calendar_id = message_calendar.id unless message_calendar.nil?
    call.save
    
    sequence = message.description_to_call_sequence('!client_fullname' => client.fullname, '!client_id' => client.id)
    
    #Se registra la llamada iniciada de plivo
    plivocall = PlivoCall.new
    plivocall.number = phonenumber_client
    plivocall.plivo_id = self.id
    plivocall.uuid = ''
    plivocall.status = 'calling'
    plivocall.hangup_enumeration = nil
    plivocall.data = sequence.to_yaml
    plivocall.call_id = call.id
    plivocall.end = false
    plivocall.step = 0
    plivocall.save
    call_params['AccountSID'] = plivocall.id

    logger.debug(call_params)      
    
    #@todo ERROR OCURRE ERROR..SE ENVIA LA LLAMA Y PLIVO RESPONDE DEMASIADO RAPIDO
    #INCLUSIVE ANTES DE GUARDAR LOS REGISTROS
    #PARA MANTENER NUESTRO PROPIO ID utilizamaos el parametro AccountSID de plivo
    plivor = PlivoHelper::Rest.new(self.api_url, self.sid, self.auth_token)
    result = ActiveSupport::JSON.decode(plivor.call(call_params).body)
    logger.debug('process:' + result.to_s)


    if result["Success"]
      plivocall.uuid = result["RequestUUID"]
      plivocall.save
      return result['RequestUUID']
    else
      logger.error(result)
      plivocall.destroy
      call.destroy
      client.update_column(:calling, false) 
      return false
    end
  end
 

  def validate_dial_plan
    if not dial_plan.nil?
      
      errors_actions = []
      
      rl = RonelaLenguaje.new do |accion, resto|
        errors_actions << 'Unknow %s' % accion
      end
      
      rl.Match do |vars, rest|
        srexp = rest.join("").strip
        rexp = Regexp.new(srexp)
      end

      lines = dial_plan.split("\n")
      lines.each{|line|
        rl.scan line
      }
      errors.add(:dial_plan, errors_actions.join("\n")) unless errors_actions.empty?
    end    
  end
  
  #Obtiene gateway segun el cliente
  #esto depende del plan de llamadas del plivo
  #::client:: cliente para determinar gateway
  #::return:: string gateway a usar
  def gateway_by_client(client)
    return self.gateways if self.dial_plan.empty? or client.nil?
    
    rl = RonelaLenguaje.new{|accion,resto|
    }
    
    gateway = {}
    use_gateway = self.gateways
    rl.Match do |vars, rest|
      srexp = rest.join("").strip
      rexp = Regexp.new(srexp)

      if rexp =~ client.phonenumber
        use_gateway = vars['gateway'].strip unless vars['gateway'].nil?
        return use_gateway
      end

    end

    #se busca match que encage
    lines = dial_plan.split("\n")
    lines.each{|line| 
      rl.scan(line)
    }

    return use_gateway
  end

  def timeout_by_client(client)
    return self.gateway_timeouts if self.dial_plan.empty? or client.nil?
    
    rl = RonelaLenguaje.new{|accion,resto|
    }
    
    gateway = {}
    use_timeout = self.gateway_timeouts
    rl.Match do |vars, rest|
      srexp = rest.join("").strip
      rexp = Regexp.new(srexp)

      if rexp =~ client.phonenumber
        use_timeout = vars['timeout'].strip unless vars['timeout'].nil?
        return use_timeout
      end

    end

    #se busca match que encage
    lines = dial_plan.split("\n")
    lines.each{|line| 
      rl.scan(line)
    }

    return use_timeout
  end
  
end
