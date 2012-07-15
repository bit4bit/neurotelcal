class PlivoCall < ActiveRecord::Base
  attr_accessible :data, :uuid, :status, :hangup_enumeration, :call_id, :created_at, :plivo_id, :step, :number

  belongs_to :client
  belongs_to :call
  belongs_to :plivo

  def call_sequence
    return YAML::load(data)
  end
  
  def next_step
    self.step += 1
    self.save()
  end

  def answered?
    return self.hangup_enumeration == 'NORMAL_CLEARING'
  end
  
end
