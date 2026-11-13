require 'rails_helper'

# CSP を強制する時、script-src に 'unsafe-inline' を残すと XSS を止められない。
# そこでビューにインラインの JS（src の無い <script>・onclick= などの属性）を書かず、
# app/assets/javascripts のファイルに置く。まだ残っているファイルは ALLOWED に並べ、直したら外す
RSpec.describe 'ビューのインラインの JS', type: :request do
  def allowed
    %w(
      app/views/dojos/index.html.erb
      app/views/home/show.html.erb
      app/views/shared/_dojos.html+smartphone.erb
      app/views/shared/_dojos_stats.html.erb
      app/views/shared/_partners.html.erb
      app/views/shared/_social_buttons_raw.html.erb
      app/views/stats/show.html.erb
    )
  end

  def views
    Dir.glob(Rails.root.join('app/views/**/*.erb')).map { it.delete_prefix("#{Rails.root}/") }.sort
  end

  def inline_js?(source)
    body = source.gsub(/<!--.*?-->/m, '')
    body.match?(/<script(?![^>]*\bsrc=)[^>]*>/) ||
      body.match?(/[\s{(,]:?on[a-z]+(\s*=\s*["']|:\s*['"])/) ||
      body.include?('javascript_tag')
  end

  it '許可した一覧の外のビューには、インラインの JS が無い' do
    offenders = views.reject { allowed.include?(it) }.select { inline_js?(File.read(it)) }

    expect(offenders).to be_empty, "インラインの JS が残っている: #{offenders.join(', ')}"
  end

  it '許可した一覧のファイルは、まだインラインの JS を含んでいる（直したら一覧から外す）' do
    stale = allowed.reject { File.exist?(it) && inline_js?(File.read(it)) }

    expect(stale).to be_empty, "一覧から外す: #{stale.join(', ')}"
  end

  # ソースを照らすだけでは、パーシャルやヘルパーが出す JS を見落とすので、描画した HTML も照らす
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
