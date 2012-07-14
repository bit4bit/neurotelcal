xml.instruct! :xml, :version => '1.0'

xml.Response do
  @call_sequence.each do |step|
    if step[:audio]
      local_resource = Rails.root.join(step[:audio])
      xml.Play @plivo.app_url.to_s + '/resources/audio/' + File.basename(step[:audio].to_s)
    elsif step[:audio_local]
      xml.Play step[:audio_local]
    elsif step[:decir]
      xml.Speak step[:decir]
    end
  end
  xml.Hangup 
end
