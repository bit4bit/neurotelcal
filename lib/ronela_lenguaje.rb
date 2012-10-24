# -*- coding: utf-8 -*-
=begin
 Ronela un Motor de novelas gráficas.
 (C) 2011 Jovany Leandro G.C <info@manadalibre.org>

  This file is part of Ronela.

    Ronela is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    Ronela is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
=end


class RonelaLenguajePailas < Exception
end


#==Ronela Lenguaje
#Clase generica para leer lenguaje de ronela.
#el lenguaje ronela tiene las siguientes palabras claves
#
# - Personaje => Crea personaje
# - Imagen => Crea imagen desde archivo
# - Escenario => Muestra imagen como escenario
# - Mostrar => Muestra imagen
# - \w > .... => El personaje dice ...
class RonelaLenguaje

  def initialize (&func)
    @acciones = {}
    @nada = func unless func.nil?
  end

  def definir_accion &func
    
  end
  def scan(string)

    if string.kind_of? String
      string.delete! "\n"
    end

    #se elimina comentario
    string.gsub!(/#.*$/,'')
    string.strip!

    #toma primer palabra que determina que hacer
    if string.nil? or string.empty?
      return nil
    end
    


    partida = string.split
    accion = partida[0]

    unless @acciones.has_key? accion
      #si se paso manejador cuando no
      #se entiende la accion se llama
      if !@nada.nil?
        return @nada.call(accion, partida[1..-1].join(' '))
      else
        raise RonelaLenguajePailas, string
      end
    end


    variables = {}
    resto = []

    for i in 1..(partida.size)
      #saca variable ti color=rojo
      if m = partida[i].to_s.match(/([0-9a-zA-Z\-_\/\\\.ñÑáéíóúÁÉÍÓÚ]+)=([0-9a-zA-Z\-_\/,\\\.ñÑáéíóúÁÉÍÓÚ]+)/)
        variables[m[1]] = m[2]
        #el resto va 
      elsif !partida[i].to_s.empty?
        resto << partida[i].to_s
      end
    end

    @acciones[accion].each {|f| 
      f.call(variables, resto)
    }
    
  end

  #@method indica la accion y se espera una funcion
  #que será llamada cuando se encuentre la accion, se pueden registrar varias funcionse para una misma accion
  #con los argumentos @variables, @resto
  def method_missing(method, *args, &func)
    unless @acciones[method.to_s].kind_of? Array
      @acciones[method.to_s] = []
    end

    @acciones[method.to_s] << func
  end
end




if $0 == __FILE__

$personas = {}


p = RonelaLenguaje.new do
  |accion, resto|
  
  if $personas.has_key? accion
    puts "Personaje #{$personas[accion]} dice: #{resto}"
  end
end


p.Personaje do |variables, resto|
  nombre = resto.join ' '
  if variables.has_key? "apodo"
    $personas[variables["apodo"]] = nombre
  end
end


#crea personaje
p.scan "Personaje jovany leandro apodo=jova" 

#dice algo
p.scan "jova Hola que mas"

end



