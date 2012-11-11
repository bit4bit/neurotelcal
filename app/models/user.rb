# -*- coding: utf-8 -*-
require 'digest/sha2'

class User < ActiveRecord::Base
  attr_accessible :name, :password, :password_confirmation
  validates :name, :presence => true, :uniqueness => true
  validates :password, :confirmation => true
  attr_accessor :password_confirmation
  attr_accessible :monitor, :monitor_campaign_id, :admin
  attr_reader :password
  
  validate :password_must_be_present
  has_many :notifications
  
  class << self
    def authenticate(name, password)
      if user = find_by_name(name)
        if user.hashed_password == encrypt_password(password, user.salt)
          user
        end
      end
    end

    def encrypt_password(password, salt)
      Digest::SHA2.hexdigest(password + "random" + salt)
    end
  end

  def password=(password)
    @password = password
    if password.present?
      generate_salt
      self.hashed_password = self.class.encrypt_password(password, salt)
    end
  end

  private
  def password_must_be_present
    errors.add(:password, "Falta contraseña") unless hashed_password.present?
  end

  def generate_salt
    self.salt = self.object_id.to_s + rand.to_s
  end
end
