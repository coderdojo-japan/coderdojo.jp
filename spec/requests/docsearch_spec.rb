require 'rails_helper'

# 検索の DocSearch は CDN から読み込むので、Twemoji と同じく版を固定し、SRI（integrity）で中身を照合する。
# CSP（config/initializers/csp.rb）もこの 1 ファイルだけを許している
RSpec.describe 'DocSearch の読み込み', type: :request do
  it '版を固定し、integrity を付けて読み込む' do
    get root_path
    scripts = Nokogiri::HTML(response.body).css('script[src*="docsearch"]')

    expect(scripts.size).to eq 1
    expect(scripts.first['src']).to match(%r{\Ahttps://cdn\.jsdelivr\.net/npm/@docsearch/js@\d+\.\d+\.\d+/dist/umd/index\.js\z})
    expect(scripts.first['integrity']).to start_with('sha384-')
    expect(scripts.first['crossorigin']).to eq 'anonymous'
  end
end
