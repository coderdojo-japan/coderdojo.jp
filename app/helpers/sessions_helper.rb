module SessionsHelper
  def logged_in?
    session[:user].present?
  end
end
