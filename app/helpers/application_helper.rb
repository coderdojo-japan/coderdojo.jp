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
    page_url ||= root_url + @obj.permalink if @obj && !@obj.permalink.nil?
    if page_url.empty?
      root_url # Default URL
    else
      page_url
    end
  end

  def meta_description(description)
    description ||= kata_description if @obj && @obj.permalink == "kata"
    if description.empty?
      "CoderDojo は子どものためのプログラミング道場です。2011年にアイルランドで始まり、全国では#{Dojo::NUM_OF_JAPAN_DOJOS}ヶ所以上、世界では#{Dojo::NUM_OF_COUNTRIES}ヶ国・#{Dojo::NUM_OF_WHOLE_DOJOS}ヶ所で開催されています。" # Default description
    else
      description
    end
  end

  def kata_description
    "全国の CoderDojo で活用されている資料や教材、子ども向けのプログラミングキャンプ・プログラミングコンテスト情報、CoderDojo の立ち上げ方・関わり方など、CoderDojo を中心にして色々なトピックまとめています。"
  end

  def using_scrivito?
    # TODO: There may be smarter detection
    USING_SCRIVITO
  end
end
