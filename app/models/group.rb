class Group < ActiveRecord::Base
  attr_accessible :name, :campaign_id

  has_many :client
  has_many :message
  belongs_to :campaign
end
