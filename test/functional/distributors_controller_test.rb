require 'test_helper'

class DistributorsControllerTest < ActionController::TestCase
  setup do
    @distributor = distributors(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:distributors)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create distributor" do
    assert_difference('Distributor.count') do
      post :create, distributor: { description: @distributor.description, filter: @distributor.filter }
    end

    assert_redirected_to distributor_path(assigns(:distributor))
  end

  test "should show distributor" do
    get :show, id: @distributor
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @distributor
    assert_response :success
  end

  test "should update distributor" do
    put :update, id: @distributor, distributor: { description: @distributor.description, filter: @distributor.filter }
    assert_redirected_to distributor_path(assigns(:distributor))
  end

  test "should destroy distributor" do
    assert_difference('Distributor.count', -1) do
      delete :destroy, id: @distributor
    end

    assert_redirected_to distributors_path
  end
end
