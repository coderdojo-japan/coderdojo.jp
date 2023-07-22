class ApplicationController < ActionController::Base
  #http_basic_authenticate_with name: ENV['BASIC_AUTH_NAME'],
  #                         password: ENV['BASIC_AUTH_PASSWORD'] if Rails.env.staging?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_request_variant

  private

  def set_request_variant
    request.variant = request.device_variant
  end

  def render_403(e)
    render template: 'errors/403', status: 403,
                                   layout: 'application',
                             content_type: 'text/html'
  end

  def render_404(e)
    render template: 'errors/404', status: 404,
                                   layout: 'application',
                             content_type: 'text/html'
  end

  def render_500(e)
    render template: 'errors/500', status: 500,
                                   layout: 'application',
                             content_type: 'text/html'
  end
end
