class Previews::ErrorsController < ApplicationController
  # このコントローラー全体で、application.html.erb のレイアウトを使用します
  layout "application"

  # 404ページをプレビューするためのアクション
  def not_found
    # app/views/errors/not_found.html.erb を、
    # ステータスコード404で描画します
    render template: "errors/not_found", status: :not_found
  end

  # 422ページをプレビューするためのアクション
  def unprocessable_entity
    render template: "errors/unprocessable_entity", status: :unprocessable_entity
  end

  # 500ページをプレビューするためのアクション
  def internal_server_error
    render template: "errors/internal_server_error", status: :internal_server_error
  end
end
