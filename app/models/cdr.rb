class Cdr < ActiveRecord::Base
  attr_accessible :account_code, :answer_stamp, :billsec, :bleg_uuid, :caller_id_name, :caller_id_number, :context, :destination_number, :duration, :end_stamp, :hangup_cause, :start_stamp, :uuid
end
