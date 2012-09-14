# -*- coding: utf-8 -*-
class MessageCalendar < ActiveRecord::Base
  attr_accessible :start, :stop, :message_id, :max_clients
  attr_accessible :channels
  belongs_to :message

  validate :channels_cannot_be_greater_than_plivo_channels
  
  def channels_cannot_be_greater_than_plivo_channels
    if message
      if message.group.campaign.plivo.all.size > 0
        total_channels_plivos = message.group.campaign.plivo.all.size > 1 ? message.group.campaign.plivo.all.inject {|s,v| s.channels.to_i + v.channels.to_i} : message.group.campaign.plivo.first.channels.to_i
        if channels > total_channels_plivos
          errors.add(:channels, 'Ha superado por %d el limite de canales del plivo o plivos de la Campaña %d' % [channels, total_channels_plivos])
        end
      else
        errors.add(:channels, 'No hay plivos configuarados')
      end
      
      mcls = MessageCalendar.select('channels').where(:message_id => message.id).where('id != ?', id)
      if mcls.all.size > 0
        total_channels_messages_calendars = mcls.all.size > 1 ? mcls.all.inject {|s,v| s.channels + v.channels } : mcls.first.channels

        if channels + total_channels_messages_calendars > total_channels_plivos
          errors.add(:channels, 'Ha superado por %d el limite de %d los plivos de la Campaña' % [channels + total_channels_messages_calendars, total_channels_plivos])
        end
      end
      
        
    end
  end
  
end
