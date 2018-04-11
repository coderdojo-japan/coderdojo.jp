class StatsController < ApplicationController
  def show
    @url                 = request.url
    @dojo_count          = Dojo.count
    @regions_and_dojos   = Dojo.group_by_region

    # TODO: 次の静的なDojoの開催数もデータベース上で集計できるようにする
    # https://github.com/coderdojo-japan/coderdojo.jp/issues/190
    @sum_of_events       = EventHistory.count
    @sum_of_dojos        = DojoEventService.count('DISTINCT dojo_id')
    @sum_of_participants = EventHistory.sum(:participants)

    # 2012年1月1日〜2017年12月31日までの集計結果
    period = Time.zone.local(2012).beginning_of_year..Time.zone.local(2017).end_of_year
    stat   = Stat.new(period)
    @dojos        = stat.annual_sum_total_of_aggregatable_dojo
    @events       = stat.annual_count_of_event_histories
    @participants = stat.annual_sum_of_participants

    @high_charts_globals = HighChartsBuilder.global_options
    @annual_dojos_chart           = stat.annual_dojos_chart
    @annual_event_histories_chart = stat.annual_event_histories_chart
    @annual_participants_chart    = stat.annual_participants_chart
  end
end
