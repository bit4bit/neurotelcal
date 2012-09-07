class Entity < ActiveRecord::Base
  attr_accessible :description, :direction, :leader, :name, :phone, :slogan
end
