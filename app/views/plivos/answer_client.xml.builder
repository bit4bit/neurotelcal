xml.instruct! :xml, :version => '1.0'
xml.Response do
  @call_sequence.slice(@plivocall.step, @call_sequence.length).each do |step|
    @plivocall.next_step
    break unless process_call_step(xml, step)
  end
  xml.Hangup 
end
