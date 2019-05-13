class ApplicationController < ActionController::Base
  http_basic_authenticate_with name: ENV['BASIC_AUTH_NAME'],
                           password: ENV['BASIC_AUTH_PASSWORD'] if Rails.env.staging?

  before_action :store_location , unless: :login_page_access?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include SessionsHelper

  before_action :set_request_variant

  private

    def store_location
      session[:original_url] = request.original_url
    end

    def login_page_access?
      %w(login_page sessions).include? self.controller_name
    end

  def set_request_variant
    request.variant = request.device_variant
  end
end
