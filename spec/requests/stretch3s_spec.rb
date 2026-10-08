require 'rails_helper'

RSpec.describe 'Stretch3', type: :request do
  describe 'GET /stretch3' do
    # 「使い方を見る」の画像は外部の画像ホスティングに頼らず、サイト内に置く
    it '使い方の画像をサイト内から配信する' do
      get '/stretch3'

      link = Nokogiri::HTML(response.body).at_xpath("//a[contains(., '使い方を見る')]")
      expect(link['href']).to eq('/img/stretch3_how_to_use.png')
      expect(Rails.root.join('public', 'img', 'stretch3_how_to_use.png')).to exist
    end
  end
end
