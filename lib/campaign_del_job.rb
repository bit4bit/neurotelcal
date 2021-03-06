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

class CampaignDelJob
  attr_accessor :campaign_id
  
  def initialize(campaign_id)
    self.campaign_id = campaign_id
  end
  
  def perform
    campaign = Campaign.find(campaign_id)
    
    group = Group.where(:campaign_id => campaign.id)
    group.each{|g| 
      g.client.destroy_all
      messages = Message.where(:group_id => g.id)
      messages.each{|m| 
        calls = Call.where(:message_id => m.id)
        calls.each do |call|
          call.plivo_call.destroy if call.plivo_call
          call.destroy
        end
        m.message_calendar.destroy if m.message_calendar

      } 
      g.message.destroy
    }

    campaign.group.destroy_all
    campaign.resource.destroy_all
    campaign.destroy
  end

end
