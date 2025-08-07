class HighChartsBuilder
  HIGH_CHARTS_WIDTH = 600

  class << self
    def global_options
      LazyHighCharts::HighChartGlobals.new do |f|
        f.lang(thousandsSep: ',')
      end
    end

    def build_annual_dojos(source, lang = 'ja')
      data = annual_chart_data_from(source)
      title_text = lang == 'en' ? 'Number of Dojos' : '道場数の推移'

      LazyHighCharts::HighChart.new('graph') do |f|
        f.title(text: title_text)
        f.xAxis(categories: data[:years])
        f.series(type: 'column', name: lang == 'en' ? 'New' : '増加数', yAxis: 0, data: data[:increase_nums])
        f.series(type: 'line', name: lang == 'en' ? 'Total' : '累積合計', yAxis: 1, data: data[:cumulative_sums])
        f.yAxis [
          { title: { text: lang == 'en' ? 'New' : '増加数' },   tickInterval: 15, max: 75 },
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
      
      # 増加数を計算（前年との差分）
      increase_nums = counts.each_with_index.map do |count, i|
        i == 0 ? count : count - counts[i - 1]
      end
      
      # annual_dojos_with_historical_dataからの値は既にその時点での総数
      # （累積値として扱う）
      cumulative_sums = counts

      {
        years: years,
        increase_nums: increase_nums,
        cumulative_sums: cumulative_sums
      }
    end
  end
end
