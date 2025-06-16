class ErrorsController < ApplicationController
  before_action :set_error_message

  def show
    render :show, status: @status_code
  end

  private

    def set_error_message
      @status_code = params[:status_code].to_i

      case @status_code
      when 404
        @title = "ページが見つかりませんでした... 🥺💦"
        @desc  = "ページが削除された可能性があります 🤔💭"
      when 422
        @title = "リクエストが処理できませんでした… 😢"
        @desc  = "入力内容に誤りがあるか、リクエストが正しく送信されなかった可能性があります。"
      when 500
        @title = "予期しないエラーが発生しました 😵‍💫"
        @desc  = "申し訳ありません。サーバーで問題が発生しています。"
      else
        @title = "予期せぬエラーが発生しました…😵"
        @desc  = "しばらく経ってから再度お試しください。"
      end
    end
end
