class StatsController < ApplicationController
  def show
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

    @annual_dojos_chart = HighChartsBuilder.build_annual_dojos
    @annual_event_histories_chart = HighChartsBuilder.build_annual_event_histories
    @annual_participants_chart = HighChartsBuilder.build_annual_participants
  end
end
