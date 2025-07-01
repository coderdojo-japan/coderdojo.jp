require 'rss'
require 'open-uri'
require 'yaml'
require 'active_support/broadcast_logger'

namespace :news do
  desc 'RSS フィードから最新ニュースを取得し、db/news.yml に書き出す'
  task fetch: :environment do
    # ロガー設定（ファイル＋コンソール出力）
    file_logger = ActiveSupport::Logger.new('log/news.log')
    console     = ActiveSupport::Logger.new(STDOUT)
    logger      = ActiveSupport::BroadcastLogger.new(file_logger, console)

    logger.info('==== START news:fetch ====')

    # テスト／ステージング環境ではサンプルファイル、本番は実サイトのフィード
    feed_urls = if Rails.env.test? || Rails.env.staging?
      [ Rails.root.join('spec', 'fixtures', 'sample_news.rss').to_s ]
    else
      [
        'https://coderdojo.jp/#news',
        # 必要に応じて他 Dojo の RSS もここに追加可能
        # 'https://coderdojotokyo.org/feed',
      ]
    end

    # RSS 取得＆パース
    items = feed_urls.flat_map do |url|
      logger.info("Fetching RSS → #{url}")
      begin
        URI.open(url) do |rss|
          feed = RSS::Parser.parse(rss, false)
          feed.items.map do |item|
            {
              'url'          => item.link,
              'title'        => item.title,
              'published_at' => item.pubDate.to_s
            }
          end
        end
      rescue => e
        logger.warn("⚠️ Failed to fetch #{url}: #{e.message}")
        []
      end
    end

    # 重複排除＆日付降順ソート
    unique = items.uniq { |i| i['url'] }
    sorted = unique.sort_by { |i| i['published_at'] }.reverse

    # id を追加
    sorted.each { |i| i['id'] = i['url'] }

    # YAML に書き出し
    File.open('db/news.yml', 'w') do |f|
      f.write({ 'news' => sorted }.to_yaml)
    end

    logger.info("✅ Wrote #{sorted.size} items to db/news.yml")
    logger.info('====  END news:fetch  ====')
  end
end
