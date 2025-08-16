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
    
    # まずリンクを自動検出してHTMLに変換
    html_with_links = Rinku.auto_link(text)
    
    # HTMLをパースする
    doc = Nokogiri::HTML::DocumentFragment.parse(html_with_links)
    
    # 表示用のテキストの長さを計算
    visible_text = doc.text
    
    if visible_text.length <= length
      # 切り詰める必要がない場合はそのまま返す
      return html_with_links.html_safe
    end
    
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
          result += node.content
          current_length += node.content.length
        end
      elsif node.name == 'a'
        # リンクノード
        link_text = node.text
        remaining_length = length - current_length
        
        if link_text.length > remaining_length
          # リンクのテキスト部分を切り詰める（href属性は保持）
          truncated_text = link_text[0, remaining_length] + "..."
          result += %Q(<a href="#{node['href']}">#{truncated_text}</a>)
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
