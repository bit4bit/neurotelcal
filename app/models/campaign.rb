# -*- coding: utf-8 -*-
class Campaign < ActiveRecord::Base
  STATUS = { 'START' => 0, 'PAUSE' => 1, 'END' => 2}

  attr_accessible :description, :name, :status, :entity_id
  
  validates :name, :presence => true, :uniqueness => true
  validates :entity_id, :presence => true
  has_many :resource, :dependent => :delete_all
  has_many :client, :dependent => :delete_all
  has_many :plivo, :dependent => :delete_all
  has_many :group, :dependent => :delete_all
  belongs_to :entity
  def pause?
    r = Campaign.select('status').where(:id => self.id).first.status
    return STATUS['PAUSE'] == r
  end

  def end?
    r = Campaign.select('status').where(:id => self.id).first.status
    return STATUS['END'] == r
  end
  

  def start?
    r = Campaign.select('status').where(:id => self.id).first.status
    return STATUS['START'] == r
  end


  def can_call_client?(client, message, message_calendar = nil)
    called = false
    if not message.anonymous and client.group.messages_share_clients
      ncalls = Call.where(:message_id => client.group.id_messages_share_clients, :client_id => client.id).count
    else
      ncalls = Call.where(:message_id => message.id, :client_id => client.id).count
    end
    #@todo agregar exepction
    if ncalls > 0
      considera_contestada = PlivoCall::ANSWER_ENUMERATION
      
      #logger.debug("Grupo comparte mensajes?" + client.group.messages_share_clients.to_s )
      
      if not message.anonymous and client.group.messages_share_clients 
        message_id = client.group.id_messages_share_clients
      else
        message_id = message.id
      end
      
      #no hay que botar escape ni modo de ubicar el numero
      return false if Call.where(:client_id => client.id).where("hangup_enumeration IN (%s)" % PlivoCall::REJECTED_ENUMERATION.map {|v| "'%s'" % v}.join(',')).count > 0
      #ya se marco
      return false if Call.where(:message_id => message_id, :client_id => client.id).where(:hangup_enumeration => PlivoCall::ANSWER_ENUMERATION).count > 0
      return false if Call.in_process_for_message_client?(message_id, client.id).exists?
      
      #se vuelve a marcar desde la ultima marcacion
      begin
        calls_faileds = Call.where(:message_id => message_id, :client_id => client.id).where("hangup_enumeration NOT IN (%s)" % PlivoCall::ANSWER_ENUMERATION.map {|v| "'%s'" % v}.join(',')).count
        #logger.debug('calls faileds %d for client %d' % [calls_faileds, client.id])
        call_failed = Call.where(:message_id => message_id, :client_id => client.id).where("hangup_enumeration NOT IN (%s)" % PlivoCall::ANSWER_ENUMERATION.map {|v| "'%s'" % v}.join(',')).order('terminate').reverse_order.first if calls_faileds > 0
        #se le da diez segundos para volver a marcar
        return false if calls_faileds > message.retries and not Time.now >= Time.parse(call_failed.terminate.to_s) + 10
        
        #logger.debug('client %d priority to seconds %d' % [client.id, client.priority_to_seconds_wait])
        if not (Time.now >= Time.parse(call_failed.terminate.to_s) + client.priority_to_seconds_wait)
          return false
        else
          #se actualiza prioridad a cliente para marcacion
          client.update_priority_by_hangup_cause(call_failed.hangup_enumeration)
        end
      rescue Exception => e
        logger.error('Error seen calls faileds. %s' % e.message)
      end
      
    end
    
    return true
  end
  
  def call_clients(clients, message)
    self.plivo.all.each { |plivo|
      begin
        plivo.call_clients(clients, message)
        return true
      rescue PlivoChannelFull => e
        logger.debug("Plivo id %d full trying next plivo" % plivo.id)
        next
      end
    }
    return false
  end
  
  #Campaign llama cliente, buscando un espacio disponible entre sus servidores plivos
  def call_client(client, message, message_calendar = nil)
    raise PlivoNotFound, "There is not plivo server, first add one" unless self.plivo.exists?
    called = false
    self.plivo.all.each { |plivo|
      begin
        plivo.call_client(client, message, message_calendar)
        called = true
        break
      rescue PlivoChannelFull => e
        logger.debug("Plivo id %d full trying next plivo" % plivo.id)
        next
      end
    }
    
    raise PlivoCannotCall, "cant find plivo to call" unless called
    return called
  end
  
  
  #Procesa mensaje y realiza las llamadas indicadas
  #@todo cachear consultas ya que se realizan muchas
  def process
    self.group.all.each do |group|
      
      #si esta pausado no se realiza las llamadas
      next if pause?
      fibers = []
     

      group.message.all.each do |message|
        #se termina en caso de forzado, y espera la ultima llamada
        return false if end?
      
        

        fibers << Fiber.new {
          #si ya se marcaron todos los clientes posibles se salta
          if message.done_calls_clients? and not message.anonymous
            #logger.debug("Mensaje %d done calls jumping" % message.id)
            next
            #break
          else
            #logger.debug("Mensaje %d not have done calls yet " % [message.id])
          end
          #logger.debug("Time ahora (%s) message_call (%s) message_end (%s)" % [Time.now.to_s, Time.zone.parse(message.call.to_s), Time.parse(message.call_end.to_s)])
          #se omite mensaje que no esta en fecha de verificacion
          next if Time.now < Time.parse(message.call.to_s) or Time.now > Time.parse(message.call_end.to_s) 
          #logger.debug("Campaign#Process: Revisando mensaje %s inicia %s y termina %s" % [message.name, message.call.to_s, message.call_end.to_s])
          
          count_calls = 0
          group.client.all.each do |client|
            #logger.debug("Campaign#Process: Para cliente %s en grupo %s" % [client.fullname, group.name])
            #si es marcacion directa anonima
            if message.anonymous
              next call_client(client, message) 
            end
            
            
            #se espera que la ultima llamada se ade este mensaje
            #sino se omite cliente y se deja para que lo preceso el mensaje
            #al que corresponde
            if Call.where(:client_id => client.id).exists?
              if not Call.where(:message_id => message.id, :client_id => client.id).exists? 
                next
              elsif (Call.where(:message_id => message.id, :client_id => client.id).count - Call.not_answered_for_message_client(message.id, client.id).count) >= message.max_clients
                break
              end
            end
            
            
            if client.group.messages_share_clients
              message_id = client.group.id_messages_share_clients
            else
              message_id = message.id
            end
            
            #se salta si ya esta en proceso
            if Call.in_process_for_message_client?(message_id, client.id).exists?
              count_calls += Call.in_process_for_message_client?(message_id, client.id).count
              next
            end
            
            
            #if message.done_calls_clients?
            if Call.done_calls_message(message.id).count + count_calls >= message.max_clients
              break
            elsif message.max_clients > 0 and count_calls >= message.max_clients
              break
            end
            
            
            #logger.debug('Count trying done calls %d for message %d max clients %d' % [count_calls, message.id, message.max_clients])
            #se busca el calendario para iniciar marcacion
            #logger.debug("Campaign#Process: Se busca en calendario")
            message.message_calendar.all.each do |message_calendar|
              #se detiene marcacion si ya se realizaron todas las llamadas contestadas
              
              
              if Time.now >= Time.parse(message_calendar.start.to_s) and  Time.now <= Time.parse(message_calendar.stop.to_s)
                if message_calendar.max_clients > 0 and (Call.where(:message_calendar_id => message_calendar.id, :hangup_enumeration => PlivoCall::ANSWER_ENUMERATION).count + Call.where(:message_calendar_id => message_calendar.id, :terminate => nil).count) >= message_calendar.max_clients 
                  count_calls += message.max_clients #se saca a la fuerza
                else
              
                  if can_call_client?(client, message, message_calendar)
                    count_calls += 1 if call_client(client, message, message_calendar)
                  end
                  
                end
                break
              end
            end
          end
        }
      end #end group
      fibers.each(&:resume)
    end
    
  end

end
