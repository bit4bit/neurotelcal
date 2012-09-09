class PlivoCall < ActiveRecord::Base
  attr_accessible :data, :uuid, :status, :hangup_enumeration, :call_id, :created_at, :plivo_id, :step, :number

  belongs_to :client
  belongs_to :call
  belongs_to :plivo

  def call_sequence
    return YAML::load(data)
  end
  
  def update_call_sequence(seq)
    self.data = seq.to_yaml
    self.save()
  end
  
  def reset_step
    self.step = 0
    self.save()
  end

  def next_step
    self.step += 1
    self.save()
  end

  def answered?
    answer_list = ['NORMAL_CLEARING', 'ALLOTED_TIMEOUT']
    return self.hangup_enumeration == 'NORMAL_CLEARING'
  end
  
end
