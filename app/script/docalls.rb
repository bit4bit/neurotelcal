#!/usr/bin/env /home/bit4bit/ruby/neurotelcal/script/rails runner
# Servidor que realiza las llamadas de NeuroTelcal

require 'plivohelper'
require 'forever'

#Realiza llamadas respectivas de una campana
module Service
  class CampaignCall
    #Se espera que la campana si exista
    def initialize(name)
      case name
        when String
        @campaign = Campaign.where(:name => name).first
        when Campaign
        @campaign = name
      end
      p "Para campana %s at %s" % [@campaign.name, Time.now]
      process_queue
    end

    #Realiza la llamada usando plivo
    #@param Message message mensaje a usar para realizar la llamada
    #@param Client client cliente para llamar
    def docall(message, client)
      if message.valid?
        sequence = message.description_to_call_sequence("!client_id" => client.id)
        extra_dial_string = "leg_delay_start=1,bridge_early_media=true,hangup_after_bridge=true" 
        plivo = @campaign.plivo.first

        if plivo.nil?
          p 'No se encontro servidor plivo valido'
          return
        end
        
        call_params = {
          'From' => plivo.caller_name,
          'To' => client.phonenumber,
          'Gateways' => plivo.gateways,
          'GatewayCodecs' => plivo.gateway_codecs_quote,
          'GatewayTimeouts' => plivo.gateway_timeouts,
          'GatewayRetries' => plivo.gateway_retries,
          #'AnswerUrl' => answer_client_plivo_url(),
          #'HangupUrl' => hangup_client_plivo_url(),
          #'RingUrl' => ringing_client_plivo_url()
          'ExtraDialString' => extra_dial_string,
          'AnswerUrl' => "%s/plivos/0/answer_client" % plivo.app_url,
          'HangupUrl' => "%s/plivos/0/hangup_client" % plivo.app_url,
          'RingUrl' => "%s/plivos/0/ringing_client" % plivo.app_url
        }


        
        begin
          plivor = ::PlivoHelper::Rest.new(plivo.api_url, plivo.sid, plivo.auth_token)
          result = ActiveSupport::JSON.decode(plivor.call(call_params).body)
          
          
          #Se inicio registro de llamada
          call = Call.new
          call.client_id = client.id
          call.message_id = message.id
          call.completed_p = false
          call.length = 0
          call.entered = Time.now
          call.listened = nil
          call.save

          #Se registra la llamada iniciada
          plivocall = PlivoCall.new
          plivocall.uuid = result["RequestUUID"]
          plivocall.status = 'calling'
          plivocall.data = sequence.to_yaml
          plivocall.call_id = call.id
          plivocall.save

        rescue Errno::ECONNREFUSED => e
          p 'No se pudo conectar a plivo en %s' % plivo.api_url
        rescue Exception => e
          p(e)
          p "error:" + e.class.to_s
        end
        
        
      end
      
    end

    #Procesa mensaje y realiza las llamadas indicadas
    def process_queue
      @campaign.message.find_each do |message|
        p("Revisado mensaje %s" % message.name)

        @campaign.client.find_each do |client|
          ncalls = Call.where(:message_id => message.id, :client_id => client.id, :completed_p => true).count

          #si ya se llama no se hace nada
          p("N de llamadas %s para mensaje %s fecha %s" % [ncalls.to_s, message.name, message.call.to_s])
          if ncalls == 0
             if  Time.now >= message.call
               p('[%s] Llamando a %s programada para el %s' % [@campaign.name, client.fullname, message.call.to_s])
               docall(message, client)
             end

          elsif ncalls > 0 

            last_call =  Call.where(:message_id => message.id, :client_id => client.id, :completed_p => true).order("created_at DESC").first

            #realiza llamada si ya se empezo y tiene intevarlo y este se cumple apartir desde la ultima llamada
            if message.call >= Time.now and message.repeat_interval > 0 and  (((Time.now - last_call.created_at) / (3600 * 24)).round % message.repeat_interval) == 0 and message.repeat_until <= Time.now
              p('[%s] Llamando a %s programada para el %s por intervalos de %d' % [@campaign.name, client.fullname, message.call.to_s, message.repeat_interval])
              docall(message, client)
            end
          end
        end
      end
    end

  end
end


#Run services
Forever.run do
  
  every 1.minute do
    Campaign.find_each do |campaign|
      srv = Service::CampaignCall.new(campaign)
    end
  end
end
