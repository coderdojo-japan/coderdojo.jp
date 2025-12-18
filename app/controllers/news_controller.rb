class NewsController < ApplicationController
  def index
    @title = 'CoderDojo ニュース'
    @desc  = 'CoderDojo に関する最新のニュースや<br class="ignore-pc">お知らせをまとめたページです。'
    @url   = request.url
    
    # データベースからニュースデータを取得（最新順）
    @news_items = News.recent
  end
end