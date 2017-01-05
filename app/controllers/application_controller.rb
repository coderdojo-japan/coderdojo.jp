class ApplicationController < ActionController::Base
  before_action :store_location , :unless=> :login_page_access?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include SessionsHelper
  
  private

    def store_location
      session[:original_url] = request.original_url
    end

    def login_page_access?
      self.controller_name == 'login_page' || self.controller_name =='sessions'
    end

end
