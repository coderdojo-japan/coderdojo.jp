class NewsController < ApplicationController
  def index
    @title = '📰 CoderDojo ニュース'
    @desc  = 'CoderDojo に関するお知らせの一覧ページです。'
    @url   = request.url

    # データベースからニュースデータを取得（最新順）
    @news_items = News.recent

    respond_to do |format|
      format.html # デフォルトのHTMLビュー
      format.json {
        # JSON レスポンス時は variant を無視する
        # rack-user_agent gem による variant 設定が JSON レスポンスに影響しないようにする
        request.variant = nil
        render json: @news_items
      }
    end
  end
end
