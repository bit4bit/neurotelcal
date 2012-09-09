require 'test_helper'

class PlivosControllerTest < ActionController::TestCase
=begin
  setup do
    @plivo = plivos(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:plivos)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create plivo" do
    assert_difference('Plivo.count') do
      post :create, :plivo => { :api_url => @plivo.api_url, :auth_token => @plivo.auth_token, :campaign_id => @plivo.campaign_id, :sid => @plivo.sid }
    end

    assert_redirected_to plivo_path(assigns(:plivo))
  end

  test "should show plivo" do
    get :show, :id => @plivo
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @plivo
    assert_response :success
  end

  test "should update plivo" do
    put :update, :id => @plivo, :plivo => { :api_url => @plivo.api_url, :auth_token => @plivo.auth_token, :campaign_id => @plivo.campaign_id, :sid => @plivo.sid }
    assert_redirected_to plivo_path(assigns(:plivo))
  end

  test "should destroy plivo" do
    assert_difference('Plivo.count', -1) do
      delete :destroy, :id => @plivo
    end

    assert_redirected_to plivos_path
  end
=end
  def setup
    ent = Entity.new(:name => 'DeTeste')
    assert ent.save()
    campaign = Campaign.new(:name => 'DePruebaTest', :entity_id => ent)
    assert campaign.save()
    plivo = Plivo.new(:app_url => "http://192.168.1.1:3000", :api_url => "http://192.168.1.100:8088", :sid => "tremendoelplivo", :auth_token => "tremendoelplivo", :gateways => "user/", :campaign_id => campaign.id)
    assert plivo.save()
    
    group = Group.new(:name => 'GrupoTeste', :campaign_id => campaign)
    assert group.save()
    client = Client.new(:fullname => 'deprueba', :phonenumber => 'luis101', :campaign_id => campaign, :group_id => group)
    assert client.save()
  end
  
  test "answer client decir hola" do
    message = Message.new(:description => "Decir hola")
    call = Call.new(:client_id => Client.all.first)
    assert call.save()
    plvc = PlivoCall.new(:uuid => 'testeo',  :step => 0, :data => message.description_to_call_sequence({}).to_yaml, :plivo_id => Plivo.all.first, :call_id => call)
    assert plvc.save()

    post :answer_client, {:format => :xml, :ALegRequestUUID => 'testeo'}
    builder = Builder::XmlMarkup.new(:indent => 2)
    builder.instruct!
    xml = builder.Response { |r| r.Speak 'hola'; r.Hangup}
    assert_equal xml, @response.body


  end

  test "answer client registrar digitos" do
    message = Message.new(:description => "Registrar digitos cantidad=1")
    call = Call.new(:client_id => Client.all.first)
    assert call.save()
    plvc = PlivoCall.new(:uuid => 'testeo',  :step => 0, :data => message.description_to_call_sequence({}).to_yaml, :plivo_id => Plivo.all.first, :call_id => call)
    assert plvc.save()

    post :answer_client, {:format => :xml, :ALegRequestUUID => 'testeo'}
    builder = Builder::XmlMarkup.new(:indent => 2)
    builder.instruct!
    xml = builder.Response { |b| b.GetDigits(:action=>"http://192.168.1.1:3000/plivos/testeo/get_digits_client", :retries => 1, :timeout => 5, :numDigits => 1, :validDigits => "0123456789*#"){}; b.Hangup}
    assert_equal xml, @response.body

  end

  test "answer client registrar/si" do
    message = Message.new(:description => "Registrar digitos cantidad=1\nSi = 3 / Decir el 3 | Decir ninguno")
    call = Call.new(:client_id => Client.all.first)
    assert call.save()
    
    #se compara el si cumple = 3
    sq = message.description_to_call_sequence({})
    sq[0][:result] = 3
    plvc = PlivoCall.new(:uuid => 'testeo',  :step => 1, :data => sq.to_yaml, :plivo_id => Plivo.all.first, :call_id => call)
    assert plvc.save()

    post :answer_client, {:format => :xml, :ALegRequestUUID => 'testeo'}
    builder = Builder::XmlMarkup.new(:indent => 2)
    builder.instruct!
    xml = builder.Response { |b| b.Speak "el 3"; b.Hangup }
    assert_equal xml, @response.body

    plvc = PlivoCall.where(:uuid => 'testeo').first
    assert_equal [{:register=>:digits, :options=>{:retries=>1, :timeout=>5, :numDigits=>1, :validDigits=>"0123456789*#"}, :result => 3}, {:decir => 'el 3'}], plvc.call_sequence

    #se compar el no cumple = 3
    sq = message.description_to_call_sequence({})
    sq[0][:result] = 4
    plvc = PlivoCall.new(:uuid => 'testeo2',  :step => 1, :data => sq.to_yaml, :plivo_id => Plivo.all.first, :call_id => call)
    assert plvc.save()

    post :answer_client, {:format => :xml, :ALegRequestUUID => 'testeo2'}
    builder = Builder::XmlMarkup.new(:indent => 2)
    builder.instruct!
    xml = builder.Response {|b| b.Speak 'ninguno'; b.Hangup}
    assert_equal xml, @response.body

    plvc = PlivoCall.where(:uuid => 'testeo2').first
    assert_equal [{:register=>:digits, :options=>{:retries=>1, :timeout=>5, :numDigits=>1, :validDigits=>"0123456789*#"}, :result => 4}, {:decir => 'ninguno'}], plvc.call_sequence
  end

  test 'answer_client si anidado' do
    message = Message.new(:description => "Registrar digitos cantidad=1\nSi = 3 / Registrar digitos cantidad=1 > Si = 2 / Decir si 2 | Decir no 2  | Decir ninguno")
    call = Call.new(:client_id => Client.all.first)
    assert call.save()
    
    sq = message.description_to_call_sequence({})
    sq[0][:result] = 3
    plvc = PlivoCall.new(:uuid => 'testeo',  :step => 1, :data => sq.to_yaml, :plivo_id => Plivo.all.first, :call_id => call)
    assert plvc.save()

    post :answer_client, {:format => :xml, :ALegRequestUUID => 'testeo'}
    builder = Builder::XmlMarkup.new(:indent => 2)
    builder.instruct!
    xml = builder.Response { |b| b.GetDigits(:action=>"http://192.168.1.1:3000/plivos/testeo/get_digits_client", :retries => 1, :timeout => 5, :numDigits => 1, :validDigits => "0123456789*#"){}; b.Hangup}
    assert_equal xml, @response.body

    plvc = PlivoCall.where(:uuid => 'testeo').first
    cl = plvc.call_sequence
    cl[1][:result] = 2
    plvc.update_call_sequence(cl)
    post :answer_client, {:format => :xml, :ALegRequestUUID => 'testeo'}
    builder = Builder::XmlMarkup.new(:indent => 2)
    builder.instruct!
    xml = builder.Response {|b| b.Speak 'si 2'; b.Hangup}
    assert_equal xml, @response.body


    plvc = PlivoCall.where(:uuid => 'testeo').first
    assert_equal [{:register=>:digits, :options=>{:retries=>1, :timeout=>5, :numDigits=>1, :validDigits=>"0123456789*#"}, :result=>3}, {:register=>:digits, :options=>{:retries=>1, :timeout=>5, :numDigits=>1, :validDigits=>"0123456789*#"}, :result=>2}, {:decir => 'si 2'}], plvc.call_sequence

  end
  
end
