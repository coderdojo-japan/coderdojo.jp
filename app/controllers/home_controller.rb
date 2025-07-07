class HomeController < ApplicationController
  def show
    @dojo_count = Dojo.active_dojos_count
    @regions_and_dojos = Dojo.group_by_region_on_active
    @prefectures_and_dojos = Dojo.group_by_prefecture_on_active
    @news_items = News.all.order(published_at: :desc).limit(7)
  end
end
