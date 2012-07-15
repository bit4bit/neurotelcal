#!/usr/bin/env /home/bit4bit/ruby/neurotelcal/script/rails runner
# -*- coding: utf-8 -*-
# Servidor que realiza las llamadas de NeuroTelcal

#
#Las campañas tienen una fecha inicio y parada
#los mensajes tienen una feach de inicio y parada
#ademas de un calendario de inicio y parada
# Campaña inicio
# |        Mensaje inicio
# |        |      Calendario mensaje inicio
# |        |      |
# |--------|-----­|=======|-----|========|------|===========|-----|--------|
#inicio inicio inicio1 parada1 inicio2 parada2 inicio.....parada parada parada
#
require 'plivohelper'
require 'forever'


$running = true
Rails.logger = Logger.new(Rails.root.join('log', 'docalls.log'), 3, 5*1024*1024)


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
      Rails.logger.debug("Servicio de campaña %s at %s" % [@campaign.name, Time.now])
    end

    #Realiza la llamada usando plivo
    #@param Message message mensaje a usar para realizar la llamada
    #@param Client client cliente para llamar
    def docall(message, client)
      ncalls = Call.where(:message_id => message.id, :client_id => client.id).count
      if ncalls > 0
        calls_faileds = Call.where('hangup_enumeration != ? AND message_id = ? AND client_id = ? AND terminate IS NOT NULL', 'NORMAL_CLEARING', message.id, client.id).count
        return false if calls_faileds >= message.retries

        #ya hay marcacion en camino
        return false if Call.where(:message_id => message.id, :client_id => client.id, :terminate => nil).exists?
      end
      

      if message.valid?        
        begin
          @campaign.call_client(client, message)
          Rails.logger.debug('[%s] Llamando a %s programada para el %s' % [@campaign.name, client.fullname, message.call.to_s])
        rescue PlivoNotFound => e
          Rails.logger.debug 'No hoo %s' % e.to_s
        rescue PlivoCannotCall => e
          Rails.logger.debug 'Error plivo %s' % e.to_s
        rescue Errno::ECONNREFUSED => e
          logge.debug 'No se pudo conectar a plivo en %s' % plivo.api_url
        rescue Exception => e
          Rails.logger.debug "error:" + e.to_s
        end
      end
    end

    #Procesa mensaje y realiza las llamadas indicadas
    def process_queue
      @campaign.group.find_each do |group|

        #si esta pausado no se realiza las llamadas
        next if @campaign.pause?
        
        group.message.find_each do |message|
          #se termina en caso de forzado, y espera la ultima llamada
          return false unless $running

          

          

          #se omite mensaje que no esta en fecha de verificacion
          next if Time.now < Time.parse(message.call.to_s) or Time.now > Time.parse(message.call_end.to_s) 
          Rails.logger.debug("Revisando mensaje %s inicia %s y termina %s" % [message.name, message.call.to_s, message.call_end.to_s])
          
          @campaign.client.find_each do |client|
            Rails.logger.debug("Para cliente %s" % client.fullname)
            
            #si no hay calendario se realiza marcacion directa
            return docall(message, client) unless message.message_calendar.exists?

            #se busca el calendario para iniciar marcacion
            Rails.logger.debug("Se busca en calendario")
            message.message_calendar.find_each do |message_calendar|
              if Time.now >= Time.parse(message_calendar.start.to_s) and  Time.now <= Time.parse(message_calendar.stop.to_s)
                docall(message, client)
              end
            end
            
          end
        end
      end
    end

  end
end


#Run services
print "Servicio de automarcador iniciado " + Time.now.to_s + "\n"
Rails.logger.debug('--STARTED ' + Time.now.to_s)
$threads_campaigns = []


Signal.trap('SIGINT') do
  print 'Forzando salida...espere..' + "\n"
  $running = false
  $threads_campaigns.each { |thread| thread.join}
end


while($running) do
  
  Campaign.all.each do |campaign|
    unless campaign.end?
      $threads_campaigns << Thread.new(campaign) { |doCampaign|
        srv = Service::CampaignCall.new(doCampaign)
        srv.process_queue
        ActiveRecord::Base.connection.close 
      }
    end
  end

  $threads_campaigns.each { |thread| thread.join}
  $threads_campaigns.clear
end

Rails.logger.debug('--ENDED ' + Time.now.to_s)
print "Servicio de automarcador terminado " + Time.now.to_s + "\n"
