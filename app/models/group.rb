class Group < ActiveRecord::Base
  attr_accessible :name, :campaign_id

  has_many :client
  has_many :message, :order => 'priority DESC'
  belongs_to :campaign
end
