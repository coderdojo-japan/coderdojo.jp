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

    # 個人情報（メールアドレス・保護者や利用者の名前）は集めない。
    # 道場は活動中の一覧から選ぶ（スマホでも文字を打たずに選べる）
    it '個人情報の入力欄を出さず、活動中の道場を都道府県ごとに選ばせる' do
      active   = create(:dojo, name: '活動中の道場')
      inactive = create(:dojo, :inactive, name: '活動を終えた道場')

      get '/stretch3'

      html = Nokogiri::HTML(response.body)
      expect(html.css('input[name="stretch3[email]"]')).to be_empty
      expect(html.css('input[name="stretch3[parent_name]"]')).to be_empty
      expect(html.css('input[name="stretch3[participant_name]"]')).to be_empty

      select = html.at_css('select[name="stretch3[dojo_id]"]')
      expect(select['required']).to be_present
      expect(select.at_css(%(optgroup[label="#{active.prefecture.name}"] option[value="#{active.id}"]))).to be_present
      expect(select.at_css(%(option[value="#{inactive.id}"]))).to be_nil
    end
  end

  describe 'POST /stretch3' do
    let(:dojo) { create(:dojo) }

    it '選んだ道場だけを記録し、Stretch3 へ移る' do
      expect {
        post '/stretch3', params: { stretch3: { dojo_id: dojo.id, term_of_use: '1' } }
      }.to change(Stretch3, :count).by(1)

      expect(response).to redirect_to('https://stretch3.github.io')
      expect(Stretch3.last.dojo).to eq(dojo)
    end

    # 古いフォームや直接の送信で余計な項目が届いても、道場だけを記録する
    it '道場のほかには何も保存する列を持たない' do
      post '/stretch3', params: { stretch3: { dojo_id: dojo.id, email: 'parent@example.com', parent_name: '保護者', participant_name: '参加者' } }

      expect(Stretch3.last.dojo).to eq(dojo)
      expect(Stretch3.column_names).to contain_exactly('id', 'dojo_id', 'created_at', 'updated_at')
    end

    it '道場を選んでいなければ記録せず、フォームに戻る' do
      expect {
        post '/stretch3', params: { stretch3: { dojo_id: '' } }
      }.not_to change(Stretch3, :count)

      expect(response.body).to include('stretch3[dojo_id]')
    end
  end
end
