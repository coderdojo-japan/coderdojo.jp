# /stats のグラフを Chartkick（Chart.js）で組み立てる。
# 見た目は、以前使っていた Highcharts の既定の値（書体・文字の大きさと色・棒の太さ・点の大きさ）にそろえる。
# 凡例・棒の上の数・目盛りの k 表記は app/assets/javascripts/chartkick_plugins.js で描く
class ChartkickBuilder
  # ビューでは column_chart chart.series, **chart.options と使う
  Chart = Struct.new(:series, :options)

  WIDTH       = 600  # 大きな画面での最大の幅。ビューの枠で決める
  FONT_FAMILY = '"Lucida Grande", "Lucida Sans Unicode", Arial, Helvetica, sans-serif'.freeze
  LABEL_COLOR = '#666666'.freeze  # 目盛りと軸の見出し
  TEXT_COLOR  = '#333333'.freeze  # タイトルと凡例
  GRID_COLOR  = '#e6e6e6'.freeze
  AXIS_COLOR  = '#ccd6eb'.freeze

  class << self
    def build_annual_dojos(source, lang = 'ja')
      data = annual_dojos_chart_data_from(source)
      en   = lang == 'en'
      combo_chart(
        title:  en ? 'Number of Dojos' : '道場数の推移',
        years:  data[:years],
        column: { name: en ? 'New' : '開設数',     data: data[:increase_nums],   color: '#A0D3B5', max: 75,  step: 15 },
        line:   { name: en ? 'Total' : '累積合計', data: data[:cumulative_sums], color: '#505D6B', max: 250, step: 50 }
      )
    end

    def build_annual_event_histories(source, lang = 'ja')
      data = annual_chart_data_from(source)
      en   = lang == 'en'
      combo_chart(
        title:  en ? 'Number of Events' : '開催回数の推移',
        years:  data[:years],
        column: { name: en ? 'Events' : '開催回数', data: data[:increase_nums],   color: '#F4C34F', max: 2000,  step: 500 },
        line:   { name: en ? 'Total' : '累積合計',  data: data[:cumulative_sums], color: '#BD2561', max: 14000, step: 3500 }
      )
    end

    def build_annual_participants(source, lang = 'ja')
      data = annual_chart_data_from(source)
      en   = lang == 'en'
      combo_chart(
        title:  en ? 'Number of Participants' : '参加者数の推移',
        years:  data[:years],
        column: { name: en ? 'Participants' : '参加者数', data: data[:increase_nums],   color: '#EF685E', max: 12500, step: 2500 },
        line:   { name: en ? 'Total' : '累積合計',        data: data[:cumulative_sums], color: '#35637D', max: 75000, step: 15000 }
      )
    end

    # 道場のタグの分布。棒の中に数を白い字で書き、目盛りは右に置く
    def build_dojo_tags(labels, values, title:, name:)
      series = [{ name: name, data: labels.zip(values), color: '#A0CEFB',
                  dataset: column_dataset('#A0CEFB').merge(yAxisID: 'y') }]
      options = base_options(title, height: 400).deep_merge(
        library: {
          plugins: { barLabels: { enabled: true } },
          scales: { y: value_axis(nil, max: 240, step: 40).merge(position: 'right') }
        }
      )
      Chart.new(series, options)
    end

    private

    # 棒（その年の数）と折れ線（累積合計）を、左右 2 つの目盛りで重ねる
    def combo_chart(title:, years:, column:, line:)
      series = [
        { name: column[:name], data: years.zip(column[:data]), color: column[:color],
          dataset: column_dataset(column[:color]).merge(yAxisID: 'y', order: 2) },
        { name: line[:name], data: years.zip(line[:data]), color: line[:color],
          dataset: line_dataset(line[:color]).merge(yAxisID: 'y1', order: 1) }
      ]
      # 凡例は canvas の外に HTML で描くので、その分を引いた高さ
      options = base_options(title, height: 355).deep_merge(
        library: {
          plugins: { htmlLegend: { enabled: true } },
          scales: {
            y:  value_axis(column[:name], max: column[:max], step: column[:step]),
            y1: value_axis(line[:name],   max: line[:max],   step: line[:step]).merge(position: 'right')
          }
        }
      )
      Chart.new(series, options)
    end

    # 棒の太さは Highcharts の既定（1 本分の幅の 48%）: 0.6 × 0.8。
    # マウスを重ねた棒は 10% 明るくする（Highcharts の既定）
    def column_dataset(color)
      { backgroundColor: color, hoverBackgroundColor: brighten(color, 0.1), borderWidth: 0,
        categoryPercentage: 0.6, barPercentage: 0.8 }
    end

    # 線の太さ 2px・点の半径 4px（縁取りなし）は Highcharts の既定。
    # マウスを重ねた点は半径を 2 増やし、周りに半径 10・透明度 0.25 の輪を付ける（Highcharts の既定）
    def line_dataset(color)
      { type: 'line', borderWidth: 2, tension: 0, pointRadius: 4, pointBorderWidth: 0,
        pointHoverRadius: 6, pointHoverBorderWidth: 8, pointHoverBorderColor: rgba(color, 0.25),
        pointBackgroundColor: color, pointHoverBackgroundColor: color, backgroundColor: color }
    end

    # 目盛りは 0 から max まで step ごとに全部出す（Chartkick の既定は本数を減らす）。
    # 刻みが 1000 以上の目盛りは「3.5k」のように書く（Highcharts と同じ。chartkick_plugins.js）
    def value_axis(title, max:, step:)
      axis = { min: 0, max: max,
               ticks: { stepSize: step, maxTicksLimit: max / step + 1, color: LABEL_COLOR, font: font(11),
                        kFormat: step >= 1000 },
               grid: { color: GRID_COLOR, drawTicks: false },
               border: { display: false } }
      axis[:title] = { display: true, text: title, color: LABEL_COLOR, font: font(11) } if title
      axis
    end

    def base_options(title, height:)
      {
        # 画面の幅に合わせて縮める。最大の幅（WIDTH）はビューの枠で決める
        width:  '100%',
        height: "#{height}px",
        library: {
          # 描く範囲（棒と線の領域）を Highcharts と同じ大きさにする外側の余白
          layout: { padding: { left: 15, right: 15, bottom: 10 } },
          plugins: {
            title:  { display: true, text: title, color: TEXT_COLOR, font: font(18),
                      padding: { top: 10, bottom: 15 } },
            legend: { display: false },
            # 吹き出しは chartkick_plugins.js で HTML で描く
            htmlTooltip: { enabled: true }
          },
          # マウスに一番近い点を示す（Highcharts の既定）
          interaction: { mode: 'nearest', intersect: false },
          scales: {
            x: { ticks: { color: LABEL_COLOR, font: font(11), minRotation: 45, maxRotation: 45 },
                 grid: { display: false },
                 border: { color: AXIS_COLOR } }
          }
        }
      }
    end

    # Highcharts の Color#brighten と同じく、RGB のそれぞれに 255 × amount（小数は切り捨て）を足す
    def brighten(hex, amount)
      r, g, b = hex.delete_prefix('#').scan(/../).map { (it.hex + (255 * amount).to_i).clamp(0, 255) }
      format('#%02X%02X%02X', r, g, b)
    end

    def rgba(hex, alpha)
      r, g, b = hex.delete_prefix('#').scan(/../).map(&:hex)
      "rgba(#{r}, #{g}, #{b}, #{alpha})"
    end

    def font(size, weight = 'normal')
      { family: FONT_FAMILY, size: size, weight: weight }
    end

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
