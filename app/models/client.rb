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
  
end
