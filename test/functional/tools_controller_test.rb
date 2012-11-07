require 'test_helper'

class ToolsControllerTest < ActionController::TestCase
  # test "the truth" do
  #   assert true
  # end
  
  def setup
    @call = Call.new({:client_id => 1})
    assert @call.save
    @plivocall = PlivoCall.new({:call_id => @call.id})
    assert @plivocall.save
  end
  
  test "should get new archive" do
    get :new_archive
    assert_response :success
    assert_not_nil assigns(:archive)
  end
  
  test "should create archive" do
    assert_difference('Archive.count') do
      post :create_archive, :archive => { :from_at => Time.now(), :to_at => 1.day.from_now }
    end
    assert_redirected_to index_archive_tools_path(assigns(:archives))
  end
  
  test "should not create archive without calls on date" do
    assert_no_difference('Archive.count') do
      post :create_archive, :archive => { :from_at => 1.year.from_now, :to_at => 2.year.from_now }
    end
  end
  
  test "should not create archive without calls" do
    Call.delete_all
    PlivoCall.delete_all
    assert_no_difference('Archive.count') do
      post :create_archive, :archive => { :from_at => Time.now(), :to_at => 1.day.from_now }
    end
  end
  
  test "should delete archive" do
    a = Archive.new({:from_at => Time.now(), :to_at => Time.now()})
    a.save(:validate => false)
    
    assert_difference('Archive.count', -1) do
    end
  end
  
  test "should restore from xml" do
  end
  
  test "should delete calls if have backup xml" do
  end
  
end
