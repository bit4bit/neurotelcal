class PlivoCall < ActiveRecord::Base
  attr_accessible :data, :uuid, :status, :hangup_enumeration, :call_id, :created_at

  belongs_to :client
  belongs_to :call
end
