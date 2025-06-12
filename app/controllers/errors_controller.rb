class ErrorsController < ApplicationController
  layout 'application'

  def not_found
    # このアクションでは app/views/errors/not_found.html.erb が使用されます
    render status: 404
  end

  def internal_server_error
    # このアクションでは app/views/errors/internal_server_error.html.erb が使用されます
    render status: 500
  end

  def unprocessable_entity
    # このアクションでは app/views/errors/unprocessable_entity.html.erb が使用されます
    render status: 422
  end
end
