require 'rails_helper'

# CSP を強制する時、script-src に 'unsafe-inline' を残すと XSS を止められない。
# そこでビューにインラインの JS（src の無い <script>・onclick= などの属性）を書かず、
# app/assets/javascripts のファイルに置く
RSpec.describe 'ビューのインラインの JS', type: :request do
  def views
    Dir.glob(Rails.root.join('app/views/**/*.erb')).map { it.delete_prefix("#{Rails.root}/") }.sort
  end

  def inline_js?(source)
    body = source.gsub(/<!--.*?-->/m, '')
    body.match?(/<script(?![^>]*\bsrc=)[^>]*>/) ||
      body.match?(/[\s{(,]:?on[a-z]+(\s*=\s*["']|:\s*['"])/) ||
      body.include?('javascript_tag')
  end

  it 'ビューには、インラインの JS が無い' do
    offenders = views.select { inline_js?(File.read(it)) }

    expect(offenders).to be_empty, "インラインの JS が残っている: #{offenders.join(', ')}"
  end

  # ソースを照らすだけでは、パーシャルやヘルパーが出す JS を見落とすので、描画した HTML も照らす
  %i(root_path dojos_path stats_path).each do |path|
    it "#{path} の描画した HTML に、インラインの JS が無い" do
      get send(path)
      doc = Nokogiri::HTML(response.body)
      # Chartkick のヘルパー（column_chart）はグラフごとにインラインの script を出す。データの渡し方を変える次の PR で外す
      scripts = doc.css('script:not([src])').reject { path == :stats_path && it.text.include?('new Chartkick') }

      expect(scripts.map { it.text.strip[0, 40] }).to be_empty
      expect(doc.xpath('//@*[starts-with(name(), "on")]').map(&:name)).to be_empty
    end
  end

  it 'レイアウトとヘッダーは、描画した HTML にインラインの JS を出さない' do
    get docs_path
    doc = Nokogiri::HTML(response.body)

    expect(doc.css('script:not([src])').map { it.text.strip[0, 40] }).to be_empty
    expect(doc.xpath('//@*[starts-with(name(), "on")]').map(&:name)).to be_empty
    expect(doc.at_css('#searchbox').keys).to include('data-algolia-app-id', 'data-algolia-api-key')
  end

  it '検出する書き方を見分ける' do
    expect(inline_js?('<script>alert(1)</script>')).to be true
    expect(inline_js?('<script type="text/javascript">x()</script>')).to be true
    expect(inline_js?(%(<%= check_box_tag :s, 'x', false, onclick: 'f()' %>))).to be true
    expect(inline_js?(%(<button onclick="f()">))).to be true
    expect(inline_js?('<%= javascript_tag do %>x<% end %>')).to be true

    expect(inline_js?('<script src="/js/a.js"></script>')).to be false
    expect(inline_js?("<!--\n<script>x()</script>\n-->")).to be false
    expect(inline_js?('<div data-online="1" class="phone">')).to be false
  end
end
