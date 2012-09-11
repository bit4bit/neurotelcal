class MessageCalendar < ActiveRecord::Base
  attr_accessible :start, :stop, :message_id, :max_clients
  belongs_to :message
end
