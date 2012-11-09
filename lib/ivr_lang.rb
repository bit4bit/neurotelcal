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
#Fin

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
      (space.maybe >> (si_command | decir_command | reproducirlocal_command | reproducir_command  | registrar_command | colgar_command)).repeat
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
  
end
