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


#Realiza llamadas respectivas de una campana
module ServiceNeurotelcal
  
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


    #Procesa mensaje y realiza las llamadas indicadas
    def process_queue
      @campaign.process
    end

  end

  def self.start
    #Run services
    print "Servicio de automarcador iniciado " + Time.now.to_s + "\n"
    #a demonio
    Process.daemon
    
    fpid = File.open(File.join(Dir.tmpdir, 'neurotelcalservice.pid'), 'w')
    fpid.write(Process.pid)
    fpid.close
   
    Rails.logger.debug('--STARTED ' + Time.now.to_s)
    $threads_campaigns = []
    
    
    Signal.trap('SIGHUP') do
      Rails.logger.debug('Forzando salida...espere.. ' + Time.now.to_s)
      print 'Forzando salida...espere..' + "\n"
      $running = false
      #@todo COMO GARANTIZO QUE SI TERMINO LA ULTIMA LLAMADA
      $threads_campaigns.each { |thread| thread.join}
    end
    
    
    while($running) do
      
      Campaign.all.each do |campaign|

        if campaign.end? == false
          $threads_campaigns << Thread.new(campaign) { |doCampaign|
            srv = ServiceNeurotelcal::CampaignCall.new(doCampaign)
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
  end

  def self.stop
    fpid = File.open(File.join(Dir.tmpdir, 'neurotelcalservice.pid'), 'r')
    pid = fpid.read
    fpid.close
    Process.kill('HUP', pid.to_i)
  end
end




