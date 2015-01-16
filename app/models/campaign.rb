# -*- coding: utf-8 -*-
#La campana representa un conjunto de clientes a llamar
#y un grupo de mensajes a comunicarles.
#La campana puede estar en los estados:
# ::START:: la campana realiza llamadas
# ::PAUSE:: se pausa en el ultimo cliente, pero el servicio haun esta activado
# ::END:: se detiene por complete las llamadas
#Mirar /lib/neurotelcalservice.rb para mas detalles, tambien pueden
#mirar Campaign#process.
class Campaign < ActiveRecord::Base
  STATUS = { 'START' => 0, 'PAUSE' => 1, 'END' => 2}
  default_scope order('created_at DESC')


  attr_accessible :description, :name, :status, :entity_id
  attr_accessible :notes
  attr_accessible :created_at, :pause, :start, :stop, :updated_at
  validates :name, :presence => true, :uniqueness => true
  validates :entity_id, :presence => true
  has_many :resource, :dependent => :delete_all
  has_many :plivo, :dependent => :delete_all, :conditions => 'enable = 1', :order => 'priority ASC'
  has_many :group, :dependent => :delete_all
  has_many :distributor,:dependent => :delete_all, :conditions => 'active = 1'
  belongs_to :entity

  def deep_name
    new_name = ""
    if entity
      new_name = entity.name + " -> "
    end
    new_name += name
    return new_name
  end
  
  def pause?
    #Se reconsulta para obtener ultimo estado
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

  #Clientes restantes
  def client_rest
    Client.where(:group_id => self.group.all, :callable => true).order('priority DESC, callable DESC, created_at ASC')
  end

  def client
    Client.where(:group_id => self.group.all).order('priority DESC, callable DESC, created_at ASC')
  end
  
  def active_channels
    return plivo.all.map{|p| p.channels}.reduce{|s,v| s + v}
  end

  def using_channels
    return plivo.all.map{|p| p.using_channels}.reduce{|s,v| s + v}
  end
  
  def total_calls_today
    n_calls = 0
    self.group.all.each do |group|
      next unless group.need_process_messages?
      group.message.all.each do |message|
        next if not message.time_to_process? or not message.time_to_process_calendar?
        message.message_calendar.all.each do |mc|
          next unless mc.time_to_process?
          n_calls += mc.max_clients
        end
      end
    end
    return n_calls
  end
  
  def total_calls_answer_today
    #@todo cahecar
    messages_today = self.group.map{|g| g.need_process_messages? ? g.id_messages_share_clients : nil}.flatten.compact
    return Call.where(:message_id => messages_today, :hangup_enumeration => PlivoCall::ANSWER_ENUMERATION).where('enter >= ?', DateTime.now.beginning_of_day.getutc).count
  end
  
  def total_calls_not_answer_today
    #@todo cachear
    messages_today = self.group.map{|g| g.need_process_messages? ? g.id_messages_share_clients : nil}.flatten.compact
    return Call.where(:message_id => messages_today).where('enter >= ?', DateTime.now.beginning_of_day.getutc).where("hangup_enumeration NOT IN(?)", PlivoCall::ANSWER_ENUMERATION).count
  end
  
  #::return:: en porcentaje la probabilidad de alcanzar las llamadas esperadas en base a las contestadas y no contestadas hasta ahora
  def percent_probability_to_complete
    mcf = MessageCalendar.where('stop >= ? AND start >= ?', DateTime.now.beginning_of_day.getutc, DateTime.now.beginning_of_day.getutc).order('stop ASC').first
    mci = MessageCalendar.where('start >= ?', DateTime.now.beginning_of_day.getutc).order('start DESC').first
    c = total_calls_answer_today
    #cn = total_calls_not_answer_today
    tcd = total_calls_today
    tr = (mcf.stop() - Time.now()) / 60 #tiempo restante
    ti = (Time.now() - mci.start) / 60 #tiempo desde inicio
    tt = tr + ti #total de tiempo para las llamadas
    lxm = tcd / tt #llamadas x minuto esperadas
    lea = lxm * ti #llamadas esperedas hasta ahora
    
    #logger.debug("tr %d, ti %d, lea %d, c %d" % [tr,ti,lea, c])
    begin
      #return (c / tcd) * (tcd / (c+cn))
      return ((c / lea) * 100).floor # a porcentaje
    rescue Exception => e
      return 0
    end
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
  def can_call_client?(client, message, message_calendar = nil)
    client.reload
    logger.debug('process: can_call_client? %d' % client.id)
    #logger.debug('process: client %d calls_faileds %d' % [client.id, client.calls_faileds])
    return false if  client.calling 
    #el cliente ya fue llamadao y no nay necesida de volverle a llamar
    return false unless client.callable
    #no hay que botar escape ni modo de ubicar el numero
    return false if client.error
    return true if message.anonymous?

    #se vuelve a marcar desde la ultima marcacion
    if client.calls_faileds > message.retries
      if not (Time.now >= client.last_call_at + client.priority_to_seconds_wait)
        return false
      end
    end

    return true
  end
  
  def plivos_from_distributor(client)
    plivos_to_call = []
    if distributor.count  > 0
      distributor.each do |d|
        next if d.filter.empty?
        if client.phonenumber =~ Regexp.new(d.filter)
          plivos_to_call << d.plivo
          logger.debug("process: find distributor %s for client" % [d.description])
        end
      end
      return plivos_to_call
    end
    return nil
  end
  
  


  #Verifica hay grupos por procesar
  def need_process_groups?
    self.group.each{|g| return true if g.need_process_messages?}
    return false
  end

end
