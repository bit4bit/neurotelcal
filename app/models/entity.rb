class Entity < ActiveRecord::Base
  attr_accessible :description, :direction, :leader, :name, :phone, :slogan
  validates :name, :presence => true, :uniqueness => true
  has_many :campaign, :dependent => :delete_all
end
