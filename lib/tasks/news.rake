require 'rss'
require 'net/http'
require 'json'

TEST_NEWS_FEED = Rails.root.join('spec', 'fixtures', 'sample_news.rss').freeze
DOJO_NEWS_FEED = 'https://news.coderdojo.jp/feed/'.freeze
DOJO_NEWS_JSON = 'https://news.coderdojo.jp/wp-json/wp/v2/posts'.freeze
PR_TIMES_FEED  = 'https://prtimes.jp/companyrdf.php?company_id=38935'.freeze
DOJO_CAST_FEED = 'https://coderdojo.jp/podcasts.rss'.freeze

NEWS_YAML_PATH = 'db/news.yml'.freeze
NEWS_LOGS_PATH = 'log/news.log'.freeze
TASK_LOGGER    = ActiveSupport::BroadcastLogger.new(
                   ActiveSupport::Logger.new(NEWS_LOGS_PATH),
                   ActiveSupport::Logger.new(STDOUT)
                 )

# DojoNews (WordPress) REST API から全投稿を取得するメソッド
# https://news.coderdojo.jp/wp-json/wp/v2/posts (JSON)
def fetch_dojo_news_posts(api_endpoint)
  items = []

  loop.with_index(1) do |_, page|
    uri = URI(api_endpoint)
    uri.query = URI.encode_www_form(page: page, per_page: 100, status: 'publish')

    response = Net::HTTP.get_response(uri)
    break unless response.is_a?(Net::HTTPSuccess)

    posts = JSON.parse(response.body)
    break if posts.empty?

    posts.each do |post|
      items << {
        'url'          => post['link'],
        'title'        => post['title']['rendered'],
        'published_at' => Time.parse(post['date_gmt'] + ' UTC').in_time_zone('Asia/Tokyo').iso8601
      }
    end

    TASK_LOGGER.info("📄 WordPress API: ページ #{page} から #{posts.size} 件取得")
  end

  items
end

# PR TIMES RSS フィードからすべてのプレスリリースを取得するメソッド
def fetch_prtimes_posts(rss_feed_url)
  feed = RSS::Parser.parse(rss_feed_url, false)
  feed.items.map do |item|
    published_at = if item.respond_to?(:dc_date) && item.dc_date
                     item.dc_date.in_time_zone('Asia/Tokyo').iso8601
                   else
                     raise "PR TIMES feed: dc:date not found for item: #{item.link}"
                   end

    {
      'url'          => item.link,
      'title'        => item.title,
      'published_at' => published_at
    }
  end
end

# DojoCast ポッドキャスト RSS フィードから取得するメソッド
def fetch_podcast_posts(rss_feed_url)
  feed = RSS::Parser.parse(rss_feed_url, false)
  feed.items.map do |item|
    # タイトルの先頭3桁の数字から内部リンクを生成
    # 例: "033 - タイトル" → /podcasts/33
    # 例: "001 - タイトル" → /podcasts/1
    unless item.title =~ /^(\d{3})\s/
      raise "DojoCast episode number not found in title: #{item.title}"
    end

    episode_number = $1.to_i  # 033 → 33, 001 → 1
    internal_url = "https://coderdojo.jp/podcasts/#{episode_number}"

    {
      'url'          => internal_url,
      'title'        => item.title,
      'published_at' => item.pubDate.in_time_zone('Asia/Tokyo').iso8601
    }
  end
end

namespace :news do
  desc "ニュースフィードを取得し、#{NEWS_YAML_PATH} を再構築（冪等）"
  task fetch: :environment do
    # ロガー設定（ファイル＋コンソール出力）
    TASK_LOGGER.info('==== START news:fetch ====')

    # 1. news.yml を空にする
    File.write(NEWS_YAML_PATH, [].to_yaml)
    TASK_LOGGER.info("📄 news.yml をリセットしました")

    # 2. 環境に応じたデータソースから取得
    if Rails.env.test? || Rails.env.staging?
      # テスト環境: サンプルRSS（RSS 2.0、pubDateのみ）
      TASK_LOGGER.info("🧪 テスト環境: サンプルRSSから取得")
      items = RSS::Parser.parse(TEST_NEWS_FEED, false).items.map { |item|
        {
          'url'          => item.link,
          'title'        => item.title,
          'published_at' => item.pubDate.in_time_zone('Asia/Tokyo').iso8601
        }
      }
    else
      # 本番環境: WordPress REST API + PR TIMES RSS + Podcast RSS
      dojo_news_items = fetch_dojo_news_posts(DOJO_NEWS_JSON)
      TASK_LOGGER.info("📰 news.coderdojo.jp から #{dojo_news_items.size} 件を取得")

      prtimes_items = fetch_prtimes_posts(PR_TIMES_FEED)
      TASK_LOGGER.info("📢 PR TIMES から #{prtimes_items.size} 件を取得")

      podcast_items = fetch_podcast_posts(DOJO_CAST_FEED)
      TASK_LOGGER.info("📻 DojoCast から #{podcast_items.size} 件を取得")

      items = dojo_news_items + prtimes_items + podcast_items
    end

    # 3. 古い順にソートして ID を付与（ISO 8601 なら文字列のままソート可能）
    items_by_oldest = items.sort_by    { |item| item['published_at'] }
    items_by_oldest.each.with_index(1) { |item, index| item['id'] = index }

    # 4. 最新順にソートして YAML ファイルに書き出す（キー順序: id, url, title, published_at）
    File.open(NEWS_YAML_PATH, 'w') do |file|
      file.write(items_by_oldest.reverse.map do |item|
        {
          'id'           => item['id'],
          'url'          => item['url'],
          'title'        => item['title'],
          'published_at' => item['published_at']
        }
      end.to_yaml(line_width: -1))
    end

    TASK_LOGGER.info("✅ 合計 #{items_by_oldest.size} 件を news.yml に保存しました")
    TASK_LOGGER.info("📌 次は 'bundle exec rails news:upsert' でデータベースに反映してください")
    TASK_LOGGER.info("====  END news:fetch  ====")
    TASK_LOGGER.info("")
  end


  desc "#{NEWS_YAML_PATH} からデータベースに upsert (YAMLのIDを使用)"
  task upsert: :environment do
    TASK_LOGGER.info "==== START news:upsert ===="

    news_items = YAML.safe_load File.read(NEWS_YAML_PATH)
    created_count = 0
    updated_count = 0

    News.transaction do
      # まず、同じURLだが異なるIDのレコードを削除
      news_items.each do |item|
        existing_with_different_id = News.where(url: item['url']).where.not(id: item['id']).first
        if existing_with_different_id
          TASK_LOGGER.info "[News] Removing duplicate: ID:#{existing_with_different_id.id} (URL: #{item['url']}) to be replaced by ID:#{item['id']}"
          existing_with_different_id.destroy
        end
      end

      news_items.each do |item|
        # YAMLのIDを使ってレコードを検索または初期化
        news = News.find_or_initialize_by(id: item['id'])
        news.assign_attributes(
          url:          item['url'],
          title:        item['title'],
          published_at: item['published_at']
        )

        is_new_record = news.new_record?
        if is_new_record || news.changed?
          news.save!

          status = is_new_record ? 'new' : 'updated'
          created_count += 1 if     is_new_record
          updated_count += 1 unless is_new_record

          TASK_LOGGER.info "[News] ID #{format('%04d', news.id)}: #{news.published_at.to_date} #{news.title} (#{status})"
        end
      end

      # YAMLに存在しないレコードを削除
      yaml_ids = news_items.map { |item| item['id'] }
      deleted_count = News.where.not(id: yaml_ids).destroy_all.size
      if deleted_count > 0
        TASK_LOGGER.info "Deleted #{deleted_count} items that are not in YAML."
      end
    end

    TASK_LOGGER.info "Upserted #{created_count + updated_count} items (#{created_count} new, #{updated_count} updated)."
    TASK_LOGGER.info "==== END news:upsert ===="
    TASK_LOGGER.info ""
  end
end
