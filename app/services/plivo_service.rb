class PlivoService
  
  def initialize(plivo)
    @plivo = plivo
  end

  #LLamar con el mensaje al cliente
  #@throw PlivoCannotCall
  def call_client(client, message, message_calendar = nil)
    raise PlivoChannelFull, "No hay canales disponibles" unless can_call?
    
    return false if client.nil?
    return false if message.nil?

    #http://wiki.freeswitch.org/wiki/Channel_Variables#monitor_early_media_ring
    extra_dial_string = @plivo.extra_dial
    
    phonenumber_client = client.phonenumber
    #el cliente tiene multiples numeros para ubicarle
    if client.phonenumber.include?(',')
      Rails.logger.debug('plivo: client have multiple phonenumbers')
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
      Rails.logger.debug('plivo: phonenumber client %s' % phonenumber_client)
      #se escoge uno aleatorio
      if all_phonenumbers_calleds
        phonenumber_client = phonenumbers[SecureRandom.random_number(phonenumbers.size)]
        Rails.logger.debug('plivo: random picked %s' % phonenumber_client)
      end
    end

    #se agrega prefijo
    phonenumber_client = message.prefix + phonenumber_client.to_s if message.prefix
    return false if phonenumber_client.nil?
    
    caller_id = @plivo.phonenumber
    if !message.caller_id.nil? && message.caller_id.size
      caller_id = message.caller_id
    end
    
    call_params = {
      'From' => caller_id,
      'CallerName' => @privo.caller_name,
      'To' => phonenumber_client,
      'Gateways' => @plivo.gateway_by_client(client),
      'GatewayCodecs' => @plivo.gateway_codecs_quote,
      'GatewayTimeouts' => timeout_by_client(client),
      'GatewayRetries' => @plivo.gateway_retries,
      'ExtraDialString' => extra_dial_string,
      'AnswerUrl' => "%s/plivos/0/answer_client" % @plivo.app_url,
      'HangupUrl' => "%s/plivos/0/hangup_client" % @plivo.app_url,
      'RingUrl' => "%s/plivos/0/ringing_client" % @plivo.app_url,
      
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
    plivocall.plivo_id = @plivo.id
    plivocall.uuid = ''
    plivocall.status = 'calling'
    plivocall.hangup_enumeration = nil
    plivocall.data = sequence.to_yaml
    plivocall.call_id = call.id
    plivocall.end = false
    plivocall.step = 0
    plivocall.save
    call_params['AccountSID'] = plivocall.id

    Rails.logger.debug(call_params)      
    
    #@todo ERROR OCURRE ERROR..SE ENVIA LA LLAMA Y PLIVO RESPONDE DEMASIADO RAPIDO
    #INCLUSIVE ANTES DE GUARDAR LOS REGISTROS
    #PARA MANTENER NUESTRO PROPIO ID utilizamaos el parametro AccountSID de plivo
    plivor = PlivoHelper::Rest.new(@plivo.api_url, @plivo.sid, @plivo.auth_token)
    result = ActiveSupport::JSON.decode(plivor.call(call_params).body)
    Rails.logger.debug('process:' + result.to_s)


    if result["Success"]
      plivocall.uuid = result["RequestUUID"]
      plivocall.save
      return result['RequestUUID']
    else
      Rails.logger.error(result)
      plivocall.destroy
      call.destroy
      client.update_column(:calling, false) 
      return false
    end
  end

end
