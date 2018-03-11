class HighChartsBuilder
  class << self
    def build_annual_dojos
      source = Dojo.where('created_at < ?', Time.current.beginning_of_year).group("DATE_TRUNC('year', created_at)").count
      data = annual_chart_data_from(source)

      LazyHighCharts::HighChart.new('graph') do |f|
        f.title(text: '全国の道場数の推移')
        f.xAxis(categories: data[:years])
        f.series(type: 'column', name: '増加数', yAxis: 0, data: data[:increase_nums])
        f.series(type: 'line', name: '累積合計', yAxis: 1, data: data[:cumulative_sums])
        f.yAxis [
          { title: { text: '増加数' } },
          { title: { text: '累積合計' }, opposite: true }
        ]
        f.chart(width: 600)
        f.colors(["#A0D3B5", "#505D6B"])
      end
    end

    def build_annual_event_histories
      source = EventHistory.where('evented_at < ?', Time.current.beginning_of_year).group("DATE_TRUNC('year', evented_at)").count
      data = annual_chart_data_from(source)

      LazyHighCharts::HighChart.new('graph') do |f|
        f.title(text: '開催回数の推移')
        f.xAxis(categories: data[:years])
        f.series(type: 'column', name: '開催回数', yAxis: 0, data: data[:increase_nums])
        f.series(type: 'line', name: '累積合計', yAxis: 1, data: data[:cumulative_sums])
        f.yAxis [
          { title: { text: '開催回数' } },
          { title: { text: '累積合計' }, opposite: true }
        ]
        f.chart(width: 600)
        f.colors(["#F4C34F", "#BD2561"])
      end
    end

    def build_annual_participants
      source = EventHistory.where('evented_at < ?', Time.current.beginning_of_year).group("DATE_TRUNC('year', evented_at)").sum(:participants)
      data = annual_chart_data_from(source)

      LazyHighCharts::HighChart.new('graph') do |f|
        f.title(text: '参加者数の推移')
        f.xAxis(categories: data[:years])
        f.series(type: 'column', name: '参加者数', yAxis: 0, data: data[:increase_nums])
        f.series(type: 'line', name: '累積合計', yAxis: 1, data: data[:cumulative_sums])
        f.yAxis [
          { title: { text: '参加者数' } },
          { title: { text: '累積合計' }, opposite: true }
        ]
        f.chart(width: 600)
        f.colors(["#EF685E", "#35637D"])
      end
    end

    private

    def annual_chart_data_from(source)
      sorted_list = source.each.with_object({}) {|(k, v), h| h[k.year] = v }.sort
      years = sorted_list.map(&:first)
      increase_nums = sorted_list.map(&:last)
      cumulative_sums = increase_nums.size.times.map {|i| increase_nums[0..i].inject(:+) }

      {
        years: years,
        increase_nums: increase_nums,
        cumulative_sums: cumulative_sums
      }
    end
  end
end
