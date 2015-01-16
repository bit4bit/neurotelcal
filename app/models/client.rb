# -*- coding: utf-8 -*-
class Client < ActiveRecord::Base

  attr_accessible :campaign_id, :fullname, :group_id, :phonenumber, :priority
  attr_accessible :created_at, :id, :retries, :updated_at, :campaign
  attr_accessible :updated_at
  attr_accessible :priority #campo de su interno
  attr_accessible :callable #se puede llamar?
  attr_accessible :calling, :error, :error_msg, :calls, :last_call_at
  attr_accessible :calls_faileds
  belongs_to :campaign
  belongs_to :group


  has_many :call

  validates :fullname, :group_id, :presence => true

  def calling?
    v = self.class.select('calling').where(:id => self.id).first.calling
    self[:calling] = v
    return v == true
  end
  
  def callable?
    v = self.class.select('callable').where(:id => self.id).first.callable
    self[:callable] = v
    return v == true
  end
  
  def error?
    v = self.class.select('error').where(:id => self.id).first.error
    self[:error] = v
    return v == true
  end
  
    
  #Segun la prioridad que lleve el cliente se va 
  #poniendo en cola para volver a intentarle la llamada
  def priority_to_seconds_wait
    return self.priority.abs * 5
  end

  #Cambia prioridad del cliente segun la cause de cuelgue
  #el objetivo primordial es darle prioridad en una proxima llamada
  #a los clientes que contestaron y a los que no ir bajandole prioridad
  #http://wiki.freeswitch.org/wiki/Hangup_causes
  def update_priority_by_hangup_cause(cause)
    priority = self.priority
    case cause
    when 'NORMAL_CLEARING'
      priority += 200
    when 'ALLOTED_TIMEOUT'
      priority -= 100
    when 'NO_ANSWER'
      priority -= 200
    when 'USER_BUSY'
      priority -= 300
    when 'CALL_REJECTED'
      priority -= 800
    when 'UNALLOCATED_NUMBER '
      priority -= 2000
    when 'NORMAL_TEMPORARY_FAILURE'
      priority -= 10
    else
      priority -= 500
    end
    self.update_attributes(:priority => priority)
  end

    #Se verifica si se puede llamara a un cliente
  #con un determinado mensaje y un calendario de mensaje.
  #El objetivo primordial es llamar las veces que sea necesario
  #el cliente hasta que se obtenga una respuesta de que contesto, por cada
  #'falla' en la llamada al cliente ha este se le baja la prioridad mirar Client#update_priority_by_hangup_cause
  #o bien se le aumente si contesto satisfactoriamente esta prioridad es acumulativa al cliente mirar atributo Client#prority
  #Teniendo como logica de funcionamiento:
  # * si es mensaje anonimo llamar de una
  # * si es un cliente con un numero invalido no se llama
  # * si ya se marco para el menasje no se llama
  # * si ya se esta marcando no se llama
  # * si ha fallado se reintenta las veces indicadas por mensaje
  #
  #::client:: cliente a llamar
  #::message:: mensaje a ser comunicado
  #::message_calendar:: calendario de mensaje usado en caso de haber
  #::return:: boolean indicando si se pudo o no realizar la llamada
  def can_call?(message)
    self.reload
    logger.debug('process: can_call_client? %d' % self.id)
    #logger.debug('process: client %d calls_faileds %d' % [client.id, client.calls_faileds])
    return false if  client.calling?
    #el cliente ya fue llamadao y no nay necesida de volverle a llamar
    return false unless client.callable?
    #no hay que botar escape ni modo de ubicar el numero
    return false if client.error
    return true if message.anonymous?

    #se vuelve a marcar desde la ultima marcacion
    if self.calls_faileds > message.retries
      if not (Time.now >= self.last_call_at + self.priority_to_seconds_wait)
        return false
      end
    end

    return true
  end

  
end
