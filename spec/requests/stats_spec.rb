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
      # テストデータベースに都道府県を作成
      Prefecture.find_or_create_by!(name: "東京", region: "関東")
      Prefecture.find_or_create_by!(name: "大阪", region: "近畿")
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