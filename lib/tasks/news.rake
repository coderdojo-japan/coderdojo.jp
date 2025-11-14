require 'rss'
require 'net/http'
require 'json'

NEWS_YAML_PATH = 'db/news.yml'.freeze
NEWS_LOG_PATH = 'log/news.log'.freeze

namespace :news do
  desc "RSS フィードを取得し、#{NEWS_YAML_PATH} に保存"
  task fetch: :environment do
    # ロガー設定（ファイル＋コンソール出力）
    console     = ActiveSupport::Logger.new(STDOUT)
    logger_file = ActiveSupport::Logger.new(NEWS_LOG_PATH)
    logger      = ActiveSupport::BroadcastLogger.new(logger_file, console)

    logger.info('==== START news:fetch ====')

    # 本番/開発環境では実フィード、それ以外（テスト環境など）ではテスト用フィード
    DOJO_NEWS_FEED = 'https://news.coderdojo.jp/feed/'
    PR_TIMES_FEED  = 'https://prtimes.jp/companyrdf.php?company_id=38935'
    TEST_NEWS_FEED = Rails.root.join('spec', 'fixtures', 'sample_news.rss')
    RSS_FEED_LIST  = (Rails.env.test? || Rails.env.staging?) ?
      [TEST_NEWS_FEED] :
      [DOJO_NEWS_FEED, PR_TIMES_FEED]

    # RSS のデータ構造を、News のデータ構造に変換
    fetched_items = RSS_FEED_LIST.flat_map do |feed|
      feed = RSS::Parser.parse(feed, false)
      feed.items.map { |item|
        # RSS 1.0 (RDF) と RSS 2.0 の両方に対応
        # RSS 2.0: pubDate, RSS 1.0 (RDF): dc:date
        # - PR TIMES: RSS 1.0 (RDF) 形式 - <rdf:RDF> タグ、dc:date フィールドを使用
        # - CoderDojo News: RSS 2.0 形式 - <rss version="2.0"> タグ、pubDate フィールドを使用
        published_at = if item.respond_to?(:pubDate) && item.pubDate
                         item.pubDate
                       elsif item.respond_to?(:dc_date) && item.dc_date
                         item.dc_date
                       else
                         raise "Unexpected RSS format: neither pubDate nor dc:date found for item: #{item.link}"
                       end

        {
          'url'          => item.link,
          'title'        => item.title,
          'published_at' => published_at.iso8601  # ISO 8601 形式に統一
        }
      }
    end

    # 取得済みニュース (YAML) を読み込み、URL をキーとしたハッシュに変換
    existing_items  = YAML.safe_load(File.read NEWS_YAML_PATH).index_by { it['url'] }
    existing_max_id = existing_items.flat_map { |url, item| item['id'].to_i }.max || 0

    # 新規記事と既存記事を分離
    created_items = []
    updated_items = []

    fetched_items.each do |fetched_item|
      existing_item = existing_items[fetched_item['url']]

      if existing_item.nil?
        # 新規アイテムならそのまま追加
        created_items << fetched_item
      elsif existing_item['title'] != fetched_item['title'] || existing_item['published_at'] != fetched_item['published_at']
        # タイトルまたは公開日が変わっていたら更新
        updated_items << existing_item.merge(fetched_item)
      end
    end

    # 新しいアイテムのみに ID を割り当て（古い順）
    created_items.sort_by! { Time.parse it['published_at'] }
    created_items.each.with_index(1) do |item, index|
      item['id'] = existing_max_id + index
    end

    # URL をキーに、更新されなかった既存の YAML データを取得・保持
    updated_urls    = updated_items.map { it['url'] }
    unchanged_items = existing_items.values.reject { updated_urls.include?(it['url']) }

    # 新規・更新・既存の各アイテムをマージし、日付降順でソート
    merged_items = (unchanged_items + updated_items + created_items).sort_by {
      Time.parse(it['published_at'])
    }.reverse

    # YAML ファイルに書き出し
    File.open(NEWS_YAML_PATH, 'w') do |f|
      formatted_items = merged_items.map do |item|
        {
          'id'           => item['id'],
          'url'          => item['url'],
          'title'        => item['title'],
          'published_at' => item['published_at']
        }
      end

      f.write(formatted_items.to_yaml)
    end

    logger.info "✅ Wrote #{merged_items.size} items to #{NEWS_YAML_PATH} (#{created_items.size} new, #{updated_items.size} updated)"
    logger.info "====  END news:fetch  ===="
    logger.info ""
  end

  desc "news.yml をリセットし、すべてのフィードから全記事を取得"
  task 'fetch:reset' => :environment do
    # ロガー設定（ファイル＋コンソール出力）
    console     = ActiveSupport::Logger.new(STDOUT)
    logger_file = ActiveSupport::Logger.new(NEWS_LOG_PATH)
    logger      = ActiveSupport::BroadcastLogger.new(logger_file, console)

    logger.info('==== START news:fetch:reset ====')

    # 1. news.yml を空にする
    File.write(NEWS_YAML_PATH, [].to_yaml)
    logger.info("📄 news.yml をリセットしました")

    # 2. WordPress REST API からすべての投稿を取得
    dojo_news_items = fetch_all_wordpress_posts(logger)
    logger.info("📰 news.coderdojo.jp から #{dojo_news_items.size} 件を取得")

    # 3. PR TIMES RSS フィードからすべてのプレスリリースを取得
    prtimes_items = fetch_prtimes_feed(logger)
    logger.info("📢 PR TIMES から #{prtimes_items.size} 件を取得")

    # 4. すべてのアイテムをマージし、ID を付与
    all_items = (dojo_news_items + prtimes_items).sort_by { |item|
      Time.parse(item['published_at'])
    }

    # ID を付与（古い順で1から）
    all_items.each.with_index(1) do |item, index|
      item['id'] = index
    end

    # 最新順にソート
    sorted_items = all_items.sort_by { |item| 
      Time.parse(item['published_at'])
    }.reverse

    # 5. YAML ファイルに書き出し
    File.open(NEWS_YAML_PATH, 'w') do |f|
      formatted_items = sorted_items.map do |item|
        {
          'id'           => item['id'],
          'url'          => item['url'],
          'title'        => item['title'],
          'published_at' => item['published_at']
        }
      end

      f.write(formatted_items.to_yaml)
    end

    logger.info("✅ 合計 #{sorted_items.size} 件を news.yml に保存しました")
    logger.info("📌 次は 'bundle exec rails news:upsert' でデータベースに反映してください")
    logger.info("====  END news:fetch:reset  ====")
  end

  # WordPress REST API からすべての投稿を取得
  def fetch_all_wordpress_posts(logger)
    items = []
    page = 1
    per_page = 100

    loop do
      uri = URI("https://news.coderdojo.jp/wp-json/wp/v2/posts")
      uri.query = URI.encode_www_form(page: page, per_page: per_page, status: 'publish')

      response = Net::HTTP.get_response(uri)
      break unless response.is_a?(Net::HTTPSuccess)

      posts = JSON.parse(response.body)
      break if posts.empty?

      posts.each do |post|
        items << {
          'url' => post['link'],
          'title' => post['title']['rendered'],
          'published_at' => Time.parse(post['date_gmt'] + ' UTC').iso8601
        }
      end

      logger.info("📄 WordPress API: ページ #{page} から #{posts.size} 件取得")
      page += 1
    end

    items
  end

  # PR TIMES RSS フィードから全記事を取得
  def fetch_prtimes_feed(logger)
    items = []

    begin
      feed = RSS::Parser.parse('https://prtimes.jp/companyrdf.php?company_id=38935', false)
      
      feed.items.each do |item|
        published_at = if item.respond_to?(:dc_date) && item.dc_date
                         item.dc_date.iso8601
                       else
                         raise "PR TIMES feed: dc:date not found for item: #{item.link}"
                       end

        items << {
          'url' => item.link,
          'title' => item.title,
          'published_at' => published_at
        }
      end

      logger.info("📢 PR TIMES RSS: #{items.size} 件取得")
    rescue => e
      logger.error("❌ PR TIMES フィード取得エラー: #{e.message}")
    end

    items
  end

  desc "#{NEWS_YAML_PATH} からデータベースに upsert"
  task upsert: :environment do
    console     = ActiveSupport::Logger.new(STDOUT)
    logger_file = ActiveSupport::Logger.new(NEWS_LOG_PATH)
    logger      = ActiveSupport::BroadcastLogger.new(logger_file, console)

    logger.info "==== START news:upsert ===="

    news_items = YAML.safe_load File.read(NEWS_YAML_PATH)
    created_count = 0
    updated_count = 0

    News.transaction do
      news_items.each do |item|
        news = News.find_or_initialize_by(url: item['url'])
        news.assign_attributes(
          title:        item['title'],
          published_at: item['published_at']
        )

        is_new_record = news.new_record?
        if is_new_record || news.changed?
          news.save!

          status = is_new_record ? 'new' : 'updated'
          created_count += 1 if     is_new_record
          updated_count += 1 unless is_new_record

          logger.info "[News] #{news.published_at.to_date} #{news.title} (#{status})"
        end
      end
    end

    logger.info "Upserted #{created_count + updated_count} items (#{created_count} new, #{updated_count} updated)."
    logger.info "==== END news:upsert ===="
    logger.info ""
  end
end
