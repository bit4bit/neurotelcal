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
  
  
end
