module PlivosHelper

  def process_call_step(xml, step)
    if step[:si]
      vr = false
      last_step = {}
      @call_sequence.reverse.each do |call_step|
        #print call_step
        if call_step[:result]
          last_step = call_step
          break
        end
      end
      begin
        case step[:si][:condicion]
        when "="
          vr = true if step[:si][:valor].to_s == last_step[:result].to_s
        end
      rescue
      end

      #se elimina la secuencia {:si..} y se reemplaza por su continuacion
      #quedando al final una sola sequencia [...]
      if vr == true
        cu = @call_sequence
        cu.slice!(cu.size - 1, 1)
        step[:sicontinuar].each { |v| cu << v}
        @plivocall.update_call_sequence(cu)
        step[:sicontinuar].each { |v| 
          return false unless process_call_step(xml, v)
        }
      else
        cu = @call_sequence
        cu.slice!(cu.size - 1, 1)
        #se guarda el ultimo resultado
        cu << {:result => last_step[:result].to_s} unless last_step[:result]
        step[:nocontinuar].each { |v| cu << v}
        @plivocall.update_call_sequence(cu)
        step[:nocontinuar].each { |v| 
          return false unless process_call_step(xml, v) 
        }
      end
    elsif step[:colgar]
      if step[:segundos] > 0
        xml.Hangup :reason => step[:razon], :schedule => step[:segundos]
      else
        xml.Hangup :reason => step[:razon]
      end
    elsif step[:audio]
      local_resource = Rails.root.join(step[:audio])
      audio = @plivo.app_url.to_s + '/resources/audio/' + File.basename(step[:audio].to_s)
      xml.Play "${http_get(%s)}" % audio.to_s
    elsif step[:audio_local]
      xml.Play step[:audio_local]
    elsif step[:decir]
      xml.Speak step[:decir]
    elsif step[:contactar]
      xml.Dial :action => @plivo.app_url.to_s + continue_sequence_client_plivo_path(@plivocall.uuid) do 
        xml.Number step[:contactar], :gateways => step[:pasarela], :gatewayCodecs => step[:codec], :sendDigits => step[:digitar], :gatewayTimeouts => step[:duracion], :gatewayRetries => step[:intentos]
      end
      return false
    elsif step[:register]
      case step[:register]
      when :digits
        xml.GetDigits :action => @plivo.app_url.to_s + get_digits_client_plivo_path(@plivocall.uuid), :retries => step[:options][:retries], :timeout => step[:options][:timeout], :numDigits => step[:options][:numDigits], :validDigits => step[:options][:validDigits] do
          if step[:options][:audio]
            xml.Play step[:options][:audio]
          end
          if step[:options][:decir]
            xml.Speak step[:options][:decir]
          end
        end
      end
      return false
    end
    return true
  end
end
