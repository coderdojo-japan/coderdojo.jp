module DojoHelper
  def dojo_count_label(count)
    if count == 1
      "#{count} Dojo"
    else
      "#{count} Dojos"
    end
  end

  def total_dojos_count(dojos)
    dojos.sum(&:counter)
  end

  # 道場のノート欄でリンクを保持しながらテキストを切り詰める
  def truncate_with_preserved_links(text, length: 60)
    return text if text.blank?

    # まずリンクを自動検出してHTMLに変換（target="_blank"を追加）
    html_with_links = Rinku.auto_link(text, :all, 'target="_blank"')

    # HTMLをパースする
    doc = Nokogiri::HTML::DocumentFragment.parse(html_with_links)

    # リンクの表示テキストを簡略化（href属性は保持）
    doc.css('a').each do |link|
      display_text = link.text
      # http://, https:// を削除（\A で文字列の先頭のみマッチ）
      display_text = display_text.gsub(/\Ahttps?:\/\//, '')
      # 末尾のスラッシュを削除（\z で文字列の末尾のみマッチ）
      display_text = display_text.gsub(/\/\z/, '')
      link.content = display_text
    end

    # 表示用のテキストの長さを計算
    visible_text = doc.text

    # 切り詰める必要がない場合は変更後のHTMLを返す
    return doc.to_html.html_safe if visible_text.length <= length

    # 切り詰める必要がある場合
    result = ""
    current_length = 0

    doc.children.each do |node|
      if node.text?
        # 通常のテキストノード
        remaining_length = length - current_length
        if node.content.length > remaining_length
          result += node.content[0, remaining_length] + "..."
          break
        else
          result         += node.content
          current_length += node.content.length
        end
      elsif node.name == 'a'
        # リンクノード
        link_text = node.text
        remaining_length = length - current_length

        if link_text.length > remaining_length
          # リンクのテキスト部分を切り詰める（href属性とtarget属性を保持）
          truncated_text = link_text[0, remaining_length] + "..."
          result += %Q(<a href="#{node['href']}" target="_blank">#{truncated_text}</a>)
          break
        else
          result += node.to_html
          current_length += link_text.length
        end
      else
        # その他のHTMLノード
        node_text = node.text
        remaining_length = length - current_length

        if node_text.length > remaining_length
          # このノード内でも切り詰めが必要
          result += node.text[0, remaining_length] + "..."
          break
        else
          result += node.to_html
          current_length += node_text.length
        end
      end

      break if current_length >= length
    end

    result.html_safe
  end
end
