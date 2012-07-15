class MessageCalendar < ActiveRecord::Base
  attr_accessible :start, :stop, :message_id
  belongs_to :message
end
