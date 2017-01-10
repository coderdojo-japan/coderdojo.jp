require 'test_helper'
include Scrivito::ControllerHelper

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
    assert_redirected_to scrivito_path(Obj.root)
    assert_equal session[:user] , ENV['SCRIVITO_EMAIL']
    follow_redirect!
    assert_template "plain_page/index"
  end

  test "successful login followed by logout with friendly fowordings" do
    test_url = "/kata"
    get test_url
    get @login_path
    post session_path, { email:    ENV['SCRIVITO_EMAIL'],
                         password: ENV["SCRIVITO_PASSWORD"] }
    assert_redirected_to test_url
    follow_redirect!
    # assert_template "blog_post_page/index.html"
    assert_equal test_url, path

    get "/logout"
    assert_redirected_to test_url
    follow_redirect!
    assert_equal test_url, path
  end
end
