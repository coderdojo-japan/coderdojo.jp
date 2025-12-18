# -*- coding: utf-8 -*-
module ApplicationHelper
  def full_title(page_title)
    if page_title.empty?
      "CoderDojo Japan - 子どものためのプログラミング道場" # Default title
    else
      "#{page_title} - CoderDojo Japan"
    end
  end

  def full_url(page_url)
    # When URL is composed by Rails
    if page_url.empty?
      # Set og:url with request param
      request.url
    elsif page_url.starts_with? '/'
      # Set og:url with given param
      'https://coderdojo.jp' + page_url
    else
      # 例: https://coderdojo.jp/...
      page_url
    end
  end

  def full_description(description)
    # Default description
    if description.empty?
      "CoderDojo は子どものためのプログラミング道場です。全国に#{Dojo.active_dojos_count}ヶ所以上あり、毎年#{Dojo::NUM_OF_ANNUAL_EVENTS}回以上のイベントが日本各地で開催されています。"
    else
      description
    end
  end

  def meta_image(filepath)
    base_url = Rails.env.development? ? 'http://localhost:3000' : 'https://coderdojo.jp'
    filepath = '/img/ogp-default.jpg' if filepath.blank?

    if filepath.starts_with? 'http'
      # 例: 'https://i.gyazo.com/...'
      filepath
    else
      # 例: '/img/ogp-docs.jpeg'
      base_url + filepath
    end
  end

  def page_lang(lang)
    lang.empty? ? 'ja' : lang
  end

  # 'inline_' プレフィックスがついたflashメッセージをビュー内で表示するヘルパー
  # inline_alert → alert, inline_warning → warning のように変換してBootstrapのCSSクラスを適用
  def render_inline_flash_messages
    flash.select { |type, _| type.to_s.start_with?('inline_') }.map do |type, message|
      css_class = type.to_s.gsub('inline_', '')
      content_tag(:div, message, class: "alert alert-#{css_class}", style: "margin-bottom: 15px;")
    end.join.html_safe
  end

  def kata_description
    "道場で役立つ資料やコンテスト情報、立ち上げ方や各種支援をまとめています。"
  end

  def is_kata?
    request.path.starts_with? "/kata"
  end

  # 画像を aFarkas/lazysizes 経由で遅延読み込みする
  # cf. https://github.com/aFarkas/lazysizes
  def lazy_image_tag(source, options={})
    options['data-src'] = asset_path(source)
    options['loading']  = 'lazy' # Optimize if available
    options[:class].blank? ?
      options[:class] = "lazyload" :
      options[:class] = "lazyload #{options[:class]}"

    if options[:min] == true
      # Use minified image path: foo.png -> foo.min.png
      image_tag(asset_path(source.split('.').join('.min.')), options)
    elsif !options[:min].blank?
      # The minified path above can be overridden if path is given.
      image_tag(asset_path(options[:min]), options)
    else
      # Default minified image is spinner.
      image_tag(asset_path('/spinner.svg'), options)
    end
  end

  def welcome_path(options={anchor: 'welcome'}); root_path(options); end
  def news_path   (options={anchor: 'news'});    root_path(options); end

  def news_url   (path='/'); 'https://news.coderdojo.jp' + path; end
  def dojomap_url(path='/'); 'https://map.coderdojo.jp'  + path; end
  def zen_url(path='/find'); 'https://zen.coderdojo.com' + path; end

  def decadojo_url;   'https://decadojo.coderdojo.jp'; end
  def dojocon_url;    'https://dojocon.coderdojo.jp';  end
  def dojoletter_url; 'https://news.coderdojo.jp/category/DojoLetterバックナンバー'; end
  def foundation_url; 'https://speakerdeck.com/helloworldfoundation'; end

  def facebook_group_url; 'https://www.facebook.com/groups/coderdojo.jp'; end
  def facebook_page_url;  'https://www.facebook.com/coderdojo.jp'; end
  def twitter_url;        'https://twitter.com/CoderDojoJapan'; end
  def youtube_url;        'https://youtube.com/CoderDojoJapan'; end

  def prefecture_name_in_english(prefecture_name)
    # 都道府県名の英語表記を返す簡易マッピング
    # 「都」「府」「県」を除去してから検索
    name_without_suffix = prefecture_name.gsub(/[都府県]$/, '')
    
    prefecture_names = {
      '北海道' => 'Hokkaido',
      '青森' => 'Aomori',
      '岩手' => 'Iwate',
      '宮城' => 'Miyagi',
      '秋田' => 'Akita',
      '山形' => 'Yamagata',
      '福島' => 'Fukushima',
      '茨城' => 'Ibaraki',
      '栃木' => 'Tochigi',
      '群馬' => 'Gunma',
      '埼玉' => 'Saitama',
      '千葉' => 'Chiba',
      '東京' => 'Tokyo',
      '神奈川' => 'Kanagawa',
      '新潟' => 'Niigata',
      '富山' => 'Toyama',
      '石川' => 'Ishikawa',
      '福井' => 'Fukui',
      '山梨' => 'Yamanashi',
      '長野' => 'Nagano',
      '岐阜' => 'Gifu',
      '静岡' => 'Shizuoka',
      '愛知' => 'Aichi',
      '三重' => 'Mie',
      '滋賀' => 'Shiga',
      '京都' => 'Kyoto',
      '大阪' => 'Osaka',
      '兵庫' => 'Hyogo',
      '奈良' => 'Nara',
      '和歌山' => 'Wakayama',
      '鳥取' => 'Tottori',
      '島根' => 'Shimane',
      '岡山' => 'Okayama',
      '広島' => 'Hiroshima',
      '山口' => 'Yamaguchi',
      '徳島' => 'Tokushima',
      '香川' => 'Kagawa',
      '愛媛' => 'Ehime',
      '高知' => 'Kochi',
      '福岡' => 'Fukuoka',
      '佐賀' => 'Saga',
      '長崎' => 'Nagasaki',
      '熊本' => 'Kumamoto',
      '大分' => 'Oita',
      '宮崎' => 'Miyazaki',
      '鹿児島' => 'Kagoshima',
      '沖縄' => 'Okinawa'
    }
    
    prefecture_names[name_without_suffix] || prefecture_name
  end

  def translate_dojo_tag(tag_name)
    # よくあるCoderDojoタグの英語訳
    tag_translations = {
      'ボードゲーム' => 'Board Games',
      'ロボット' => 'Robotics',
      'マインクラフト' => 'Minecraft',
      'タイピング' => 'Typing',
      '電子工作' => 'Electronics',
      'プログラミング' => 'Programming',
      'ゲーム' => 'Gaming',
      'パソコン' => 'Computers',
      '初心者歓迎' => 'Beginners Welcome',
      'オンライン開催あり' => 'Online Available',
      'オンライン' => 'Online',
      '女子' => 'Girls',
      '中高生' => 'Teens',
      '3Dプリンター' => '3D Printing',
      'AI' => 'AI',
      'IoT' => 'IoT',
      'VR' => 'VR',
      'AR' => 'AR',
      'Web' => 'Web',
      'アプリ' => 'Apps',
      'デザイン' => 'Design',
      '音楽' => 'Music',
      '動画' => 'Video',
      'アニメーション' => 'Animation',
      'ドローン' => 'Drones',
      'レゴ' => 'LEGO',
      '工作' => 'Crafts',
      'ラズベリーパイ' => 'Raspberry Pi',
      'Webサイト' => 'Web Development',
      'ウェブサイト' => 'Web Development',
      'スクラッチ' => 'Scratch',
      'Scratch' => 'Scratch',
      'Python' => 'Python',
      'JavaScript' => 'JavaScript',
      'Ruby' => 'Ruby',
      'Unity' => 'Unity',
      'micro:bit' => 'micro:bit',
      'マイクロビット' => 'micro:bit',
      'レーザーカッター' => 'Laser Cutting',
      'ビスケット' => 'Viscuit',
      'Viscuit' => 'Viscuit',
      'HTML' => 'HTML',
      'CSS' => 'CSS'
    }
    
    tag_translations[tag_name] || tag_name
  end

  def format_news_title(news)
    has_custom_emoji = news.title[0]&.match?(/[\p{Emoji}&&[^0-9#*]]/)
    return news.title if has_custom_emoji

    # Add preset Emoji to its prefix if news.title does not have Emoji.
    emoji = case news.url
            when %r{/podcasts/\d+}
              '📻'
            when %r{prtimes\.jp}
              '📢'
            else
              '📰'
            end
    "#{emoji} #{news.title}"
  end

  def news_link_url(news)
    # Convert absolute podcast URLs to relative paths for local development
    if news.url.match?(%r{^https://coderdojo\.jp/podcasts/\d+$})
      news.url.sub('https://coderdojo.jp', '')
    else
      news.url
    end
  end
end
