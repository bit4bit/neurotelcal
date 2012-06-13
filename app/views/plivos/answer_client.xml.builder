xml.instruct! :xml, :version => '1.0'
xml.Response do
  @call_sequence.each do |step|
    if step[:audio]
      xml.Play 'http://192.168.1.3:3000/resources/audio/' + File.basename(step[:audio].to_s)
    elsif step[:audio_local]
      xml.Play step[:audio_local]
    elsif step[:decir]
      xml.Speak step[:decir]
    end
  end
  xml.Hangup 
end
