require 'rss'
require 'net/http'
require 'json'

PR_TIMES_FEED  = 'https://prtimes.jp/companyrdf.php?company_id=38935'.freeze
DOJO_NEWS_FEED = 'https://news.coderdojo.jp/feed/'.freeze
TEST_NEWS_FEED = Rails.root.join('spec', 'fixtures', 'sample_news.rss').freeze

NEWS_YAML_PATH = 'db/news.yml'.freeze
NEWS_LOGS_PATH = 'log/news.log'.freeze
TASK_LOGGER    = ActiveSupport::BroadcastLogger.new(
                   ActiveSupport::Logger.new(NEWS_LOGS_PATH),
                   ActiveSupport::Logger.new(STDOUT)
                 )

# DojoNews (WordPress) REST APIから全投稿を取得するメソッド
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

namespace :news do
  desc "RSS フィードを取得し、#{NEWS_YAML_PATH} に保存"
  task fetch: :environment do
    # ロガー設定（ファイル＋コンソール出力）
    TASK_LOGGER.info('==== START news:fetch ====')

    # 本番/開発環境では実フィード、それ以外（テスト環境など）ではテスト用フィード
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
          'published_at' => published_at.in_time_zone('Asia/Tokyo').iso8601  # JST に統一
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

    TASK_LOGGER.info "✅ Wrote #{merged_items.size} items to #{NEWS_YAML_PATH} (#{created_items.size} new, #{updated_items.size} updated)"
    TASK_LOGGER.info "====  END news:fetch  ===="
    TASK_LOGGER.info ""
  end

  desc "news.yml をリセットし、すべてのフィードから全記事を取得"
  task 'fetch:reset' => :environment do
    # ロガー設定（ファイル＋コンソール出力）
    TASK_LOGGER.info('==== START news:fetch:reset ====')

    # 1. news.yml を空にする
    File.write(NEWS_YAML_PATH, [].to_yaml)
    TASK_LOGGER.info("📄 news.yml をリセットしました")

    # 2. WordPress REST API からすべての投稿を取得
    dojo_news_items = fetch_dojo_news_posts("https://news.coderdojo.jp/wp-json/wp/v2/posts")
    TASK_LOGGER.info("📰 news.coderdojo.jp から #{dojo_news_items.size} 件を取得")

    # 3. PR TIMES RSS フィードからすべてのプレスリリースを取得
    prtimes_items = []
    feed = RSS::Parser.parse(PR_TIMES_FEED, false)
    feed.items.each do |item|
      published_at = if item.respond_to?(:dc_date) && item.dc_date
                       item.dc_date.iso8601
                     else
                       raise "PR TIMES feed: dc:date not found for item: #{item.link}"
                     end

      prtimes_items << {
        'url'          => item.link,
        'title'        => item.title,
        'published_at' => published_at
      }
    end
    TASK_LOGGER.info("📢 PR TIMES から #{prtimes_items.size} 件を取得")

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

    TASK_LOGGER.info("✅ 合計 #{sorted_items.size} 件を news.yml に保存しました")
    TASK_LOGGER.info("📌 次は 'bundle exec rails news:upsert' でデータベースに反映してください")
    TASK_LOGGER.info("====  END news:fetch:reset  ====")
  end


  desc "#{NEWS_YAML_PATH} からデータベースに upsert"
  task upsert: :environment do
    TASK_LOGGER.info "==== START news:upsert ===="

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

          TASK_LOGGER.info "[News] #{news.published_at.to_date} #{news.title} (#{status})"
        end
      end
    end

    TASK_LOGGER.info "Upserted #{created_count + updated_count} items (#{created_count} new, #{updated_count} updated)."
    TASK_LOGGER.info "==== END news:upsert ===="
    TASK_LOGGER.info ""
  end
end
