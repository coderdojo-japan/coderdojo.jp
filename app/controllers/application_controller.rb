class ApplicationController < ActionController::Base
  #http_basic_authenticate_with name: ENV['BASIC_AUTH_NAME'],
  #                         password: ENV['BASIC_AUTH_PASSWORD'] if Rails.env.staging?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_request_variant

  # NOTE: rescue_from methods are evaluated from **bottom to up**
  if Rails.env.production?
    rescue_from Exception,                      with: :render_500
    rescue_from ActiveRecord::RecordNotFound,   with: :render_404
    rescue_from ActionController::RoutingError, with: :render_404
  end

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
