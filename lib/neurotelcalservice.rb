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
require 'tmpdir'

$running = true
Rails.logger = Logger.new(Rails.root.join('log', 'neurotelcalservice.log'), 3, 5*1024*1024)
require Rails.root.join('app', 'models', 'plivo.rb')

#Realiza llamadas respectivas de una campana
module ServiceNeurotelcal
  @@running = true

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

    #Espera hasta encontrar canal disponible
    def esperar_canal
      @campaign.plivo.all.each { |cp|
          sleep 1 until cp.can_call?
      }
    end
    
    #Procesa mensaje y realiza las llamadas indicadas
    def process_queue
      begin
        esperar_canal
        @campaign.waiting_for_messages
        @campaign.process(true)
      rescue PlivoNotFound => e
        Rails.logger.error("NO HAY SERVIDOR PLIVO PARA LLAMAR")
      rescue PlivoCannotCall => e
        #se espera un canal disponible
        esperar_canal
        #PlivoCall.where(:end => 0, :hangup_enumeration => nil, :status => 'calling').delete_all #se limpian las mal realizadas
        Rails.logger.error("NO SE PUDO REALIZAR LA LLAMADA")
      rescue Errno::ECONNREFUSED => e
        Rails.logger.error("CONEXION RECHAZADA SERVIDOR PLIVO:" + e.message)
      rescue Exception => e
        Rails.logger.error("EXCEPTION:" + e.message)
        e.backtrace.each { |line| Rails.logger.error line}
      end
    end

  end

  #Se inicia el demonio neurotelcal
  #el cual revisa las campana, grupos, mensajes y realiza las llamadas
  def self.start
    pid_file = File.join(Dir.tmpdir,'neurotelcalservice.pid')
    if File.exists?(pid_file)
      STDERR.puts "YA HAY UN SERVICIO INICIADO"
      exit(1)
    end

    Signal.trap('INT') { ServiceNeurotelcal.stop}
    Signal.trap('TERM') { ServiceNeurotelcal.stop}
    #Run services
    print "Servicio de automarcador iniciado " + Time.now.to_s + "\n"
    #a demonio
    Process.daemon
    
   
    fpid = File.open(File.join(Dir.tmpdir, 'neurotelcalservice.pid'), 'w')
    fpid.write(Process.pid)
    fpid.close
   
    Rails.logger.debug('--STARTED ' + Time.now.to_s)
    $threads_campaigns = []
    
    
    while(@@running) do
      Campaign.all.each do |campaign|
        if campaign.end? == false
          #Hilo por campana para acelerar un poco la cosa
          $threads_campaigns << Thread.new(campaign) { |doCampaign|
            srv = ServiceNeurotelcal::CampaignCall.new(doCampaign)
            srv.process_queue
            ActiveRecord::Base.connection.close 
          }
        end
      end
      
      $threads_campaigns.each { |thread| thread.join}
      $threads_campaigns.clear
      sleep 1
    end
    
    Rails.logger.debug('--ENDED ' + Time.now.to_s)
  end
  
  #Se detiene despues de que se hayan terminado
  #los clientes pendients
  def self.stop
    @@running = false
    #se terminan todas las campanas, osea se paran completamente
    Campaign.all.each {|cp| cp.update_column(:status, Campaign::STATUS['END'])}
    File.delete(File.join(Dir.tmpdir, 'neurotelcalservice.pid'))
  end
  
  def self.force_stop
    begin
      fpid = File.open(File.join(Dir.tmpdir, 'neurotelcalservice.pid'), 'r')
      pid = fpid.read
      fpid.close

      Process.kill('TERM', pid.to_i)
      Rails.logger.debug "Deteniendo servicio"
      print "Deteniendo...servicio\n"
      sleep 10
    rescue
    
    end
  end
end




