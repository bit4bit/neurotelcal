class Campaign < ActiveRecord::Base
  attr_accessible :description, :name
  
  validates :name, :presence => true, :uniqueness => true
  has_many :resource
  has_many :message
  has_many :client
  has_many :plivo
end
