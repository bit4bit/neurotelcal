class Calendar < ActiveRecord::Base
  attr_accessible :start, :stop
  belongs_to :message
end
