class Calendar < ActiveRecord::Base
  attr_accessible :campaign_id, :do_call, :interval, :name

  validates :name, :interval, :do_call, :presence => true

  validates :name, :uniqueness => true
  validates :interval, :numericality => true
  
  belongs_to :campaign
  has_many :call
end
