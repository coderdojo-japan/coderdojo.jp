class HighChartsBuilder
  class << self
    def global_options
      LazyHighCharts::HighChartGlobals.new do |f|
        f.lang(thousandsSep: ',')
      end
    end

    def build_annual_dojos(source)
      data = annual_chart_data_from(source)

      LazyHighCharts::HighChart.new('graph') do |f|
        f.title(text: '道場数の推移')
        f.xAxis(categories: data[:years])
        f.series(type: 'column', name: '増加数', yAxis: 0, data: data[:increase_nums])
        f.series(type: 'line', name: '累積合計', yAxis: 1, data: data[:cumulative_sums])
        f.yAxis [
          { title: { text: '増加数' },   tickInterval: 15, max: 75 },
          { title: { text: '累積合計' }, tickInterval: 50, max: 250, opposite: true }
        ]
        f.chart(width: 600, alignTicks: false)
        f.colors(["#A0D3B5", "#505D6B"])
      end
    end

    def build_annual_event_histories(source)
      data = annual_chart_data_from(source)

      LazyHighCharts::HighChart.new('graph') do |f|
        f.title(text: '開催回数の推移')
        f.xAxis(categories: data[:years])
        f.series(type: 'column', name: '開催回数', yAxis: 0, data: data[:increase_nums])
        f.series(type: 'line',   name: '累積合計', yAxis: 1, data: data[:cumulative_sums])
        f.yAxis [
          { title: { text: '開催回数' }, tickInterval:  500, max: 2000 },
          { title: { text: '累積合計' }, tickInterval: 2500, max: 10000, opposite: true }
        ]
        f.chart(width: 600, alignTicks: false)
        f.colors(["#F4C34F", "#BD2561"])
      end
    end

    def build_annual_participants(source)
      data = annual_chart_data_from(source)

      LazyHighCharts::HighChart.new('graph') do |f|
        f.title(text: '参加者数の推移')
        f.xAxis(categories: data[:years])
        f.series(type: 'column', name: '参加者数', yAxis: 0, data: data[:increase_nums])
        f.series(type: 'line',   name: '累積合計', yAxis: 1, data: data[:cumulative_sums])
        f.yAxis [
          { title: { text: '参加者数' }, tickInterval: 2500, max: 12500 },
          { title: { text: '累積合計' }, tickInterval: 12000, max: 60000, opposite: true }
        ]
        f.chart(width: 600, alignTicks: false)
        f.colors(["#EF685E", "#35637D"])
      end
    end

    private

    def annual_chart_data_from(source)
      years           = source.map(&:first)
      increase_nums   = source.map(&:last)
      cumulative_sums = increase_nums.size.times.map {|i| increase_nums[0..i].sum }

      {
        years: years,
        increase_nums: increase_nums,
        cumulative_sums: cumulative_sums
      }
    end
  end
end
