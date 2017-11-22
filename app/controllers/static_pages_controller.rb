class StaticPagesController < ApplicationController
  def home
    @dojo_count        = Dojo.count
    @regions_and_dojos = Dojo.includes(:prefecture).default_order.group_by { |dojo| dojo.prefecture.region }
  end

  def stats
    @dojo_count          = Dojo.count
    @regions_and_dojos   = Dojo.includes(:prefecture).default_order.group_by { |dojo| dojo.prefecture.region }
    @sum_of_participants = EventHistory.sum(:participants)

    # TODO: 次の静的なDojoの開催数もデータベース上で集計できるようにする
    @sum_of_events       = EventHistory.count + # 以下は2017年11月3日時点で個別に確認した数字
      29 + # 柏の葉
      3  + # 南柏
      4  + # 柏湘南
      63   # 小平
    @sum_of_dojos        =  69 + # TODO: 計測対象の道場数を調べるクエリをあとで尋ねる
      4 # TODO: 同上。上記の同上数を足している
  end

  def letsencrypt
    if params[:id] == ENV['LETSENCRYPT_REQUEST']
      render text: ENV['LETSENCRYPT_RESPONSE']
    else
      render text: 'Failed.'
    end
  end
end
