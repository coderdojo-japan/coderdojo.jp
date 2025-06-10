class ErrorsController < ApplicationController
  layout 'application' # エラー画面にも通常のアプリと同じレイアウトを適用

  def not_found
    render status: 404 # このアクションでは app/views/errors/not_found.html.erb が使用されます
  end

  def internal_server_error
    render status: 500 # このアクションでは app/views/errors/internal_server_error.html.erb が使用されます
  end

  def unprocessable_entity
    render status: 422 # このアクションでは app/views/errors/unprocessable_entity.html.erb が使用されます
  end
end
