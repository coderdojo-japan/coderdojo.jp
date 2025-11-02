require 'rss'

namespace :news do
  desc 'RSS フィードを取得し、db/news.yml に保存'
  task fetch: :environment do
    # ロガー設定（ファイル＋コンソール出力）
    console     = ActiveSupport::Logger.new(STDOUT)
    logger_file = ActiveSupport::Logger.new('log/news.log')
    logger      = ActiveSupport::BroadcastLogger.new(logger_file, console)

    logger.info('==== START news:fetch ====')

    # 本番/開発環境では実フィード、それ以外（テスト環境など）ではテスト用フィード
    DOJO_NEWS_FEED = 'https://news.coderdojo.jp/feed/'
    TEST_NEWS_FEED = Rails.root.join('spec', 'fixtures', 'sample_news.rss')
    RSS_FEED_LIST  = (Rails.env.test? || Rails.env.staging?) ?
      [TEST_NEWS_FEED] :
      [DOJO_NEWS_FEED]

    # RSS のデータ構造を、News のデータ構造に変換
    fetched_items = RSS_FEED_LIST.flat_map do |feed|
      feed = RSS::Parser.parse(feed, false)
      feed.items.map { |item|
        {
          'url'          => item.link,
          'title'        => item.title,
          'published_at' => item.pubDate.to_s
        }
      }
    end

    # 取得済みニュース (YAML) を読み込み、URL をキーとしたハッシュに変換
    news_yaml_file  = File.read Rails.root.join('db', 'news.yml')
    existing_items  = YAML.safe_load(news_yaml_file).index_by { it['url'] }
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
    created_items.each_with_index do |item, index|
      item['id'] = existing_max_id + index + 1
    end

    # URL をキーに、更新されなかった既存の YAML データを取得・保持
    updated_urls    = updated_items.map { it['url'] }
    unchanged_items = existing_items.values.reject { updated_urls.include?(it['url']) }

    # 新規・更新・既存の各アイテムをマージし、日付降順でソート
    merged_items = (unchanged_items + updated_items + created_items).sort_by {
      Time.parse(it['published_at'])
    }.reverse

    # YAML ファイルに書き出し
    File.open('db/news.yml', 'w') do |f|
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

    logger.info("✅ Wrote #{merged_items.size} items to db/news.yml (#{created_items.size} new, #{updated_items.size} updated)")
    logger.info('====  END news:fetch  ====')
  end

  desc 'db/news.yml からデータベースに upsert'
  task upsert: :environment do
    console     = ActiveSupport::Logger.new(STDOUT)
    logger_file = ActiveSupport::Logger.new('log/news.log')
    logger      = ActiveSupport::BroadcastLogger.new(logger_file, console)

    logger.info "==== START news:upsert ===="

    yaml_path = Rails.root.join('db', 'news.yml')
    entries   = YAML.safe_load File.read(yaml_path)
    new_count = 0
    updated_count = 0

    News.transaction do
      entries.each do |attrs|
        news = News.find_or_initialize_by(url: attrs['url'])
        is_new = news.new_record?

        news.assign_attributes(
          title:        attrs['title'],
          published_at: attrs['published_at']
        )

        if is_new || news.changed?
          news.save!
          status = is_new ? 'new' : 'updated'
          new_count += 1 if is_new
          updated_count += 1 unless is_new

          logger.info "[News] #{news.published_at.to_date} #{news.title} (#{status})"
        end
      end
    end

    logger.info "Upserted #{new_count + updated_count} items (#{new_count} new, #{updated_count} updated)."
    logger.info "==== END news:upsert ===="
  end
end
