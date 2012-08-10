# -*- coding: utf-8 -*-
class Campaign < ActiveRecord::Base
  STATUS = { 'START' => 0, 'PAUSE' => 1, 'END' => 2}

  attr_accessible :description, :name, :status
  
  validates :name, :presence => true, :uniqueness => true
  has_many :resource
  has_many :client
  has_many :plivo
  has_many :group

  def pause?
    return STATUS['PAUSE'] == status
  end

  def end?
    return STATUS['END'] == status
  end
  

  def start?
    return STATUS['START'] == status
  end


  #Campaign llama cliente, buscando un espacio disponible entre sus servidores plivos
  def call_client(client, message)
    called = false
    ncalls = Call.where(:message_id => message.id, :client_id => client.id).count
    #@todo agregar exepction
    if ncalls > 0
      calls_faileds = Call.where(:message_id => message.id, :client_id => client.id).where('hangup_enumeration != "NORMAL_CLEARING"').count
      #ya se marco
      return false if Call.where(:message_id => message.id, :client_id => client.id).where(:hangup_enumeration => :NORMAL_CLEARING).count > 0
      #ya hay marcacion en camino
      return false if Call.where(:message_id => message.id, :client_id => client.id, :terminate => nil).exists?
      #ya se realizaron todos los intentos
      return false if calls_faileds > message.retries
    end


    raise PlivoNotFound, "There is not plivo server, first add one" unless self.plivo.exists?

    self.plivo.all.each { |plivo|
      begin
        plivo.call_client(client, message)
        called = true
        break
      rescue PlivoChannelFull => e
        logger.debug("Plivo id %d full trying next plivo" % plivo.id)
        next
      end
    }

    raise PlivoCannotCall, "cant find plivo to call" unless called
  end
  
  
  #Procesa mensaje y realiza las llamadas indicadas
  def process
    self.group.find_each do |group|

      #si esta pausado no se realiza las llamadas
      next if pause?
      
      group.message.find_each do |message|
        #se termina en caso de forzado, y espera la ultima llamada
        return false if end?
        
        #se omite mensaje que no esta en fecha de verificacion
        next if Time.now < Time.parse(message.call.to_s) or Time.now > Time.parse(message.call_end.to_s) 
        logger.debug("Campaign#Process: Revisando mensaje %s inicia %s y termina %s" % [message.name, message.call.to_s, message.call_end.to_s])

        group.client.find_each do |client|
          logger.debug("Campaign#Process: Para cliente %s en grupo %s" % [client.fullname, group.name])
          
          #si no hay calendario se realiza marcacion directa
          unless message.message_calendar.exists?
            next call_client(client, message) 
          end
          

          #se busca el calendario para iniciar marcacion
          logger.debug("Campaign#Process: Se busca en calendario")
          message.message_calendar.find_each do |message_calendar|
            if Time.now >= Time.parse(message_calendar.start.to_s) and  Time.now <= Time.parse(message_calendar.stop.to_s)
              call_client(client, message)
            end
          end
          
        end
      end
    end
  
  end

end
