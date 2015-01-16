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

  Campaign.all.each do |campaign|
    if $running_campaigns.has_key?(campaign.id)
      $running_campaigns.delete(campaign.id) if campaign.end?
      next
    end
    next unless campaign.start?
    Rails.logger.info "Testing campaign #{campaign.name}"


    ::ActiveRecord::Base.establish_connection
    pid = fork do
      fork_campaign = Campaign.find(campaign.id)
      Rails.logger.info "Forking process for campaign #{fork_campaign.name} ENV #{ENV['RAILS_ENV']}"
      ENV["RAILS_ENV"] ||= "production"

      root = File.expand_path(File.dirname(__FILE__))
      root = File.dirname(root) until File.exists?(File.join(root, 'config'))
      Dir.chdir(root)

      require File.join(root, "config", "environment")

      while fork_campaign.start?
        Rails.logger.debug("Processing campaign #{campaign.name}")
        fork_campaign.process(true)
        sleep 5
      end
      Rails.logger.debug("Stopped campaign #{campaign.name}")
    end
   $running_campaigns[campaign.id] = pid
  end

  sleep 10
end

$running_campaigns.each do |campaign_id, task|
  Process.waitpid pid
end
