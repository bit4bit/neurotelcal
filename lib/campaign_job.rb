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

require 'plivohelper'

class CampaignJob
  attr_accessor :campaign_id
  
  def initialize(campaign_id)
    self.campaign_id = campaign_id
  end
  
  def perform
    campaign = Campaign.find(campaign_id)
    
    #espera por mensaje a procesar
    while not campaign.need_process_groups?
      sleep 5
    end
    
    Rails.logger.debug("Processing campaign")
    while campaign.need_process_groups?
      campaign.process(true)
      break if campaign.end?
    end
    campaign.update_column(:status, Campaign::STATUS['END'])
    Rails.logger.debug("End processing campaign")
  end
end
