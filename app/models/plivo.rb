# -*- coding: utf-8 -*-
class Plivo < ActiveRecord::Base
  attr_accessible :app_url, :api_url, :auth_token, :campaign_id, :sid, :status, :gateways, :caller_name, :gateway_timeouts, :gateway_retries, :gateway_codecs
  belongs_to :campaign

  validates :app_url, :api_url, :sid, :auth_token, :campaign, :gateways, :gateway_timeouts, :gateway_retries, :caller_name, :presence => true
  
  validates :gateway_retries, :gateway_timeouts, :numericality => true

  before_save :verificar_conexion

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


  #Encommila la cadena de los codecs
  def gateway_codecs_quote
    return "'%s'" % gateway_codecs
  end

  def status
    return verificar_conexion ? "Conectado" : "Desconectado"
  end
end
