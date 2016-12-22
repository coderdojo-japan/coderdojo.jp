require 'test_helper'


class UsersLoginTest < ActionDispatch::IntegrationTest
  def setup
    login = LoginPage.instance
    @login_path = "/#{login.slug + login.id}"
  end

  test "login with invalid information" do
    get @login_path
    assert_template 'login_page/index'
    post session_path, { email: "", password: "" }
    assert_redirected_to @login_path
    assert_not flash.empty?
    get @login_path
    assert flash.present?
  end

  test "login with valid information" do
    get @login_path
    post session_path, { email:    ENV['SCRIVITO_EMAIL'],
                         password: ENV["SCRIVITO_PASSWORD"] }
    assert_redirected_to "/sotechsha"
    assert_equal session[:user] , ENV['SCRIVITO_EMAIL']
    follow_redirect!
    assert_template "sotechsha_overview_page/index"
  end
end
