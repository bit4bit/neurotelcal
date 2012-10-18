require 'test_helper'

class MonitorControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get campaigns_status" do
    get :campaigns_status
    assert_response :success
  end

  test "should get channels_status" do
    get :channels_status
    assert_response :success
  end

end
