class StaticPagesController < ApplicationController
  def home
    @dojo_count        = Dojo.count
    @regions_and_dojos = Dojo.eager_load(:prefecture).default_order.group_by { |dojo| dojo.prefecture.region }
  end

  def stats
    @url                 = request.url
    @dojo_count          = Dojo.count
    @regions_and_dojos   = Dojo.eager_load(:prefecture).default_order.group_by { |dojo| dojo.prefecture.region }

    # TODO: 次の静的なDojoの開催数もデータベース上で集計できるようにする
    @sum_of_events       = EventHistory.count + # 以下は2017年11月3日時点で個別に確認した数字
      29 + # 柏の葉
      3  + # 南柏
      4  + # 柏湘南
      63   # 小平
    @sum_of_dojos        = DojoEventService.count('DISTINCT dojo_id') +
      4    # TODO: 同上。上記の道場数を静的に足しています
    @sum_of_participants = EventHistory.sum(:participants)

    # 2017年1月1日〜12月31日までの集計結果
    @2017_events       = EventHistory.where('evented_at > ?', Time.zone.local(2017).beginning_of_year).count
    @2017_participants = EventHistory.where('evented_at > ?', Time.zone.local(2017).beginning_of_year).sum(:participants)
  end

  def letsencrypt
    if params[:id] == ENV['LETSENCRYPT_REQUEST']
      render text: ENV['LETSENCRYPT_RESPONSE']
    else
      render text: 'Failed.'
    end
  end
end
