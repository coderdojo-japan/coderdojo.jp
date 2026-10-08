xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom' do
  xml.channel do
    xml.title       strip_tags(@title)
    xml.description strip_tags(@desc)
    xml.link        full_url(news_index_path)
    xml.language    'ja'
    xml.atom :link, href: full_url(news_index_path(format: :rss)), rel: 'self', type: 'application/rss+xml'

    @news_items.each do |news|
      xml.item do
        # link_url は DojoCast の URL を相対パスにするため、RSS では絶対 URL の url を使う
        xml.title   news.formatted_title
        xml.link    news.url
        xml.guid    news.url, isPermaLink: 'true'
        xml.pubDate news.published_at.rfc2822
      end
    end
  end
end
