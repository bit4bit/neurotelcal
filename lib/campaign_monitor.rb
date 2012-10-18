# Copyright (C) 2012 Bit4Bit <bit4bit@riseup.net>
#
#
# This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


#Utilizamos RSpec como monitor del comportamiento de neurotelcal
#por ejemplo el avisar si no se ha podido llamar, o bien
#muchas llamadas estan siendo rechazadas


class CampaignMonitor < MonitorApp
  def setup
    @messages_processing = {}
    Campaign.all.each do |campaign|
      if campaign.start? and campaign.need_process_groups?
        id_messages = []
        campaign.group.all.each do |group|
          next unless group.need_process_messages?
          id_messages << group.id_messages_share_clients
        end
        id_messages.flatten!
        @id_messages[campaign.id] = id_messages
      end
    end
  end

  def test_be_calling_if_there_are_messages_on_time
    @messages_processing.each do |campaign_id, messages|
      assert Call.in_process_for_message(messages).count > 0, 'Campaign %d not is calling' % campaign_id
    end
  end
  
  def test_be_calling_if_70_percent_had_answered
    @messages_processing.each do |campaign_id, messages|
      last_calls = Call.where(:message_id => messages).limit(200)
      
      calls = last_calls.count
      answers_calls = 0
      last_calls.each do |last_call|
        answers_calls += 1 if PlivoCall::ANSWER_ENUMERATION.include?(last_call.hangup_enumeration)
      end

      assert answers_calls > 0, 'Campaign %d not had answereds calls'
      assert ( (100 * answers_calls) / calls) > 69, 'Campaign %d has more 70% percent with not answereds calls' % campaign_id #debe ser mayor a 70% sino se envia alerta
    end
  end
  
  def test_greater_than_zero
    assert 3 > 5, "No es mayor"
  end
  
end
