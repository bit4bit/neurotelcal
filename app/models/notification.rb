class Notification < ActiveRecord::Base
  attr_accessible :msg, :type_msg, :user_id
  belongs_to :user
end
