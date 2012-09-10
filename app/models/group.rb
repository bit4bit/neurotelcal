class Group < ActiveRecord::Base
  attr_accessible :name, :campaign_id, :messages_share_clients

  has_many :client, :order => 'priority DESC'
  has_many :message, :order => 'priority DESC'
  belongs_to :campaign
end
