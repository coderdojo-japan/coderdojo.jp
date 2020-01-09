class StatsController < ApplicationController
  def show
    @url                 = request.url

    # 2012年1月1日〜2019年12月31日までの集計結果
    period        = Time.zone.local(2012).beginning_of_year..Time.zone.local(2019).end_of_year
    stats         = Stat.new(period)

    # 推移グラフ
    @high_charts_globals          = HighChartsBuilder.global_options
    @annual_dojos_chart           = stats.annual_dojos_chart
    @annual_event_histories_chart = stats.annual_event_histories_chart
    @annual_participants_chart    = stats.annual_participants_chart

    # 最新データ
    @sum_of_dojos        = Dojo.active_dojos_count
    @sum_of_events       = EventHistory.count
    @sum_of_participants = EventHistory.sum(:participants)
    # TODO: 静的なDojoの開催数もデータベース上で集計できるようにする
    # https://github.com/coderdojo-japan/coderdojo.jp/issues/190

    # 集計方法と集計対象
    @aggregated_dojos   = DojoEventService.count('DISTINCT dojo_id')
    @annual_dojos_table = stats.annual_sum_total_of_aggregatable_dojo

    # 日本各地の道場
    @regions_and_dojos = Dojo.group_by_region_on_active
  end
end

    # NOTE: テーブル表示したいときは次のように書く
    # @annual_dojos_table        = stats.annual_sum_total_of_aggregatable_dojo
    # @annual_events_table       = stats.annual_count_of_event_histories
    # @annual_participants_table = stats.annual_sum_of_participants
    #   %tr
    #     %td 開催数
    #     - @events.each_value do |num|
    #       %td= num
    #     /%td= @events.values.sum
    #   %tr
    #     %td 参加数
    #     - @participants.each_value do |num|
    #       %td= num
    #     /%td= @participants.values.sum

