require 'rails_helper'

# 道場数・6 個目以降のタグ・パートナーの説明の tooltip は、Bootstrap 3 の JS を使わず、
# data-tooltip 属性の文を CSS（custom.scss の [data-tooltip]）で要素の下に出す
RSpec.describe 'tooltip', type: :request do
  let(:iphone) { 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1' }

  before { create(:dojo, counter: 3, tags: %w(Scratch Python Ruby JavaScript micro:bit Minecraft Unity)) }

  def tooltips(headers = {})
    get root_path, headers: headers
    Nokogiri::HTML(response.body).css('[data-tooltip]').to_h { [it['data-tooltip'], it] }
  end

  it 'Bootstrap 3 の tooltip の属性を出さない' do
    get root_path
    expect(response.body).not_to include('data-toggle="tooltip"')
  end

  it '道場数と、6 個目以降のタグを出す' do
    found = tooltips

    expect(found.keys).to include('道場数', 'Minecraft, Unity')
    expect(found['Minecraft, Unity'].text).to eq '...'
  end

  it 'スマホ版でも道場数を出す' do
    expect(tooltips('User-Agent' => iphone).keys).to include('道場数')
  end

  it 'パートナーの説明は、画像のリンクに付ける（img には ::after が付かない）' do
    link = tooltips['Webサイトの運営および開発支援']

    expect(link.name).to eq 'a'
    expect(link.at_css('img')['alt']).to eq 'YassLab 株式会社'
  end
end
