class CampaignService
  
  def initialize(campaign)
    @campaign = campaign
  end

  #Campaign llama cliente, buscando un espacio disponible entre sus servidores plivos
  def call_client(client, message, message_calendar = nil)
    raise PlivoNotFound, "There is not plivo server, first add one" unless @campaign.plivo.exists?
    plivos_to_call = []
    if @campaign.distributor.count > 0
      plivos_to_call = @campaign.plivos_from_distributor(client)
      return false if plivos_to_call.nil?
    else
      plivos_to_call = @campaign.plivo.all
    end

    plivos_to_call.each { |plivo|
      begin
        return PlivoService.new(plivo).call_client(client, message, message_calendar)
      rescue PlivoChannelFull => e
        Rails.logger.debug("Plivo id %d full trying next plivo" % plivo.id)
        next
      end
    }
    
    #raise PlivoCannotCall, "cant find plivo to call" unless called
    return false
  end

  def call_client!(client, message, message_calendar = nil)
    raise PlivoCannotCall, "cant find plivo to call" unless call_client(client, message, message_calendar)
    return true
  end

  #@todo separa esto del modelo
  def process(daemonize = false)
    process_by_client(daemonize)
  end

    #Se recorre cliente por cliente
  #y se van asignando a un mensaje para ser llamadaos
  def process_by_client(daemonize)
    total_messages_today = 0
    count_channels_messages = {}
    id_groups_to_process = [] 
    @campaign.group.all.each do |group_processing|
      next unless group_processing.enable?
      next unless group_processing.start?

      group_processing.message.all.each do |message|
        next if message.anonymous
        next unless message.time_to_process?
        next if message.done_calls_clients?
        next unless message.time_to_process_calendar?
        
        total_messages_today += 1
        Rails.logger.debug('process: today we need do the message %d %s' % [message.id, message.name])
        count_channels_messages[message.id] = 0
        id_groups_to_process << message.group.id
      end
    end

    if total_messages_today == 0
      Rails.logger.debug('process: nothing to process')
      return false
    end

    Rails.logger.debug('process: total messages today %d' % total_messages_today)

    if id_groups_to_process.size < 1
      Rails.logger.debug('process: not id groups to process')
      return false
    end
    
    id_groups_to_process.uniq!
    clients = Client.where(:group_id => id_groups_to_process, :callable => true).order('priority DESC, callable DESC, created_at ASC')

    
    Rails.logger.debug('process: total messages today %d' % total_messages_today)

    if @campaign.distributor.count > 0
      clients = Client.where(:group_id => id_groups_to_process, :callable => true, :calling => false, :error => false).where(["phonenumber REGEXP ?", Regexp.new(@campaign.distributor.map{|d| d.filter}.join("|")).source]).order('priority DESC, callable DESC, created_at ASC')
    else
      clients = Client.where(:group_id => id_groups_to_process, :callable => true, :calling => false, :error => false).order('priority DESC, callable DESC, created_at ASC')      
    end

    #end if not have client
    unless clients.any?
      Rails.logger.debug('process: we not have clients to call')
      return false
    end
    
    wait_messages = []
    clients.find_each do |client_processing|
      #@deprecated se paso a consulta sql anterior
      #next unless client_processing.callable?
      #next if client_processing.calling?
      #next if client_processing.error?


      while @campaign.using_channels >= @campaign.active_channels
        return false if daemonize
        sleep 1
        Rails.logger.debug('process: all channels using waiting for.')
      end
      #si no hay grupos para procesar se espera
      #lo ideal es mantener cargada la cola de clientes procesados
      return false if not @campaign.need_process_groups?
      
      wait_while_pause daemonize

      @campaign.group.all.each do |group_processing|

        #se termina en caso de forzado, y espera la ultima llamada
        return false if @campaign.end?
        #se omite si esta detenido
        next unless group_processing.start?
        next unless group_processing.enable?
        #se omite grupo si no es de cliente
        next unless client_processing.group_id == group_processing.id

        #si esta pausado no se realiza las llamadas
        wait_while_pause daemonize
        
        Rails.logger.debug('process: find group for process')
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
          break if @campaign.end?
          
          wait_while_pause daemonize
          
          #se espera que la ultima llamada se ade este mensaje
          #sino se omite cliente y se deja para que lo preceso el mensaje
          #al que corresponde
          #::deprecation:: can_call? verifica si estan compartidos los clientes y decide si llamar
          #next if client_processing.group.messages_share_clients and Call.where(:client_id => client_processing.id).exists? and Call.where(:message_id => message.id, :client_id => client_processing.id).exists?

          use_extra_channels = 0
          use_extra_channels = extra_channels(message)
          
          #si esta sobre el limite se omite mensaje
          #Rails.logger.debug('process: message over process? %s' % message.over_limit_process_channels?(use_extra_channels).to_s)
          #Rails.logger.debug('process: count channels %d' % count_channels_messages[message.id])

          
          if message.over_limit_process_channels?(use_extra_channels) or (count_channels_messages[message.id] > 0 and count_channels_messages[message.id] >= message.total_channels_today() + use_extra_channels)
            wait_messages << message unless wait_messages.include?(message)
            next
          end          
          
          #se llama
          Rails.logger.debug('process: calling client %d' % client_processing.id)
          if process_one_client(message, client_processing)
            count_channels_messages[message.id] += 1
            Rails.logger.debug('process: called client %d' % client_processing.id)
          end
        end
      end

      #Si se pide demonio
      #entonces se espera hasta que esten disponibles mensajes para llamar
      #ya que si no habria que empezar siempre la lista de lo clientes
      Rails.logger.debug('process: wait_messages size %d total to way %d' % [wait_messages.size, count_channels_messages.size])
      
      time_elapsed_waiting = 0
      if daemonize and wait_messages.size > 0 and wait_messages.size >= count_channels_messages.size
        wait_messages.cycle{|message|
          #se termina en caso de forzado, y espera la ultima llamada
          return false if @campaign.end?
          return false if not @campaign.need_process_groups?
          
          Rails.logger.debug('process: waiting channel available for message %s' % message.name)
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
          Rails.logger.debug('process: can not call the client %d finished de calendar or all clients for message calendar all called' % client.id)
          return false
        else
          if client.can_call?(message, message_calendar)
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
   

  def wait_while_pause(daemonize)
    return false if @campaign.pause? and daemonize
    sleep 1 while @campaign.pause?
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
    Group.where(:campaign_id => @campaign.id).each do |group|
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

      plivo_total_channels = @campaign.active_channels
      plivo_using_channels = @campaign.using_channels

      #cantidad de canales disponibles despues de los ya usados y los separados
      diff_mc_and_plivo = message_calendar_total_channels - plivo_using_channels
      if diff_mc_and_plivo <= 0
        channels_availables = diff_mc_and_plivo + (plivo_total_channels - message_calendar_total_channels)
      else
        channels_availables = plivo_total_channels - plivo_using_channels
      end


      #llamada restantes para limite
      calls_to_complete = calls_expected - calls_answered
      #Rails.logger.debug('extra_channels: calls_to_complete %d' % calls_to_complete)

      #tiempo restante para limite
      seconds_to_complete = message_calendar.stop - Time.now
      #Rails.logger.debug('extra_channels: seconds_to_complete %d' % seconds_to_complete)

      #canales para completar
      begin
        channels_to_complete = calls_to_complete / (seconds_to_complete / message_calendar.time_expected_for_call)
        #Rails.logger.debug('extra_channels: channels_to_complete %d' % channels_to_complete)
        nchannels = channels_availables - channels_to_complete.floor
        need_channels += channels_availables > channels_to_complete ? channels_to_complete : channels_availables
      rescue ZeroDivisionError => e
        #e.backtrace.each { |line| Rails.logger.error line}
      rescue Exception => e
        e.backtrace.each { |line| Rails.logger.error line}
      end
    end
    Rails.logger.debug('extra_channels:Needing extra channels %d' % need_channels)
    need_channels = 0 if need_channels < 0
    return need_channels.to_i
  end

end
