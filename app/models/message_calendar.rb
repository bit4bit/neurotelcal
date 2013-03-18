# -*- coding: utf-8 -*-
class MessageCalendar < ActiveRecord::Base
  attr_accessible :start, :stop, :message_id, :max_clients, :time_expected_for_call
  attr_accessible :channels, :use_available_channels
  attr_accessible :notes
  attr_accessible :created_at, :updated_at

  belongs_to :message

  validates :max_clients, :numericality => { :greater_than_or_equal_to => 0 }
  validates :time_expected_for_call, :numericality => { :greater_than_or_equal_to => 0 }
  validates :channels, :numericality => { :greater_than_or_equal_to => 0 }

  validate :channels_cannot_be_greater_than_plivo_channels
  validate :time_expected_for_call_if_use_available_channels
  validate :channels_be_greater_than_zero_if_not_use_avaible_channels


  def channels_be_greater_than_zero_if_not_use_avaible_channels
    errors.add(:channels, 'Campo obligatorio o seleccion "usar canales disponibles"') if channels < 1 and not use_available_channels
  end
  

  def time_expected_for_call_if_use_available_channels
    if use_available_channels == true
      errors.add(:time_expected_for_call, 'Debe indicar este valor si activa "usar canales disponibles"') if time_expected_for_call < 1
    end
    
  end
  
  def channels_cannot_be_greater_than_plivo_channels
    if message
      if message.group.campaign.plivo.all.size > 0
        total_channels_plivos = 0
        if message.group.campaign.plivo.all.size > 1
          message_group.campaign.plivo.all.each {|p| total_channels_plivos += p.channels}
        else
          total_channels_plivos = message.group.campaign.plivo.first.channels.to_i
        end
        
        if channels > total_channels_plivos
          errors.add(:channels, 'Ha superado por %d el limite de canales del plivo o plivos de la Campaña %d' % [channels, total_channels_plivos])
        end
      else
        errors.add(:channels, 'No hay plivos configuarados')
      end
      
      if message.group.messages_share_clients
        mcls = MessageCalendar.select('channels').where(:message_id => message.group.id_messages_share_clients).where('id != ?', id).where('start >= ? AND stop <= ?', start, stop)
      else
        mcls = MessageCalendar.select('channels').where(:message_id => message.id).where('id != ?', id).where('start >= ? AND stop <= ?', start, stop)
      end

      if mcls.all.size > 0
        total_channels_messages_calendars = 0;
        mcls.each {|mc| total_channels_messages_calendars += mc.channels}


        if channels + total_channels_messages_calendars > total_channels_plivos
          errors.add(:channels, 'Ha superado por %d el limite de %d los plivos de la Campaña' % [channels + total_channels_messages_calendars, total_channels_plivos])
        end
      end

    end
  end

  def time_to_process?
    return false unless Time.now >= self.start and Time.now <= self.stop
    return false if self.max_clients > 0 and (Call.where(:message_calendar_id => self.id, :hangup_enumeration => PlivoCall::ANSWER_ENUMERATION).count + Call.where(:message_calendar_id => self.id, :terminate => nil).count) >= self.max_clients 
    return true
  end
  
end
