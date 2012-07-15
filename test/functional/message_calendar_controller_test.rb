require 'test_helper'

class MessageCalendarControllerTest < ActionController::TestCase
  test "should get start:datetime" do
    get :start:datetime
    assert_response :success
  end

  test "should get stop:datetime" do
    get :stop:datetime
    assert_response :success
  end

end
