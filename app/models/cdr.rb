class Cdr < ActiveRecord::Base
  attr_accessible :account_code, :answer_stamp, :billsec, :bleg_uuid, :caller_id_name, :caller_id_number, :context, :destination_number, :duration, :end_stamp, :hangup_cause, :start_stamp, :uuid
  
  def plivo_call
    return PlivoCall.where(:uuid => self.uuid).first
  end
  
  def plivo_call?
    return PlivoCall.where(:uuid => self.uuid).exists?
  end
  
end
