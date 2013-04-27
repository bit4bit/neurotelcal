xml.instruct! :xml, :version => '1.0'
xml.Response do
  @call_sequence.slice(@plivocall.step, @call_sequence.length).each do |step|
    plivocall = Rails.cache.read(:plivocall_id => @plivocall.id)
    unless plivocall.nil?
      @plivocall = plivocall
      @plivocall.step += 1
      Rails.cache.write(:plivocall_id => @plivocall.id, @plivocall)
    else
      @plivocall.next_step      
    end
   


    break unless process_call_step(xml, step)
  end
  xml.Hangup 
end
