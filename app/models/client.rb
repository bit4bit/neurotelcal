# -*- coding: utf-8 -*-
class Client < ActiveRecord::Base
  attr_accessible :campaign_id, :fullname, :group_id, :phonenumber, :priority
  attr_accessible :priority #campo de su interno
  belongs_to :campaign
  belongs_to :group
  
  has_many :call

  validates :fullname, :group_id, :presence => true
  #validates :phonenumber, :format => {
  #  :with => /[0-9]+([ ][0-9]+)*/,
  #  :message => "Solo número entre 7 y 10 digitos separados por espacio"
  #}

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
    else
      self.priority -= 500
    end

    self.save()
  end
  
end
