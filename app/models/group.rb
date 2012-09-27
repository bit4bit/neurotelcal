class Group < ActiveRecord::Base
  attr_accessible :name, :campaign_id, :messages_share_clients
  attr_accessible :enable
  has_many :client, :order => 'priority DESC'
  has_many :message, :order => 'priority DESC', :dependent => :delete_all
  belongs_to :campaign

  def id_messages_share_clients
    message.all.map {|m| m.id }
  end
end
