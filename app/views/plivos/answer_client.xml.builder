xml.instruct! :xml, :version => '1.0'
xml.Response do
  @call_sequence.slice(@plivocall.step, @call_sequence.length).each do |step|
    @plivocall.next_step
    if step[:audio]
      local_resource = Rails.root.join(step[:audio])
      xml.Play @plivo.app_url.to_s + '/resources/audio/' + File.basename(step[:audio].to_s)
    elsif step[:audio_local]
      xml.Play step[:audio_local]
    elsif step[:decir]
      xml.Speak step[:decir]
    elsif step[:register]
      case step[:register]
        when :digits
        xml.GetDigits :action => @plivo.app_url.to_s + get_digits_client_plivo_path(@plivocall.uuid), :retries => step[:options][:retries], :timeout => step[:options][:timeout], :numDigits => step[:options][:numDigits], :validDigits => step[:options][:validDigits]
      end
      
      break
    end
    
  end
  xml.Hangup 
end
