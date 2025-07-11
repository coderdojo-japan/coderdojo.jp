class StatsController < ApplicationController

  # GET /stats[.json]
  def show
    # 言語設定
    @lang = params[:lang] || 'ja'
    
    # 2012年1月1日〜2024年12月31日までの集計結果
    @period_start = 2012
    @period_end   = 2024
    period        = Time.zone.local(@period_start).beginning_of_year..Time.zone.local(@period_end).end_of_year
    stats         = Stat.new(period)

    # 推移グラフ
    @high_charts_globals          = HighChartsBuilder.global_options
    @annual_dojos_chart           = stats.annual_dojos_chart(@lang)
    @annual_event_histories_chart = stats.annual_event_histories_chart(@lang)
    @annual_participants_chart    = stats.annual_participants_chart(@lang)

    # 最新データ
    @sum_of_dojos        = Dojo.active_dojos_count
    @sum_of_events       = EventHistory.count
    @sum_of_participants = EventHistory.sum(:participants)
    # TODO: 静的なDojoの開催数もデータベース上で集計できるようにする
    # https://github.com/coderdojo-japan/coderdojo.jp/issues/190

    # 道場タグ分布
    @dojo_tag_chart  = LazyHighCharts::HighChart.new('graph') do |f|
      number_of_tags = 10
      title_text = @lang == 'en' ? "CoderDojo Tag Distribution (Top #{number_of_tags})" : "CoderDojo タグ分布 (上位 #{number_of_tags})"
      f.title(text: title_text)

      # Use 'tally' method when using Ruby 2.7.0 or higher
      # cf. https://twitter.com/yasulab/status/1154566199511941120
      #tags = Dojo.active.map(&:tags).flatten.group_by(&:itself).transform_values(&:count)
      tags = Dojo.active.map(&:tags).flatten.tally

      # Add tags for multiple dojos: https://github.com/coderdojo-japan/coderdojo.jp/issues/992
      Dojo.active.where('counter > 1').each do |dojo|
        dojo.tags.each {|tag| tags[tag] += (dojo.counter - 1) }
      end
      tags = tags.sort_by{|key, value| value}.reverse.to_h

      # タグ名を言語に応じて翻訳
      tag_labels = if @lang == 'en'
        tags.keys.take(number_of_tags).map { |tag| helpers.translate_dojo_tag(tag) }.reverse
      else
        tags.keys.take(number_of_tags).reverse
      end

      f.xAxis categories: tag_labels
      f.yAxis title: { text: '' }, showInLegend: false, opposite: true,
              tickInterval: 40, max: 240
      f.series type: 'column', name: @lang == 'en' ? "Number of Dojos" : "対応道場数", yAxis: 0, showInLegend: false,
               data: tags.values.take(number_of_tags).reverse,
               dataLabels: {
                 enabled: true,
                 y: 20,
                 color: 'white',
                 align: 'center',
                 style: {
                   textShadow: false,
                 }
               }

      f.chart width: 600, alignTicks: false
      f.colors ["#A0CEFB", "#A0CEFB"]
    end

    # 集計方法と集計対象
    # TODO: 'DISTINCT dojo_id' cannot track joint-registrated dojos
    #   cf. https://github.com/coderdojo-japan/coderdojo.jp/issues/682
    # TODO: 集計対象となっている道場数の推移と合わせて調整すると良さそう
    # joint_dojo_counter  = Dojo.where('counter > 1').map do |d|
    #   d.dojo_event_services.any? ? (d.counter-1) : 0 # Remove itself from counting
    # end.sum
    # @aggregated_dojos   = DojoEventService.count('DISTINCT dojo_id') + joint_dojo_counter
    #
    # MEMO: 色々不要!! 以下の *_table/whole の最新の値を出せば良いだけだった!!
    # @dojos_aggregated        = DojoEventService.count('DISTINCT dojo_id')
    # @dojos_included_inactive = stats.annual_sum_total_of_dojo_inactive_included

    # 「集計対象となっている道場数 / 非集計対象含む道場数」の推移
    @annual_dojos_table = stats.annual_sum_total_of_aggregatable_dojo
    @annual_dojos_whole = stats.annual_sum_total_of_dojo_inactive_included
    @annual_dojos_ratio = {}
    @period_range = @period_start..@period_end
    @period_range.each do |year|
      ratio = @annual_dojos_whole[year.to_s].zero? ?
        '100.0' :
        (Rational(@annual_dojos_table[year.to_s], @annual_dojos_whole[year.to_s]).to_f * 100).round(1).to_s

      @annual_dojos_ratio[year.to_s] = ratio
    end

    # 割合に応じた開催数と参加数の見込み
    @annual_events_table       = stats.annual_count_of_event_histories
    @annual_participants_table = stats.annual_sum_of_participants

    # 日本各地の道場
    @data_by_region = []
    @regions_and_dojos = Dojo.group_by_region_on_active
    @regions_and_dojos.each_with_index do |(region, dojos), index|
      # 地域名の英語化
      region_name = if @lang == 'en'
        case region
        when '北海道' then 'Hokkaido'
        when '東北' then 'Tohoku'
        when '関東' then 'Kanto'
        when '中部' then 'Chubu'
        when '近畿' then 'Kinki'
        when '中国' then 'Chugoku'
        when '四国' then 'Shikoku'
        when '九州' then 'Kyushu'
        when '沖縄' then 'Okinawa'
        else region
        end
      else
        region
      end
      
      @data_by_region << {
        code:        index+1,
        name:        "#{region_name} (#{dojos.pluck(:counter).sum})",
        color:       "dodgerblue",  # Area Color
        hoverColor:  "dodgerblue", # Another option: "deepskyblue"
        prefectures: Prefecture.where(region: region).map(&:id)
      }
    end

    @data_by_prefecture = {}
    Prefecture.order(:id).each do |p|
      prefecture_name = @lang == 'en' ? helpers.prefecture_name_in_english(p.name) : p.name
      @data_by_prefecture[prefecture_name] = Dojo.active.where(prefecture_id: p.id).sum(:counter)
    end
    @data_by_prefecture_count = @data_by_prefecture.select{|k,v| v>0}.count

    respond_to do |format|
      # No corresponding View for now.
      # Only for API: GET /dojos.json
      format.html # => app/views/stats/show.html.erb
      format.json { render json: {
          # NOTE: Add JSON data upon requests
          active_dojos: @sum_of_dojos,  # Required by other repos
          total_events: @sum_of_events,
          total_ninjas: @sum_of_participants,
          active_dojos_by_prefecture: @data_by_prefecture,
        }
      }
    end
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
