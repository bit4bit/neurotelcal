# -*- coding: utf-8 -*-
require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "description to call sequence option with '" do

  end

  test "description to call sequence SI" do
    message = Message.new(:description => "Si = 3 / Decir hola | Decir cagada")
    assert_equal([{:si => {:condicion => '=', :valor => '3'}, :sicontinuar => [{:decir =>'hola'}], :nocontinuar => [{:decir => "cagada"}]}], message.description_to_call_sequence({}))
    message = Message.new(:description => "Si = 3 / Si = 4 / Decir mero interno | Decir mero no | Decir fin")
    assert_equal([{:si => {:condicion => '=', :valor =>'3'}, 
                   :sicontinuar => [
                                    {:si => {:condicion => '=', :valor => '4'},
                                      :sicontinuar => [{:decir => 'mero interno'}],
                                      :nocontinuar  => [{:decir => 'mero no'}]
                                    }],
                   :nocontinuar => [
                                    {:decir => 'fin'}
                                    ]
                 }], message.description_to_call_sequence({}))

    message = Message.new(:description => "Registrar digitos cantidad=1
Si = 1 / Decir choose one > Decir now select again > Si = 2 / Decir you choose two | Decir you are equiovcado | Decir good bye")
    assert_equal([{:register => :digits, :options => {:retries => 1, :timeout => 5, :numDigits => 1, :validDigits => "0123456789*#"}},
                  {:si => {:condicion => '=', :valor => '1'},
                    :sicontinuar => [{:decir => 'choose one'},
                                     {:decir => 'now select again'},
                                     {:si => {:condicion => '=', :valor => '2'},
                                       :sicontinuar => [{:decir => 'you choose two'}],
                                       :nocontinuar => [{:decir => 'you are equiovcado'}]
                                     }],
                    :nocontinuar => [{:decir => 'good bye'}]
                  }], message.description_to_call_sequence({}))
                   
  end
end
