# -*- coding: utf-8 -*-
class Client < ActiveRecord::Base
  attr_accessible :campaign_id, :fullname, :group_id, :phonenumber, :priority
  attr_accessible :priority #campo de su interno
  attr_accessible :callable #se puede llamar?
  attr_accessible :calling, :error, :error_msg
  belongs_to :campaign
  belongs_to :group


  has_many :call

  validates :fullname, :group_id, :presence => true
  #validates :phonenumber, :format => {
  #  :with => /[0-9]+(,[0-9]+)*/,
  #  :message => "Solo números y separados por coma para multiples numeros"
  #}

  def calling?
    return Client.select('calling').where(:id => self.id).first.calling == true
  end
  
  def callable?
    return Client.select('callable').where(:id => self.id).first.callable == true
  end
  
  def error?
    return Client.select('error').where(:id => self.id).first.error == true
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
    case cause
    when 'NORMAL_CLEARING'
      self.priority += 200
    when 'ALLOTED_TIMEOUT'
      self.priority -= 100
    when 'USER_BUSY'
      self.priority -= 300
    when 'CALL_REJECTED'
      self.priority -= 800
    when 'UNALLOCATED_NUMBER '
      self.priority -= 2000
    when 'NORMAL_TEMPORARY_FAILURE'
      self.priority -= 10
    else
      self.priority -= 500
    end

    self.save()
  end
  
end
