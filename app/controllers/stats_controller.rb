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

    # 道場タググラフ
    @dojo_tag_chart  = LazyHighCharts::HighChart.new('graph') do |f|
      number_of_tags = 10
      f.title(text: "CoderDojo タグ分布 (上位#{number_of_tags})")

      # TODO: Use 'tally' method when using Ruby 2.7.0 or higher
      # cf. https://twitter.com/yasulab/status/1154566199511941120
      tags = Dojo.active.map(&:tags).flatten.group_by(&:itself).transform_values(&:count)
        .sort_by(&:last).reverse.to_h
      f.xAxis categories: tags.keys.take(number_of_tags).reverse
      f.yAxis title: { text: '' }, showInLegend: false, opposite: true,
              tickInterval: 40, max: 200
      f.series type: 'column', name: "対応道場数", yAxis: 0, showInLegend: false,
               data: tags.values.take(number_of_tags).reverse,
               dataLabels: { enabled: true, y: 20, align: 'center' }

      f.chart width: 600, alignTicks: false
      f.colors ["#A0CEFB", "#A0CEFB"]
    end

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

