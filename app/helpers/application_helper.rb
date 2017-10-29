# -*- coding: utf-8 -*-
module ApplicationHelper
  def full_title(page_title)
    base_title = "CoderDojo Japan"
    if page_title.empty?
      "CoderDojo Japan - 子どものためのプログラミング道場"
    else
      "#{page_title} - #{base_title}"
    end
  end

  def full_url(page_url)
    default_url = "https://coderdojo.jp/"
    if page_url.empty?
      default_url
    else
      page_url
    end
  end

  def meta_description(description)
    if description.empty?
      "CoderDojo は子どものためのプログラミング道場です。2011年にアイルランドで始まり、全国では#{Dojo::NUM_OF_JAPAN_DOJOS}ヶ所以上、世界では#{Dojo::NUM_OF_COUNTRIES}ヶ国・#{Dojo::NUM_OF_WHOLE_DOJOS}ヶ所で開催されています。"
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
