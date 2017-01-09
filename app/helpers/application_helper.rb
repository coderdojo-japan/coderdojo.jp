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

  def meta_description(description)
    if description.empty?
      "CoderDojo は子どものためのプログラミング道場です。2011年にアイルランドで始まり、全国では70ヶ所以上、世界では66ヶ国・1,150ヶ所で開催されています。"
    else
      description
    end
  end
end
