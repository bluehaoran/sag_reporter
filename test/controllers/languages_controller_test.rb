require 'test_helper'

class LanguagesControllerTest < ActionController::TestCase

  def setup
    @lang = languages(:toto)
    @user = users(:andrew)
  end
  
  test "should get index" do
    log_in_as(@user)
    get :index
    assert_response :success
  end

  test "should get new" do
    log_in_as(@user)
    get :new
    assert_response :success
  end

  test "should get edit" do
    log_in_as(@user)
    get :edit, id: @lang
    assert_response :success
  end

  test "should get show" do
    log_in_as(@user)
    get :show, id: @lang
    assert_response :success
  end

end