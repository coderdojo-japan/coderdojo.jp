require 'rails_helper'

# Twemoji は CDN から読み込むので、版を固定し、SRI（integrity）で中身を照合する。
# @latest のままだと、配布元の中身が差し替えられた時にそのまま全ページで動いてしまう
RSpec.describe 'Twemoji の読み込み', type: :request do
  it '版を固定し、integrity を付けて読み込む' do
    get root_path
    scripts = Nokogiri::HTML(response.body).css('script[src*="twemoji"]')

    expect(scripts.size).to eq 1
    expect(scripts.first['src']).to match(%r{\Ahttps://cdn\.jsdelivr\.net/npm/@twemoji/api@\d+\.\d+\.\d+/dist/twemoji\.min\.js\z})
    expect(scripts.first['integrity']).to start_with('sha384-')
    expect(scripts.first['crossorigin']).to eq 'anonymous'
  end
end
