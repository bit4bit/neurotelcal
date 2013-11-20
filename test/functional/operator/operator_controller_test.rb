require 'test_helper'

class Operator::OperatorControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get cdr" do
    get :cdr
    assert_response :success
  end

  test "should get channels_status" do
    get :channels_status
    assert_response :success
  end

  test "should get campaigns_status" do
    get :campaigns_status
    assert_response :success
  end

end
