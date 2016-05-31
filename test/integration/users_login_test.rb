require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:andrew)
  end

  test 'login with invalid information' do
    get login_path
    assert_template 'sessions/new'
    post login_path, session: {phone: '', password: ''}
    assert_not is_logged_in?
    assert_template 'sessions/new'
    assert_not flash.empty?
    get login_path
    assert flash.empty?
  end

  test 'login with valid information followed by logout' do
    get login_path
    post login_path, session: { phone: @user.phone, password: 'password' }
    assert_redirected_to root_path
    assert is_logged_in?
    follow_redirect!
    assert_select 'a[href=?]', login_path, count: 0
    assert_select 'a[href=?]', logout_path
    assert_select 'a[href=?]', user_path(@user)
    delete logout_path
    assert_not is_logged_in?
    assert_redirected_to login_url
    # Simulate a user clicking logout in a second window.
    delete logout_path
    follow_redirect!
    assert_select 'a[href=?]', login_path
    assert_select 'a[href=?]', logout_path, count: 0
    assert_select 'a[href=?]', user_path(@user), count: 0
  end

  test 'login with remembering' do
    log_in_as(@user)
    assert_not_nil cookies['remember_token']
  end

  test 'get authentication token' do
    post '/knock/auth_token', {auth: {phone: @user.phone, password: 'password'}}
    response = ActiveSupport::JSON.decode @response.body
    assert_match /.*\..*\..*/, response['jwt']
  end

  test 'no authentication on bad credentials' do
    post '/knock/auth_token', {auth: {phone: @user.phone, password: 'invalid'}}
    assert_response :missing
  end

end
