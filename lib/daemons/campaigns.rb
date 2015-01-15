#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

$running_campaigns = {}

$running = true
Signal.trap("TERM") do 
  $running = false
end

while($running) do
  Rails.logger.info "Procesing campaigns"

  Campaign.all.delete_if{|c| $running_campaigns.has_key?(c.id)}.each do |campaign|
    Rails.logger.info "Testing campaign #{campaign.name}"
    
    Rails.logger.info "Forking process for campaign #{campaign.name}"
    ::ActiveRecord::Base.establish_connection
    pid = fork do
      until campaign.end?
        Rails.logger.debug("Processing campaign #{campaign.name}")
        campaign.process(true)
        sleep 5
        break unless $running
      end
    end
   $running_campaigns[campaign.id] = pid
  end

  sleep 10
end

$running_campaigns.each do |campaign_id, pid|
  Process.wait pid
end
