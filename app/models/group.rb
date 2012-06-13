class Group < ActiveRecord::Base
  attr_accessible :name, :campaign_id

  has_many :client
  belongs_to :campaign
end
