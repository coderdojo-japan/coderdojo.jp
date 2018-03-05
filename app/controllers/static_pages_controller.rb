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
    # https://github.com/coderdojo-japan/coderdojo.jp/issues/190
    @sum_of_events       = EventHistory.count
    @sum_of_dojos        = DojoEventService.count('DISTINCT dojo_id')
    @sum_of_participants = EventHistory.sum(:participants)

    # 2012年1月1日〜2017年12月31日までの集計結果
    @dojos, @events, @participants = {}, {}, {}
    @range = 2012..2017
    @range.each do |year|
      @dojos[year] =
        Dojo
          .distinct
          .joins(:dojo_event_services)
          .where(created_at: Time.zone.local(@range.first).beginning_of_year..Time.zone.local(year).end_of_year)
          .count
      @events[year] =
        EventHistory.where(evented_at:
                     Time.zone.local(year).beginning_of_year..Time.zone.local(year).end_of_year).count
      @participants[year] =
        EventHistory.where(evented_at:
                     Time.zone.local(year).beginning_of_year..Time.zone.local(year).end_of_year).sum(:participants)
    end
  end

  def events
    @url                 = request.url
    @regions_and_dojos   = Dojo.eager_load(:prefecture).default_order.group_by { |dojo| dojo.prefecture.region }
    @events = Dojo.where(evented_at:
                      Time.zone.now..Time.zone.now.end_of_year)
    #@hoge = Statistics::Aggregation.new(from: Time.current.strftime('%Y'),to:Time.current.strftime('%Y')).run
  end


  def letsencrypt
    if params[:id] == ENV['LETSENCRYPT_REQUEST']
      render text: ENV['LETSENCRYPT_RESPONSE']
    else
      render text: 'Failed.'
    end
  end
end
