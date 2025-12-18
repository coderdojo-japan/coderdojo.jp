require 'rails_helper'

RSpec.describe "News", type: :request do
  describe "GET /news" do
    before do
      # テスト用のニュースデータを作成
      @news1 = News.create!(
        title: "テストニュース1",
        url: "https://example.com/news1",
        published_at: 2.days.ago
      )
      @news2 = News.create!(
        title: "テストニュース2", 
        url: "https://example.com/news2",
        published_at: 1.day.ago
      )
      @news3 = News.create!(
        title: "テストニュース3",
        url: "https://example.com/news3",
        published_at: 3.days.ago
      )
    end

    it "正常にレスポンスを返す" do
      get news_index_path
      expect(response).to have_http_status(:success)
    end

    it "適切なタイトルを表示する" do
      get news_index_path
      expect(response.body).to include("CoderDojo ニュース")
    end

    it "ニュース記事を新しい順に表示する" do
      get news_index_path
      
      # 新しい順に表示されることを確認
      news2_pos = response.body.index(@news2.title)
      news1_pos = response.body.index(@news1.title)
      news3_pos = response.body.index(@news3.title)
      
      expect(news2_pos).to be < news1_pos
      expect(news1_pos).to be < news3_pos
    end

    it "ニュースのタイトルとリンクを表示する" do
      get news_index_path
      
      expect(response.body).to include(@news1.title)
      expect(response.body).to include(@news1.url)
      expect(response.body).to include(@news2.title)
      expect(response.body).to include(@news2.url)
    end

    it "ニュースがない場合は適切なメッセージを表示する" do
      News.destroy_all
      get news_index_path
      
      expect(response.body).to include("現在、ニュース記事はありません")
    end
  end
end