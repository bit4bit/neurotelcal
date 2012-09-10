# -*- coding: utf-8 -*-
class Client < ActiveRecord::Base
  attr_accessible :campaign_id, :fullname, :group_id, :phonenumber
  attr_accessible :priority #campo de su interno
  belongs_to :campaign
  belongs_to :group
  
  has_many :call

  validates :fullname, :group_id, :presence => true
  #validates :phonenumber, :format => {
  #  :with => /[0-9]+([ ][0-9]+)*/,
  #  :message => "Solo número entre 7 y 10 digitos separados por espacio"
  #}

  #Cambia prioridad del cliente segun la cause de cuelgue
  #el objetivo primordial es darle prioridad en una proxima llamada
  #a los clientes que contestaron y a los que no ir bajandole prioridad
  #http://wiki.freeswitch.org/wiki/Hangup_causes
  def update_priority_by_hangup_cause(cause)
    case cause
    when 'NORMAL_CLEARING'
      priority += 100
    when 'ALLOTED_TIMEOUT'
      priority -= 100
    when 'USER_BUSY'
      priority -= 300
    when 'CALL_REJECTED'
      priority -= 900
    when 'UNALLOCATED_NUMBER '
      priority -= 1000
    else
      priority -= 500
    end

    self.save()
  end
  
end
