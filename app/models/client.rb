# -*- coding: utf-8 -*-
class Client < ActiveRecord::Base
  attr_accessible :campaign_id, :fullname, :group_id, :phonenumber
  belongs_to :campaign
  belongs_to :group
  
  has_many :call

  validates :fullname, :group_id, :presence => true
  #validates :phonenumber, :format => {
  #  :with => /[0-9]+([ ][0-9]+)*/,
  #  :message => "Solo número entre 7 y 10 digitos separados por espacio"
  #}
end
