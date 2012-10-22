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
    @logger = Rails.logger = Logger.new(Rails.root.join('log', 'campaign_monitor.log'), 3, 5*1024*1024)
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
  
  problem "be calling if there are messages on time" do
    @messages_processing.each do |campaign_id, messages|
      @campaign_id = campaign_id
      assert Call.in_process_for_message(messages).count > 0, 'Campaign %d not is calling' % campaign_id
    end
  end
  
  solution "be calling if there are messages on time" do
    @campaign_be_calling = [] if @campaign_be_calling.nil?

    if @campaign_be_calling.include?(@campaign_id)
      notify "We trying restarting but not work", :fatal
      return try_problem('dont know')
    end
    
    @campaign_be_calling << @campaign_id

    notify "Restarting campaign #{campaign.id}"
    campaign = Campaign.find(@campaign_id)
    Campaign.transaction do
      campaign.update_column(:status, Campaign::STATUS['END'])
    end
    
    sleep 20
    Campaign.transaction do
      campaign.update_column(:status, Campaign::STATUS['START'])
    end
    
    Delayed::Job.enqueue ::CampaignJob.new(campaign.id), :queue => campaign.id

    sleep 10
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
