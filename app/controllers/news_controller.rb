class NewsController < ApplicationController
  def index
    @title = '☯️ CoderDojo ニュース ✉️'
    @desc  = 'CoderDojo に関するお知らせの一覧ページです。'
    @url   = request.url

    # データベースからニュースデータを取得（最新順）
    @news_items = News.recent
  end
end
