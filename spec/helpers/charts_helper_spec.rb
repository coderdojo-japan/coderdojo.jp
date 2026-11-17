require 'rails_helper'

RSpec.describe ChartsHelper, type: :helper do
  # Chartkick のヘルパーの代わりに使うので、グラフに渡すデータと設定が同じであることを確かめる
  it 'column_chart_tag は、Chartkick の column_chart と同じデータと設定を渡す' do
    chart = ChartkickBuilder.build_dojo_tags(%w[Scratch <b>], [10, 3], title: 'タグ', name: '道場数')

    div = Nokogiri::HTML.fragment(helper.column_chart_tag(chart)).at_css('div')
    script = helper.column_chart(chart.series, **chart.options)
    data, options = script.match(/new Chartkick\["ColumnChart"\]\("chart-\d+", (.*), (\{.*\})\);/).captures

    expect(div['data-chartkick-type']).to eq('ColumnChart')
    expect(JSON.parse(div['data-chartkick-data'])).to eq(JSON.parse(data))
    expect(JSON.parse(div['data-chartkick-options'])).to eq(JSON.parse(options))
    expect(div['style']).to eq(Nokogiri::HTML.fragment(script).at_css('div')['style'])
  end
end
