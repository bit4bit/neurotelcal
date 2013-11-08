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

    #logger.debug('process: client %d calls_faileds %d' % [client.id, client.calls_faileds])
    return false if  client.calling 
    #el cliente ya fue llamadao y no nay necesida de volverle a llamar
    return false unless client.callable
    #no hay que botar escape ni modo de ubicar el numero
    return false if client.error
    return true if message.anonymous?

    #se vuelve a marcar desde la ultima marcacion
    if client.calls_faileds > message.retries
      #logger.debug('process: client %d priority to seconds %d wait %d' % [client_fresh.id, client_fresh.priority_to_seconds_wait, (client_fresh.last_call_at + client_fresh.priority_to_seconds_wait) - Time.now])
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
  
  #Campaign llama cliente, buscando un espacio disponible entre sus servidores plivos
  def call_client(client, message, message_calendar = nil)
    raise PlivoNotFound, "There is not plivo server, first add one" unless self.plivo.exists?
    called = false
    plivos_to_call = []
    if distributor.count > 0
      plivos_to_call = plivos_from_distributor(client)
      if plivos_to_call.nil?
        return false
      end
    else
      plivos_to_call = self.plivo.all
    end
    

    plivos_to_call.each { |plivo|
      begin
        called = plivo.call_client(client, message, message_calendar)

        
        break
      rescue PlivoChannelFull => e
        logger.debug("Plivo id %d full trying next plivo" % plivo.id)
        next
      end
    }
    
    #raise PlivoCannotCall, "cant find plivo to call" unless called
    return called
  end

  def call_client!(client, message, message_calendar = nil)
    called = call_client(client, message, message_calendar)
    raise PlivoCannotCall, "cant find plivo to call" unless called
    return called
  end
  

  #@todo separa esto del modelo
  def process(daemonize = false)
    process_by_client(daemonize)
  end

  #Verifica hay grupos por procesar
  def need_process_groups?
    self.group.each{|g| return true if g.need_process_messages?}
    return false
  end
  
  #Se recorre cliente por cliente
  #y se van asignando a un mensaje para ser llamadaos
  def process_by_client(daemonize)
    total_messages_today = 0
    count_channels_messages = {}
    id_groups_to_process = [] 
    self.group.all.each do |group_processing|
      next unless group_processing.enable?
      group_processing.message.all.each do |message|
        next if message.anonymous
        next unless message.time_to_process?
        next if message.done_calls_clients?
        next unless message.time_to_process_calendar?
        
        total_messages_today += 1
        logger.debug('process: today we need do the message %d %s' % [message.id, message.name])
        count_channels_messages[message.id] = 0
        id_groups_to_process << message.group.id
      end
    end
    #no hay que estar corriendo
    sleep 5
    if total_messages_today == 0
      logger.debug('process: nothing to process')
      return false
    end

    logger.debug('process: total messages today %d' % total_messages_today)

    if id_groups_to_process.size < 1
      logger.debug('process: not id groups to process')
      return false
    end
    
    id_groups_to_process.uniq!
    clients = Client.where(:group_id => id_groups_to_process, :callable => true).order('priority DESC, callable DESC, created_at ASC')

    
    logger.debug('process: total messages today %d' % total_messages_today)

    id_groups_to_process.uniq!
    if distributor.count > 0
      clients = Client.where(:group_id => id_groups_to_process, :callable => true).where(["phonenumber REGEXP ?", Regexp.new(distributor.map{|d| d.filter}.join("|")).source]).order('priority DESC, callable DESC, created_at ASC')
    else
      clients = Client.where(:group_id => id_groups_to_process, :callable => true).order('priority DESC, callable DESC, created_at ASC')      
    end
    


    #end if not have client
    if clients.empty?
      logger.debug('process: we not have clients to call')
      sleep 30
      return false
    end
    
    wait_messages = []
    clients.all.each do |client_processing|
      next unless client_processing.callable?
      next if client_processing.calling?
      next if client_processing.error?

      while using_channels >= active_channels
        sleep 1
        logger.debug('process: all channels using waiting for.')
      end
      #si no hay grupos para procesar se espera
      #lo ideal es mantener cargada la cola de clientes procesados
      return false if not need_process_groups?
      

      sleep 1 while pause?

      self.group.all.each do |group_processing|
        #se termina en caso de forzado, y espera la ultima llamada
        return false if end?

        #se omite grupo si no es de cliente
        next unless client_processing.group_id == group_processing.id
        next unless group_processing.enable?
        #si esta pausado no se realiza las llamadas
        sleep 1 while pause? 
        
        group_processing.message.all.each do |message|
          
          #si es marcacion directa anonima
          #se debio haber realizado con Plivo#call_client
          next if message.anonymous
          #si no se pudo marcar el mensaje se elimina de la cola de espera
          if not message.time_to_process? or not message.time_to_process_calendar? or message.done_calls_clients?
            count_channels_messages.delete(message.id) unless count_channels_messages[message.id].nil?
            next
          else
            count_channels_messages[message.id] = 0 if count_channels_messages[message.id].nil?
          end
          
          #se termina en caso de forzado, y espera la ultima llamada
          break if end?
          sleep 1 while pause? #si se pausa la campana se espera hasta que se despause

          
          #se espera que la ultima llamada se ade este mensaje
          #sino se omite cliente y se deja para que lo preceso el mensaje
          #al que corresponde
          #::deprecation:: can_call? verifica si estan compartidos los clientes y decide si llamar
          #next if client_processing.group.messages_share_clients and Call.where(:client_id => client_processing.id).exists? and Call.where(:message_id => message.id, :client_id => client_processing.id).exists?

          use_extra_channels = 0
          use_extra_channels = extra_channels(message)
          
          #si esta sobre el limite se omite mensaje
          #logger.debug('process: message over process? %s' % message.over_limit_process_channels?(use_extra_channels).to_s)
          #logger.debug('process: count channels %d' % count_channels_messages[message.id])
          

          
          if message.over_limit_process_channels?(use_extra_channels) or (count_channels_messages[message.id] > 0 and count_channels_messages[message.id] >= message.total_channels_today() + use_extra_channels)
            wait_messages << message unless wait_messages.include?(message)
            next
          end          
          
          #se llama
          if process_one_client(message, client_processing)
            count_channels_messages[message.id] += 1
            logger.debug('process: called client %d' % client_processing.id)
          end
        end
      end

      #Si se pide demonio
      #entonces se espera hasta que esten disponibles mensajes para llamar
      #ya que si no habria que empezar siempre la lista de lo clientes
      logger.debug('process: wait_messages size %d total to way %d' % [wait_messages.size, count_channels_messages.size])
      
      time_elapsed_waiting = 0
      if daemonize and wait_messages.size > 0 and wait_messages.size >= count_channels_messages.size
        wait_messages.cycle{|message|
          #se termina en caso de forzado, y espera la ultima llamada
          return false if end?
          return false if not need_process_groups?
          
          logger.debug('process: waiting channel available for message %s' % message.name)
          time_elapsed_waiting += 0.10
          sleep 0.10
          if not message.over_limit_process_channels? or time_elapsed_waiting > 0.10 * 10 * 180 #espera 3 minutos
            wait_messages.each {|m| count_channels_messages[m.id] = m.calls_in_process}
            break #se salta este mensaje y se vuelve a buscar cliente
          end

        }
        #count_channels_messages = {}
        wait_messages = []
      end

    end
    
  end
  
    
  private
  def process_one_client(message, client)
    message.message_calendar.all.each do |message_calendar|
      #se detiene marcacion si ya se realizaron todas las llamadas contestadas
      if Time.now >= message_calendar.start and  Time.now <= message_calendar.stop
        if message_calendar.max_clients > 0 and (Call.where(:message_calendar_id => message_calendar.id, :hangup_enumeration => PlivoCall::ANSWER_ENUMERATION).count + Call.where(:message_calendar_id => message_calendar.id, :terminate => nil).count) >= message_calendar.max_clients 
          return false
        else
          if can_call_client?(client, message, message_calendar)
            r = call_client(client, message, message_calendar)
            if r.is_a?(String)
              return true
            end
          end
        end
        break
      end
    end
    return false
  end
   

  #Esto selecciona automaticamente los canales ha usar en el mensaje
  #en base a la cantidad de llamadas esperadas, logradas y faltantes
  #Osea en caso de faltar poco tiempo para terminar y hay canales disponibles
  #y hay muchas llamadas se utilizan los canales en proporcion a lo necesario para
  #cumplir con el max_clients del calendario.
  #::return:: int cantidad a ampliar para llamar
  def extra_channels(message)
    message_calendar_total_channels = 0
    #conteo de los cupos asignados para no usarlos
    Group.where(:campaign_id => id).each do |group|
      group.message.each do |message|
        next if message.anonymous
        message.message_calendar.each {|ms|
          next if Time.now < ms.start or Time.now > ms.stop
          message_calendar_total_channels += ms.channels 
        }
      end
    end
    
    #cantidad de canales necesarios
    need_channels = 0
    message.message_calendar.each do |message_calendar|
      next if Time.now < message_calendar.start or Time.now > message_calendar.stop
      next unless message_calendar.time_expected_for_call > 0
      next unless message_calendar.use_available_channels

      calls_answered = Call.answered_for_message(message.id).count

      calls_expected = message_calendar.max_clients

      plivo_total_channels = active_channels
      plivo_using_channels = using_channels

      #cantidad de canales disponibles despues de los ya usados y los separados
      diff_mc_and_plivo = message_calendar_total_channels - plivo_using_channels
      if diff_mc_and_plivo <= 0
        channels_availables = diff_mc_and_plivo + (plivo_total_channels - message_calendar_total_channels)
      else
        channels_availables = plivo_total_channels - plivo_using_channels
      end


      #llamada restantes para limite
      calls_to_complete = calls_expected - calls_answered
      #logger.debug('extra_channels: calls_to_complete %d' % calls_to_complete)

      #tiempo restante para limite
      seconds_to_complete = message_calendar.stop - Time.now
      #logger.debug('extra_channels: seconds_to_complete %d' % seconds_to_complete)

      #canales para completar
      begin
        channels_to_complete = calls_to_complete / (seconds_to_complete / message_calendar.time_expected_for_call)
        #logger.debug('extra_channels: channels_to_complete %d' % channels_to_complete)
        nchannels = channels_availables - channels_to_complete.floor
        need_channels += channels_availables > channels_to_complete ? channels_to_complete : channels_availables
      rescue ZeroDivisionError => e
        #e.backtrace.each { |line| logger.error line}
      rescue Exception => e
        e.backtrace.each { |line| logger.error line}
      end
    end
    logger.debug('extra_channels:Needing extra channels %d' % need_channels)
    need_channels = 0 if need_channels < 0
    return need_channels.to_i
  end

end
