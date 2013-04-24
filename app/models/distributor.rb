class Distributor < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :plivo
  attr_accessible :description, :filter
end
