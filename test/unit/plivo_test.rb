require 'test_helper'

class Plivo
  #se omite conexion a servicio plivo
  def verificar_conexion
    return true
  end
end

class PlivoTest < ActiveSupport::TestCase

  test "should save with dialplan" do
    plivo = Plivo.all.first

    plivo.dial_plan =<<DIALPLAN
Match ^574 gateway=sofia/gateway/one/
DIALPLAN

    assert plivo.save, "Not saved Dial plan error: %s" % plivo.errors.to_a.to_s
    
    plivo.dial_plan =<<DIALPLAN
#PRINCIPAL
Match ^574 gateway=sofia/gateway/one/
#SALIDA POR ATRAS
Match ^555 gateway=sofia/gateway/one/
DIALPLAN
    assert_nothing_raised {plivo.save}
    assert plivo.save, "Not saved dial plan with comment error: %s" % plivo.errors.to_a.to_s
  end


  #Verificamos el dialplan
  test "should give a gateway with dialplan" do
    plivo = Plivo.all.first
    plivo.dial_plan ="
Match ^227[[:digit:]]{4}$ gateway=sofia/gateway/one/
Match ^[[:digit:]]{6}$ gateway=sofia/gateway/six/
Match .+ gateway=sofia/gateway/generic/
"
    assert plivo.save, "Not saved dialplan"

    client = Client.new({:phonenumber => '2273434'})
    assert_equal 'sofia/gateway/one/', plivo.gateway_by_client(client)
    
    client = Client.new({:phonenumber => '23099999'})
    assert_equal 'sofia/gateway/generic/', plivo.gateway_by_client(client)

    client = Client.new({:phonenumber => '531913'})
    assert_equal 'sofia/gateway/six/', plivo.gateway_by_client(client)
  end

  
end
