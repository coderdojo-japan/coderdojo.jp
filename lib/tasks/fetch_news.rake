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
  desc 'RSS フィードから最新ニュースを取得し、db/news.yml に書き出す'
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
        # 既存アイテムの更新
        existing_item = existing_items_hash[new_item['url']]
        updated_item = existing_item.merge(new_item)  # 新しい情報で更新
        updated_items << updated_item
      else
        # 完全に新しいアイテム
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
end
