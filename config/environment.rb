# Load the rails application
require File.expand_path('../application', __FILE__)

#paginado
require 'will_paginate'
require 'securerandom'
require 'ronela_lenguaje'

#jobs
require 'campaign_job'
require 'archive_job'

#tercerxs
require 'extensions'
# Initialize the rails application
Neurotelcal::Application.initialize!
