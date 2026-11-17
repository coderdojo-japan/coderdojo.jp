module ChartsHelper
  # Chartkick の column_chart は、グラフごとにインラインの <script> で描く。
  # CSP で 'unsafe-inline' を外せるよう、同じデータと設定を div の data 属性で渡し、
  # /stats だけで読む charts.js で描く（spec/requests/inline_script_spec.rb）。
  # div の見た目（読み込み中の表示）は Chartkick のヘルパーが出すものと同じにする
  def column_chart_tag(chart)
    options = chart.options.except(:width, :height)
    height  = chart.options.fetch(:height)
    width   = chart.options.fetch(:width)

    tag.div(options.fetch(:loading, 'Loading...'),
      style: "height: #{height}; width: #{width}; text-align: center; color: #999; line-height: #{height}; font-size: 14px; " \
             "font-family: 'Lucida Grande', 'Lucida Sans Unicode', Verdana, Arial, Helvetica, sans-serif;",
      data: { chartkick_type: 'ColumnChart', chartkick_data: chart.series, chartkick_options: options })
  end
end
