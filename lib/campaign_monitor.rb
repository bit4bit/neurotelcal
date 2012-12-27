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


#Se dan algunos casos que se puede
#dar una solucion automatica
monapp_case "campaigns" do
  setup do
    @messages_processing = {}
    @campaigns = []
    @campaigns_end = []
    Campaign.all.each do |campaign|
      @campaigns << campaign.id
      id_messages = []
      campaign.group.all.each do |group|
        next unless group.need_process_messages?
        id_messages << group.id_messages_share_clients
      end
      id_messages.flatten!
      @messages_processing[campaign.id] = id_messages unless id_messages.empty?
      if campaign.end?
        @campaigns_end << campaign.id
      end
      
    end
  end

  problem "be calling if campaign stop and have work to do" do
    @campaigns.each do |campaign_id|
      campaign = Campaign.find_by_id(campaign_id)
      @campaign_id = campaign_id
      campaign.group.all.each do |group|
        if group.need_process_messages?
          assert campaign.end? == false, 'Campaign %d not is calling and have messages to process' % campaign_id
        end
      end
    end
  end
  
  solution "be calling if campaign stop and have work to do" do
    notify "Init campaign #{@campaign_id}"
    campaign = Campaign.find_by_id(@campaign_id)
    break unless campaign.end?

    notify "Force stop campaign"
    Campaign.transaction do
      campaign.update_column(:status, Campaign::STATUS['END'])
      sleep 20
      notify "Starting again campaign"
      campaign.update_column(:status, Campaign::STATUS['START'])
    end
    
    notify "Enqueue campaign again and running"
    Delayed::Job.enqueue ::CampaignJob.new(campaign.id), :queue => campaign.id
  end

  #No hay clientes
  problem 'not have clients' do
    @messages_processing.each do |campaign_id, messages|
      @campaign_name = Campaign.find(campaign_id).name
      @campaign_id = campaign_id
      assert Client.where(:campaign_id => campaign_id, :callable => 1).count > 0
    end
  end

  solution 'not have clients' do
    notify "HAAA!! campaign #{@campaign_name} not have clients we stop the campaign", :fatal
    Campaign.transaction do
      Campaign.find(campaign_id).update_column(:status, Campaign::STATUS['END'])
    end
  end
  
  
  problem 'dont know' do
  end
  
  solution 'dont know' do
    notify "We dont know how resolv the problem..good bye", :fatal
  end
  
end

