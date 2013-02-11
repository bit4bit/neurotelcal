# Copyright (C) 2012 Bit4Bit <bit4bit@riseup.net>
#
#
# This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#Aqui creamos parse para lenguaje IVR
#Esto reemplaza la libreria Ronela..
#con este ya podemos tener:
#Si =3
# Decir "Hola"
#No
# Decir "haa"
#Fin
#el cual es cambiado a un hash,ej:
# {:si => {:condicion => '=', :valor => 3}, :sicontinuar => {:decir => "hola", :nocontinuar => {:decir => "haa"}}}
#y luego cambiado a el fortmo XML de plivo.


module IVRLang
  
  class Parser < Parslet::Parser
    rule :space do
      (match '[ ]').repeat(1)
    end
    
    rule :literals do
      (literal >> eol).repeat
    end
    
    rule :literal do
      (integer | string).as(:literal) >> space.maybe
    end
    
    rule :string do
      str('"') >>
        (
         (str('\\') >> any) |
         (str('"').absent? >> any)
         ).repeat >>
        str('"')
    end
    
    rule :integer do
      match('[0-9]').repeat(1).as(:integer)
    end
    
    rule :eol do
      line_end.repeat(1)
    end
    
    rule :line_end do
      crlf >> space.maybe
    end
    
    rule :crlf do
      match('[\r\n]').repeat(1)
    end
    
    rule :op do
      match('[=]')
    end
    
    rule :command_list do
      (space.maybe >> (si_command | decir_command | contactar_command | reproducirlocal_command | reproducir_command  | registrar_command | colgar_command)).repeat
    end
    
    rule :no_command do
      str("No") >> space.maybe >> line_end >>
        (command_list).as(:no_body)
    end
    
    rule :si_command do
      str("Si").as(:command) >> space.maybe >> op.as(:op) >> (integer|string).as(:value) >> space.maybe >> line_end >> 
        ( command_list).as(:if_body) >> no_command.maybe >> str("Fin") >>  line_end.maybe
    end
    
    rule :command_options do
      (space >> match("[a-zA-Z0-9]").repeat(1).as(:name) >> match("[=]") >> (integer | string).as(:value)).repeat.as(:options)
    end
    
    rule :contactar_command do
      str("Contactar").as(:command) >> space >> string.as(:arg) >> command_options.maybe >> line_end.maybe
    end
    
    rule :decir_command do
      str("Decir").as(:command) >> space >> string.as(:arg) >> command_options.maybe >> line_end.maybe
    end
   
    rule :reproducirlocal_command do
      str("ReproducirLocal").as(:command) >> space >> string.as(:arg) >> command_options.maybe >> line_end.maybe
    end 

    rule :reproducir_command do
      str("Reproducir").as(:command) >> space >> string.as(:arg) >> command_options.maybe >> line_end.maybe
    end
    
    rule :registrar_command do
      str("Registrar digitos").as(:command) >> command_options.maybe >> line_end.maybe
    end
    
    rule :colgar_command do
      str("Colgar").as(:command) >> command_options.maybe >> line_end.maybe
    end
    
    rule :expression do
      command_list
    end
    
    root :expression
  end
  

  def self.call_sequence(str, campaign_id = nil)
    p = IVRLang::Parser.new
    transform = Parslet::Transform.new do 
      
      rule(:integer => simple(:x)) { Integer(x) }
      rule(:command => "Si", :op => simple(:o), :value => simple(:x), :if_body => subtree(:i), :no_body => subtree(:n)){
        {:si => {:condicion => o.to_s, :valor => x.to_s}, :sicontinuar => i, :nocontinuar => n}
      }
      
      rule(:command => "Registrar digitos", :options => subtree(:o)){
        options = {:retries => 1, :timeout => 5, :numDigits => 99, :validDigits => '0123456789*#'}
        o.each{|option|
          case option[:name].to_s
          when "intentos"
            options[:retries] = option[:value].to_i
          when 'duracion'
            options[:timeout] = option[:value].to_i
          when 'cantidad'
            options[:numDigits] = option[:value].to_i
          when 'digitosValidos'
            options[:validDigits] = option[:value].to_s.gsub(/^\"|\"$/,"")
          when 'audio'
            options[:audio] = option[:value].to_s.gsub(/^\"|\"$/,"")
          when 'decir'
            options[:decir] = option[:value].to_s.gsub(/^\"|\"$/,"")
          else
            options[option[:name].to_s.gsub(/^\"|\"$/,"")] = option[:value].to_s.gsub(/^\"|\"$/,"")
          end
        }
        {:register => :digits, :options => options}
      }
      
      rule(:command => "Reproducir", :arg => simple(:x), :options => subtree(:l)){
        path = nil
        uri = x.to_s.gsub(/^\"|\"$/,"")
        if campaign_id
          r = Resource.where(:campaign_id => campaign_id, :type_file => 'audio', :name => x.to_s.gsub(/^\"|\"$/,"")).first
          path = r.file if r
        end
        
        unless path
          path = uri
          {:audio_local => path}
        else
          {:audio => path}
        end
        
      }

      rule(:command => "ReproducirLocal" ,:arg => simple(:x), :options => subtree(:o)){
        {:audio_local => x.to_s.gsub(/^\"|\"$/,"")}
      }
      rule(:command => "Decir", :arg => simple(:x), :options => subtree(:o)){
        v = {:decir => x.to_s.gsub(/^\"|\"$/,"")}
      }

      rule(:command => "Contactar", :arg => simple(:x), :options => subtree(:o)){
        v = {:contactar => x.to_s.gsub(/^\"|\"$/,""), :codecs => "", :digitar => "", :duracion => "", :intentos => "0"}
        o.each{|option|
          option_value = option[:value].to_s.gsub(/^\"|\"$/,"")
          case option[:name].to_s
          when "pasarela"
            v[:pasarela] = option_value
          when "codec"
            v[:codec] = option_value
          when "digitar" #envia digito
            v[:digitar] = option_value
          when "duracion"
            v[:duracion] = option_value.to_i
          when "intentos"
            v[:intentos] = option_value.to_i
            #@todo sendOnPreanswer??
          end
        }
        v
      }

      rule(:command => "Colgar", :options => subtree(:o)) {
        v = {:colgar => true, :razon => '', :segundos => 0}
        o.each{|option|
          case option[:name].to_s
          when "razon"
            v[:razon] = option[:value].to_s.gsub(/^\"|\"$/,"")
          when "segundos"
            v[:segundos] = option[:value].to_i
          end
          
        }
        v
      }
    end
    transform.apply(p.parse(str))
  end
  
  module Helper

    #
    #Procesa el mensajes tomado en pasos
    #para ir creando dinamicamente el XML para plivo.
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
        elsif not step[:razon].to_s.empty?
          xml.Hangup :reason => step[:razon]
        else
          xml.Hangup
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
  
end
