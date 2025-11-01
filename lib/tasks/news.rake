require 'rss'
require 'net/http'
require 'uri'
require 'yaml'
require 'time'
require 'active_support/broadcast_logger'

def safe_open(url)
  uri = URI.parse(url)
  raise "不正なURLです: #{url}" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    request = Net::HTTP::Get.new(uri)
    response = http.request(request)
    response.body
  end
end

def fetch_rss_items(url, logger)
  logger.info("Fetching RSS → #{url}")
  begin
    rss = safe_open(url)
    feed = RSS::Parser.parse(rss, false)
    feed.items.map { |item| item_to_hash(item) }
  rescue => e
    logger.warn("⚠️ Failed to fetch #{url}: #{e.message}")
    []
  end
end

def item_to_hash(item)
  {
    'url'          => item.link,
    'title'        => item.title,
    'published_at' => item.pubDate.to_s
  }
end

namespace :news do
  desc 'RSS フィードを取得し、db/news.yml に保存'
  task fetch: :environment do
    # ロガー設定（ファイル＋コンソール出力）
    file_logger = ActiveSupport::Logger.new('log/news.log')
    console     = ActiveSupport::Logger.new(STDOUT)
    logger      = ActiveSupport::BroadcastLogger.new(file_logger, console)

    logger.info('==== START news:fetch ====')

    # 既存の news.yml を読み込み
    yaml_path = Rails.root.join('db', 'news.yml')
    existing_news = if File.exist?(yaml_path)
                      YAML.safe_load(File.read(yaml_path), permitted_classes: [Time], aliases: true)['news'] || []
                    else
                      []
                    end

    # テスト／ステージング環境ではサンプルファイル、本番は実サイトのフィード
    feed_urls = if Rails.env.test? || Rails.env.staging?
                  [Rails.root.join('spec', 'fixtures', 'sample_news.rss').to_s]
                else
                  [
                    'https://news.coderdojo.jp/feed/'
                    # 必要に応じて他 Dojo の RSS もここに追加可能
                    # 'https://coderdojotokyo.org/feed',
                  ]
                end

    new_items = feed_urls.flat_map { |url| fetch_rss_items(url, logger) }

    # 既存データをハッシュに変換（URL をキーに）
    existing_items_hash = existing_news.index_by { |item| item['url'] }

    # 新しいアイテムと既存アイテムを分離
    truly_new_items = []
    updated_items = []

    new_items.each do |new_item|
      if existing_items_hash.key?(new_item['url'])
        existing_item = existing_items_hash[new_item['url']]
        # タイトルまたは公開日が変わった場合のみ更新
        if existing_item['title'] != new_item['title'] || existing_item['published_at'] != new_item['published_at']
          updated_items << existing_item.merge(new_item)
        end
      else
        truly_new_items << new_item
      end
    end

    # 既存の最大IDを取得
    max_existing_id = existing_news.map { |item| item['id'].to_i }.max || 0

    # 新しいアイテムのみに ID を割り当て（古い順）
    truly_new_items_sorted = truly_new_items.sort_by { |item|
      Time.parse(item['published_at'])
    }

    truly_new_items_sorted.each_with_index do |item, index|
      item['id'] = max_existing_id + index + 1
    end

    # 更新されなかった既存アイテムを取得
    updated_urls = updated_items.map { |item| item['url'] }
    unchanged_items = existing_news.reject { |item| updated_urls.include?(item['url']) }

    # 全アイテムをマージ
    all_items = unchanged_items + updated_items + truly_new_items_sorted

    # 日付降順ソート
    sorted_items = all_items.sort_by { |item|
      Time.parse(item['published_at'])
    }.reverse

    # YAML ファイルに書き出し
    File.open('db/news.yml', 'w') do |f|
      formatted_items = sorted_items.map do |item|
        {
          'id'           => item['id'],
          'url'          => item['url'],
          'title'        => item['title'],
          'published_at' => item['published_at']
        }
      end

      f.write({ 'news' => formatted_items }.to_yaml)
    end

    logger.info("✅ Wrote #{sorted_items.size} items to db/news.yml (#{truly_new_items_sorted.size} new, #{updated_items.size} updated)")
    logger.info('====  END news:fetch  ====')
  end

  desc 'db/news.yml からデータベースに upsert'
  task upsert: :environment do
    file_logger = ActiveSupport::Logger.new('log/news.log')
    console     = ActiveSupport::Logger.new(STDOUT)
    logger      = ActiveSupport::BroadcastLogger.new(file_logger, console)

    logger.info "==== START news:upsert ===="

    yaml_path = Rails.root.join('db', 'news.yml')
    raw       = YAML.safe_load(File.read(yaml_path), permitted_classes: [Time], aliases: true)

    entries = raw['news'] || []
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
