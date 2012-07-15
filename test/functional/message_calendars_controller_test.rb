require 'test_helper'

class MessageCalendarsControllerTest < ActionController::TestCase
  setup do
    @message_calendar = message_calendars(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:message_calendars)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create message_calendar" do
    assert_difference('MessageCalendar.count') do
      post :create, message_calendar: { start: @message_calendar.start, stop: @message_calendar.stop }
    end

    assert_redirected_to message_calendar_path(assigns(:message_calendar))
  end

  test "should show message_calendar" do
    get :show, id: @message_calendar
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @message_calendar
    assert_response :success
  end

  test "should update message_calendar" do
    put :update, id: @message_calendar, message_calendar: { start: @message_calendar.start, stop: @message_calendar.stop }
    assert_redirected_to message_calendar_path(assigns(:message_calendar))
  end

  test "should destroy message_calendar" do
    assert_difference('MessageCalendar.count', -1) do
      delete :destroy, id: @message_calendar
    end

    assert_redirected_to message_calendars_path
  end
end
