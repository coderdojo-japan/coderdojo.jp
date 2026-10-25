require 'rails_helper'

# ダウンロード機能は、オンライン版への移行（2024年度）に伴い停止済み。
# 未使用のコードとテーブルを削除しても、案内ページとワークショップ紹介の表示が
# 変わらないことを固定する。
RSpec.describe 'Pokemons', type: :request do
  it 'GET /pokemon がこれまでどおり表示される' do
    get pokemon_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include('ポケモン素材の利用規約')
    expect(response.body).to include('オンライン版に移行しました')
  end

  it 'GET /pokemon に、名前やメールアドレスの入力欄を出さない' do
    get pokemon_path

    html = Nokogiri::HTML(response.body)
    expect(html.css('main form, .introduction form, .introduction input')).to be_empty
    expect(response.body).not_to include('保護者の名前')
    expect(response.body).not_to include('メールアドレス')
  end

  it 'GET /pokemon/workshop がこれまでどおり表示される' do
    get pokemon_workshop_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include('ポケモンワークショップの事例紹介')
  end

  it 'GET /pokemon/download は /pokemon にリダイレクトされる' do
    get '/pokemon/download'

    expect(response).to redirect_to('/pokemon')
  end
end
