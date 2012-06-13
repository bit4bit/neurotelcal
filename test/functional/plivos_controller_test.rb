require 'test_helper'

class PlivosControllerTest < ActionController::TestCase
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
end
