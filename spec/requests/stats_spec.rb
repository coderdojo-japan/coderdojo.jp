require 'rails_helper'

RSpec.describe "Stats", type: :request do
  describe "GET /stats" do
    it "日本語版の統計ページが表示される" do
      get "/stats"
      expect(response).to have_http_status(200)
      expect(response.body).to include("統計情報")
      expect(response.body).to include("推移グラフ")
      expect(response.body).to include("最新データ")
      expect(response.body).to include("View in English")
    end
  end

  # /stats.json は他リポジトリからも参照される。既存キーは消さず追加のみ行う。
  # HTML を grep して数値を確かめると無関係な数字を拾うため、
  # 本番の値はこのエンドポイントで確認できるようにしておく。
  describe "GET /stats.json" do
    let(:json) { JSON.parse(response.body) }

    before do
      dojo = create(:dojo, name: '集計対象', counter: 2, created_at: Time.zone.local(2020, 5, 1))
      create(:dojo_event_service, dojo_id: dojo.id)
      create(:dojo, name: '対象外', counter: 1, created_at: Time.zone.local(2020, 5, 1))
      get "/stats.json"
    end

    it "他リポジトリが参照している既存のキーを返す" do
      expect(response).to have_http_status(200)
      expect(json).to include('active_dojos', 'total_events', 'total_ninjas', 'active_dojos_by_prefecture')
      # キーの存在だけでなく値も検証する。意味が変わっても気づけるようにするため
      expect(json['active_dojos']).to eq(Dojo.active.sum(:counter))
    end

    it "期間内の道場数を入れ子で返す" do
      # 集計対象はイベントサービスを持つ Dojo のみ。連名道場は counter 個と数える
      expect(json['dojos_in_period']).to eq({
        'start' => 2012, 'end' => 2025, 'aggregatable' => 2, 'total' => 3
      })
    end

    it "非アクティブな道場も期間内の道場数に含む" do
      # HTML の「非アクティブになった道場も含まれています」という表記と揃えている。
      # active_dojos より大きい値になるのはこのため
      dojo = create(:dojo, name: '休止中', counter: 1,
                    created_at: Time.zone.local(2021, 5, 1), inactivated_at: Time.zone.local(2022, 1, 1))
      create(:dojo_event_service, dojo_id: dojo.id, group_id: '999')
      get "/stats.json"

      expect(JSON.parse(response.body)['dojos_in_period']['aggregatable']).to eq(3)
    end
  end

  describe "GET /english/stats" do
    it "英語版の統計ページが表示される" do
      get "/english/stats"
      expect(response).to have_http_status(200)
      expect(response.body).to include("Statistics")
      expect(response.body).to include("Transition Charts")
      expect(response.body).to include("Latest Data")
      expect(response.body).to include("Switch to Japanese")
    end

    it "都道府県名が英語で表示される" do
      # テストデータベースに都道府県を作成（seeds.rbの形式に合わせる）
      Prefecture.find_or_create_by!(name: "東京都", region: "関東")
      Prefecture.find_or_create_by!(name: "大阪府", region: "近畿")
      Prefecture.find_or_create_by!(name: "北海道", region: "北海道")

      get "/english/stats"
      expect(response.body).to include("Tokyo")
      expect(response.body).to include("Osaka")
      expect(response.body).to include("Hokkaido")
    end

    it "グラフのタイトルが英語で表示される" do
      get "/english/stats"
      expect(response.body).to include("Number of Dojos")
      expect(response.body).to include("Number of Events")
      expect(response.body).to include("Number of Participants")
    end
  end

  describe "言語パラメータ" do
    it "言語パラメータがデフォルトで'ja'に設定される" do
      get "/stats"
      controller = @controller
      expect(controller.instance_variable_get(:@lang)).to eq('ja')
    end

    it "/english/stats で言語パラメータが'en'に設定される" do
      get "/english/stats"
      controller = @controller
      expect(controller.instance_variable_get(:@lang)).to eq('en')
    end
  end
end