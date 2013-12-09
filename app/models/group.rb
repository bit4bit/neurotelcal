class Group < ActiveRecord::Base
  default_scope order('created_at DESC')
  attr_accessible :name, :campaign_id, :messages_share_clients
  attr_accessible :enable
  attr_accessible :created_at, :updated_at
  attr_accessible :status
  has_many :client, :dependent => :delete_all, :order => 'priority DESC, callable DESC, created_at ASC'
  has_many :message, :order => 'priority DESC', :conditions => 'processed = 0', :dependent => :delete_all
  belongs_to :campaign

  def deep_name
    new_name = ""
    if campaign
      new_name = campaign.deep_name + " -> "
    end
    new_name += name
    return new_name
  end
  
  def id_messages_share_clients
    message.all.map {|m| m.id }
  end

  def need_process_messages?
    message.all.map {|m| return true if m.time_to_process? and m.time_to_process_calendar?}
    return false
  end

  def total_calls
    client.where(:callable => false).count
  end
  
  def stop?
    r = Group.select('status').where(:id => self.id).first.status
    r == 'stop' || r == 'end'
  end
  
  def start?
    r = Group.select('status').where(:id => self.id).first.status
    r == 'start'
  end
  
end
