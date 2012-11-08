# Load the rails application
require File.expand_path('../application', __FILE__)

#paginado
require 'will_paginate'
require 'securerandom'
require 'ronela_lenguaje'
require 'campaign_job'

#IVR LANG
require 'ivr_lang'
# Initialize the rails application
Neurotelcal::Application.initialize!
