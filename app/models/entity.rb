class Entity < ActiveRecord::Base
  attr_accessible :description, :direction, :leader, :name, :phone, :slogan, :created_at, :updated_at
  validates :name, :presence => true, :uniqueness => true
  has_many :campaign, :dependent => :delete_all
end
