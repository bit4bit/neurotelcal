# -*- coding: utf-8 -*-
require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "description to call sequence IVRLang" do
    assert_equal  [{:decir => "hola"}],IVRLang.call_sequence('Decir "hola"')
    assert_equal [{:decir => "a"},{:decir => "b"}], IVRLang.call_sequence('Decir "a"
Decir "b"')
    assert_equal [{:si => {:condicion => '=', :valor => '3'}, :sicontinuar => [{:decir => 'hola'}], :nocontinuar => [{:decir => 'cagada'}]}], IVRLang.call_sequence('Si =3
Decir "hola"
No
Decir "cagada"
Fin')
    assert_equal([{:si => {:condicion => '=', :valor =>'3'}, 
                   :sicontinuar => [
                                    {:si => {:condicion => '=', :valor => '4'},
                                      :sicontinuar => [{:decir => 'mero interno'}],
                                      :nocontinuar  => [{:decir => 'mero no'}]
                                    }],
                   :nocontinuar => [
                                    {:decir => 'fin'}
                                   ]
                 }], IVRLang.call_sequence('Si =3
 Si =4
  Decir "mero interno"
 No
  Decir "mero no"
 Fin
No
 Decir "fin"
Fin'))

    assert_equal [
                  {:decir => "inicia"},{:si => {:condicion => '=', :valor => '3'}, :sicontinuar => [{:decir => 'hola'}], :nocontinuar => [{:decir => 'cagada'}]}, {:decir => "finaliza"}], IVRLang.call_sequence('Decir "inicia"
Si =3
Decir "hola"
No
Decir "cagada"
Fin
Decir "finaliza"')

    assert_equal [{:register => :digits, :options => {:retries => 1, :timeout => 5, :numDigits=> 99, :validDigits => '0123456789*#'}}], IVRLang.call_sequence("Registrar digitos")
    assert_equal [{:register => :digits, :options => {:retries => 5, :timeout => 5, :numDigits=> 99, :validDigits => '0123456789*#'}}], IVRLang.call_sequence("Registrar digitos intentos=5")
    assert_equal [{:register => :digits, :options => {:retries => 5, :timeout => 10, :numDigits=> 3, :validDigits => '12'}}], IVRLang.call_sequence("Registrar digitos intentos=5 duracion=10 cantidad=3 digitosValidos=\"12\"")

    assert_equal [{:audio_local => "/tmp/prueba.ogg"}], IVRLang.call_sequence('ReproducirLocal "/tmp/prueba.ogg"')
  end
  
  test "description to call sequence IVRLang Resource Campaign" do
    cid = Campaign.first.id
    r = Resource.new()
    r.campaign_id = cid
    r.file = "teste.wav"
    r.name = "prueba"
    r.type_file = 'audio'
    assert r.save(:validate => false)
    print "Campaign used %d\n" % cid
    assert_equal [{:audio => "teste.wav"}], IVRLang.call_sequence('Reproducir "prueba"', cid)
  end
  
  test "description to call sequence option with '" do

  end

end
