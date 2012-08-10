require 'plivohelper'
require 'neurotelcalservice'


namespace :neurotelcal do
  task :process_queue => :environment do
    Campaign.all.each do |campaign|
      if campaign.end? == false
        campaign.process
      end
      
    end
  end
  
  task :service_start => :environment do
    ServiceNeurotelcal::start
  end

  task :service_stop => :environment do
    ServiceNeurotelcal::stop
  end
end
