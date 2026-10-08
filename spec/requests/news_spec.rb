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
      # format_news_title によってプリセット絵文字が追加される可能性があるため、
      # タイトルの主要部分で位置を確認
      news2_pos = response.body.index("テストニュース2")
      news1_pos = response.body.index("テストニュース1")
      news3_pos = response.body.index("テストニュース3")

      expect(news2_pos).to be < news1_pos
      expect(news1_pos).to be < news3_pos
    end

    it "ニュースのタイトルとリンクを表示する" do
      get news_index_path

      # format_news_title によってプリセット絵文字が追加される可能性があるため、
      # タイトルの主要部分が含まれていることを確認
      expect(response.body).to include("テストニュース1")
      expect(response.body).to include(@news1.url)
      expect(response.body).to include("テストニュース2")
      expect(response.body).to include(@news2.url)
    end

    it "ニュースがない場合は適切なメッセージを表示する" do
      News.destroy_all
      get news_index_path

      expect(response.body).to include("現在、ニュース記事はありません")
    end
  end

  describe "GET /news.json" do
    before do
      # テスト用のニュースデータを作成
      @news1 = News.create!(
        title: "テストニュース1",
        url: "https://example.com/news1",
        published_at: 2.days.ago
      )
      @news2 = News.create!(
        title: "テストニュース2",
        url: "https://coderdojo.jp/podcasts/2",
        published_at: 1.day.ago
      )
    end

    context "variant が設定されている場合" do
      it "variant :pc が設定されていても JSON 形式でレスポンスを返す" do
        # rack-user_agent gem が PC からのアクセスで variant :pc を設定する状況を再現
        # set_request_variant をオーバーライドして variant を強制的に設定
        allow_any_instance_of(NewsController).to receive(:set_request_variant) do |controller|
          controller.request.variant = :pc
        end

        get news_index_path(format: :json)

        expect(response).to have_http_status(:success)
        expect(response.content_type).to match(/application\/json/)

        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
        expect(json.length).to eq(2)
      end

      it "variant :smartphone が設定されていても JSON 形式でレスポンスを返す" do
        # rack-user_agent gem がモバイルからのアクセスで variant :smartphone を設定する状況を再現
        allow_any_instance_of(NewsController).to receive(:set_request_variant) do |controller|
          controller.request.variant = :smartphone
        end

        get news_index_path(format: :json)

        expect(response).to have_http_status(:success)
        expect(response.content_type).to match(/application\/json/)

        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
        expect(json.length).to eq(2)
      end
    end

    it "JSON形式でレスポンスを返す" do
      get news_index_path(format: :json)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to match(/application\/json/)
    end

    it "ニュースデータをJSON形式で返す" do
      get news_index_path(format: :json)
      json = JSON.parse(response.body)

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)

      # 新しい順に返されることを確認
      expect(json[0]["title"]).to eq("テストニュース2")
      expect(json[1]["title"]).to eq("テストニュース1")
    end

    it "各ニュースアイテムに必要な属性が含まれる" do
      get news_index_path(format: :json)
      json = JSON.parse(response.body)

      first_news = json[0]
      expect(first_news).to have_key("id")
      expect(first_news).to have_key("title")
      expect(first_news).to have_key("url")
      expect(first_news).to have_key("published_at")
    end

    it "ニュースがない場合は空の配列を返す" do
      News.destroy_all
      get news_index_path(format: :json)

      json = JSON.parse(response.body)
      expect(json).to eq([])
    end
  end

  describe "GET /news.rss" do
    before do
      @news1 = News.create!(
        title: "テストニュース1",
        url: "https://example.com/news1",
        published_at: 2.days.ago
      )
      # DojoCast の項目。HTML では link_url で相対パスになるが、RSS では絶対 URL のまま出す
      @news2 = News.create!(
        title: "DojoCast エピソード",
        url: "https://coderdojo.jp/podcasts/2",
        published_at: 1.day.ago
      )
      @news3 = News.create!(
        title: "テストニュース3",
        url: "https://example.com/news3",
        published_at: 3.days.ago
      )
    end

    let(:feed) { Nokogiri::XML(response.body) { |config| config.strict } }

    it "RSS 2.0 形式でレスポンスを返す" do
      get news_index_path(format: :rss)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to match(%r{application/rss\+xml})
      expect(feed.at_xpath("/rss/@version").value).to eq("2.0")
    end

    it "チャンネルの情報を返す" do
      get news_index_path(format: :rss)

      expect(feed.at_xpath("/rss/channel/title").text).to include("CoderDojo ニュース")
      expect(feed.at_xpath("/rss/channel/link").text).to eq("https://coderdojo.jp/news")
      expect(feed.at_xpath("/rss/channel/description").text).to be_present
      self_link = feed.at_xpath("/rss/channel/atom:link[@rel='self']", "atom" => "http://www.w3.org/2005/Atom")
      expect(self_link["href"]).to eq("https://coderdojo.jp/news.rss")
    end

    it "ニュースを新しい順に返す" do
      get news_index_path(format: :rss)

      links = feed.xpath("/rss/channel/item/link").map(&:text)
      expect(links).to eq([@news2.url, @news1.url, @news3.url])
    end

    it "各項目にタイトル・絶対 URL・guid・公開日時を含める" do
      get news_index_path(format: :rss)

      item = feed.at_xpath("/rss/channel/item")
      expect(item.at_xpath("title").text).to eq(@news2.formatted_title)
      expect(item.at_xpath("link").text).to eq("https://coderdojo.jp/podcasts/2")
      expect(item.at_xpath("guid").text).to eq("https://coderdojo.jp/podcasts/2")
      expect(item.at_xpath("pubDate").text).to eq(@news2.published_at.rfc2822)
    end

    it "variant :smartphone が設定されていても RSS を返す" do
      allow_any_instance_of(NewsController).to receive(:set_request_variant) do |controller|
        controller.request.variant = :smartphone
      end

      get news_index_path(format: :rss)

      expect(response).to have_http_status(:success)
      expect(feed.xpath("/rss/channel/item").size).to eq(3)
    end

    it "ニュースがない場合は項目のないフィードを返す" do
      News.destroy_all
      get news_index_path(format: :rss)

      expect(response).to have_http_status(:success)
      expect(feed.xpath("/rss/channel/item")).to be_empty
    end

    it "ページの head からフィードを自動検出できる" do
      get news_index_path

      link = Nokogiri::HTML(response.body).at_css('link[rel="alternate"][type="application/rss+xml"]')
      expect(link["href"]).to eq("https://coderdojo.jp/news.rss")
    end
  end
end
