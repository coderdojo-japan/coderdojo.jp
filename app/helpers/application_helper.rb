# -*- coding: utf-8 -*-
module ApplicationHelper
  def full_title(page_title)
    page_title = @obj.display_title if page_title.empty? && @obj && !@obj.permalink.nil?
    if page_title.empty?
      "CoderDojo Japan - 子どものためのプログラミング道場" # Default title
    else
      "#{page_title} - CoderDojo Japan"
    end
  end

  def full_url(page_url)
    # When URL is composed by Scrivito
    return @obj.permalink if @obj && !@obj.permalink.nil?

    # When URL is composed by Rails
    if page_url.empty?
      # Set og:url with request param
      request.url
    else
      # Set og:url with given param
      page_url
    end
  end

  def full_description(description)
    description = kata_description if @obj && @obj.permalink == "kata"
    if description.empty?
      "CoderDojo は子どものためのプログラミング道場です。2011年にアイルランドで始まり、全国では#{Dojo.active_dojos_count}ヶ所以上、世界では#{Dojo::NUM_OF_COUNTRIES}ヶ国・#{Dojo::NUM_OF_WORLD_DOJOS}ヶ所で開催されています。" # Default description
    else
      description
    end
  end

  def meta_image(filepath='og-image.png')
    base_url = Rails.env.development? ? 'http://localhost:3000/' : 'https://coderdojo.jp/'
    filepath = filepath[1..] if filepath.starts_with? '/'
    base_url + filepath
  end

  def kata_description
    "道場で役立つ資料やコンテスト情報、立ち上げ方や各種支援をまとめています。"
  end

  def using_scrivito?
    !@obj.nil?
  end

  def is_kata?
    request.path.starts_with? "/kata"
  end
end
