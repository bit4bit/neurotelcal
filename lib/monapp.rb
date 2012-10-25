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

#MonAPP permite monitorear e interactuar con aplicativos de software.

require 'logger'
require 'net/smtp'

module MonAPP

  
  class Assertion < Exception;  end
  class Solution; end
  
  module Assertions
    def assert test, msg = nil
      msg ||= "Failed assertion, not give message"
      unless test then
        msg = msg.call if Proc === msg
        raise MonAPP::Assertion, msg
      end
    end
  end
  
  #Un Case define la logica que se debe seguir
  #para encontrar un problema y buscarle una posible solucion

  class Case
    include MonAPP::Assertions

    def initialize(name, logger = nil)
      @name = name
      @problems = {}
      @its = {}
      @solutions = {}
      @without_solution = {}
      @setups = {}
      Rails.logger.debug('created case %s' % @name)
    end
    
    def run(problem = nil)
      Rails.logger.debug('running case %s' % @name)
      begin
        @problem = nil
        if problem
          instance_eval(@setups[problem]) unless @setups[problem].nil?
          @problem = problem
          Rails.logger.debug('seeing -> %s' % problem)
          instance_eval(&@problems[problem])
        else
          @problems.each{|k,f| @problem = k;  
          Rails.logger.debug('seeing -> %s' % k)
            instance_eval(@setups[k]) unless @setups[k].nil?
            instance_eval(&f)}    
        end
        
      rescue MonAPP::Assertion => e #Hay que solucionar el problema
        begin
          Rails.logger.debug("Finding solution for #{@problem}")
          @solutions[@problem].each{|f| f.call}
          run(@problem)
        rescue MonAPP::Solution => esolg #hay solucion a problema
          Rails.logger.debug("We fond solution for #{@problem}")
          run(@problem)
        rescue MonAPP::Assertion => esol #No hay solucion a las prueba
          Rails.logger.error("Without solution for #{@problem}")
        rescue Exception => e
          Rails.logger.error("Without solution for #{@problem} exception %s" % e.backtrace.join("\n")) 
          @without_solution[@problem].call if @without_solution[@problem]
        end
      end
    end
    
    #Se indica el nombre del problema
    #y la logica para aceptar el plobrema
    def problem(name, &block)
      @problems[name] = block
    end
    
    #Se da la solucion a problema
    #si no se desea que se prueben mas soluciones
    #se envia Mon::Solution
    def solution(name, &block)
      @solutions[name] = [] if @solutions[name].nil?
      @solutions[name] << block
    end
    
    #No hay solucion para el problema
    def without_solution(name, &block)
      @without_solution[name] = block
    end

    def try_problem(name)
      run(name)
    end
    
    #Cargadador a ser llamado al ejecutar un problema
    def setup(name = nil, &block)
      @setups[name] = block unless name.nil?
      instance_eval(&block) if name.nil?
    end
    
    def notify msg, type = :info
      case type
      when :info
        Rails.logger.info("Message to notify: #{msg}")
      when :fatal
        Rails.logger.info("Message to notify(fatal): #{msg}")
      end
      
    end
  end
  
  @@cases = []
  def self.evaluate(name, logger = nil, &script)
    c = MonAPP::Case.new(name, logger)
    c.instance_eval(&script)
    @@cases << c
  end
  
  def self.run()
    @@cases.each {|c| 
      c.run
    }
  end
end


module Kernel
  def monapp_case desc, &block
    MonAPP.evaluate(desc, &block)
  end
  def monapp_run
    ::MonAPP.run
  end
  
end

if $0 == __FILE__
  
  monapp_case 'file' do
    setup do
    end
    
    problem 'no existe archivo' do
      assert File.exists?('/tmp/pruebo')
    end
    
    solution 'no existe archivoo' do
      File.open('/tmp/pruebo', 'w') do |f|
        f.write('mero')
      end
    end
    
    without_solution 'no existe archivo' do
      print "No hay solucion"
    end
    
  end
  
  MonAPP.run
end
