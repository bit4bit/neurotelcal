# Load the rails application
require File.expand_path('../application', __FILE__)

#paginado
require 'will_paginate'
require 'securerandom'
require 'ronela_lenguaje'

#jobs
require 'campaign_job'
require 'campaign_del_job'
require 'archive_job'
require 'cdr_job'
require 'mailer_job'
#IVR LANG
require 'ivr_lang'


#tercerxs
require 'extensions'
require 'tempfile'
require 'zlib'
require 'csv'

require 'liquid'

# Initialize the rails application
Neurotelcal::Application.initialize!
