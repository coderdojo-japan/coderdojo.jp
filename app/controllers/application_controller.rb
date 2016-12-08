class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private
  
  def logged_in?
    session[:user].present?
  end
  helper_method :logged_in?
end
