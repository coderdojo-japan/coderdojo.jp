class HighChartsBuilder
  HIGH_CHARTS_WIDTH = 600

  class << self
    def global_options
      LazyHighCharts::HighChartGlobals.new do |f|
        f.lang(thousandsSep: ',')
      end
    end

    def build_annual_dojos(source, lang = 'ja')
      data = annual_dojos_chart_data_from(source)
      title_text = lang == 'en' ? 'Number of Dojos' : '道場数の推移'

      LazyHighCharts::HighChart.new('graph') do |f|
        f.title(text: title_text)
        f.xAxis(categories: data[:years])
        f.series(type: 'column', name: lang == 'en' ? 'New Dojos' : '開設数', yAxis: 0, data: data[:increase_nums])
        f.series(type: 'line', name: lang == 'en' ? 'Total' : '累積合計', yAxis: 1, data: data[:cumulative_sums])
        f.yAxis [
          { title: { text: lang == 'en' ? 'New Dojos' : '開設数' },   tickInterval: 15, max: 75 },
          { title: { text: lang == 'en' ? 'Total' : '累積合計' }, tickInterval: 50, max: 250, opposite: true }
        ]
        f.chart(width: HIGH_CHARTS_WIDTH, alignTicks: false)
        f.colors(["#A0D3B5", "#505D6B"])
      end
    end

    def build_annual_event_histories(source, lang = 'ja')
      data = annual_chart_data_from(source)
      title_text = lang == 'en' ? 'Number of Events' : '開催回数の推移'

      LazyHighCharts::HighChart.new('graph') do |f|
        f.title(text: title_text)
        f.xAxis(categories: data[:years])
        f.series(type: 'column', name: lang == 'en' ? 'Events' : '開催回数', yAxis: 0, data: data[:increase_nums])
        f.series(type: 'line',   name: lang == 'en' ? 'Total' : '累積合計', yAxis: 1, data: data[:cumulative_sums])
        f.yAxis [
          { title: { text: lang == 'en' ? 'Events' : '開催回数' }, tickInterval:  500, max: 2000 },
          { title: { text: lang == 'en' ? 'Total' : '累積合計' }, tickInterval: 3000, max: 12000, opposite: true }
        ]
        f.chart(width: HIGH_CHARTS_WIDTH, alignTicks: false)
        f.colors(["#F4C34F", "#BD2561"])
      end
    end

    def build_annual_participants(source, lang = 'ja')
      data = annual_chart_data_from(source)
      title_text = lang == 'en' ? 'Number of Participants' : '参加者数の推移'

      LazyHighCharts::HighChart.new('graph') do |f|
        f.title(text: title_text)
        f.xAxis(categories: data[:years])
        f.series(type: 'column', name: lang == 'en' ? 'Participants' : '参加者数', yAxis: 0, data: data[:increase_nums])
        f.series(type: 'line',   name: lang == 'en' ? 'Total' : '累積合計', yAxis: 1, data: data[:cumulative_sums])
        f.yAxis [
          { title: { text: lang == 'en' ? 'Participants' : '参加者数' }, tickInterval: 2500,  max: 12500 },
          { title: { text: lang == 'en' ? 'Total' : '累積合計' }, tickInterval: 14000, max: 64000, opposite: true }
        ]
        f.chart(width: HIGH_CHARTS_WIDTH, alignTicks: false)
        f.colors(["#EF685E", "#35637D"])
      end
    end

    private

    def annual_chart_data_from(source)
      # sourceがハッシュの場合は配列に変換
      source_array = source.is_a?(Hash) ? source.to_a : source
      
      years           = source_array.map(&:first)
      counts          = source_array.map(&:last)
      
      # 年間の値として扱う（イベント回数や参加者数用）
      increase_nums = counts
      
      # 累積合計を計算
      cumulative_sums = counts.size.times.map {|i| counts[0..i].sum }

      {
        years: years,
        increase_nums: increase_nums,
        cumulative_sums: cumulative_sums
      }
    end
    
    # 道場数の推移用の特別なデータ処理
    # 新規開設数と累積数を表示
    def annual_dojos_chart_data_from(source)
      # sourceが新しい形式（active_dojosとnew_dojosを含む）の場合
      if source.is_a?(Hash) && source.key?(:active_dojos) && source.key?(:new_dojos)
        active_array = source[:active_dojos].to_a
        new_array = source[:new_dojos].to_a
        
        years = active_array.map(&:first)
        cumulative_sums = active_array.map(&:last)
        increase_nums = new_array.map(&:last)  # 新規開設数を使用
      else
        # 後方互換性のため、古い形式もサポート
        source_array = source.is_a?(Hash) ? source.to_a : source
        
        years = source_array.map(&:first)
        counts = source_array.map(&:last)
        
        # 増減数を計算（前年との差分）- 後方互換性のため
        increase_nums = counts.each_with_index.map do |count, i|
          i == 0 ? count : count - counts[i - 1]
        end
        
        cumulative_sums = counts
      end

      {
        years: years,
        increase_nums: increase_nums,
        cumulative_sums: cumulative_sums
      }
    end
  end
end
