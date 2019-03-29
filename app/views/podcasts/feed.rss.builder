xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0",
        "xmlns:atom"   => "http://www.w3.org/2005/Atom",
        "xmlns:itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd",
        "xmlns:media"  => "http://search.yahoo.com/mrss/",
        "xmlns:dc"     => "http://purl.org/dc/elements/1.1/" do
  xml.channel do
    xml.title       @title
    xml.description @description
    xml.link        root_url
    xml.copyright   @copyright
    xml.language    "ja"

    xml.atom :link, :href => "https://dojocast.superfeedr.com/",
                    :rel  => "hub"
    xml.atom :link, :href => "https://coderdojo.jp/podcasts.rss",
                    :rel  => "self",
                    :type => "application/rss+xml"
    xml.media :thumbnail, :url => @art_work_url
    xml.media :keywords, "programming,education,opensource,community,coderdojo,software,development"
    xml.media :category, "Technology", :scheme => "http://www.itunes.com/dtds/podcast-1.0.dtd"

    xml.itunes :author,   @author
    xml.itunes :keywords, "programming,education,opensource,community,coderdojo,software,development"
    xml.itunes :subtitle, @description
    xml.itunes :summary,  "CoderDojo コミュニティに関わる方々をハイライトする教育系ポッドキャストです。"
    xml.itunes :image,    :href => @art_work_url
    xml.itunes :explicit, "no"
    xml.itunes :owner do
      xml.itunes :name,  "Yohei Yasukawa"
      xml.itunes :email, "yohei@coderdojo.jp"
    end
    xml.itunes :category, :text => "Education"

    @episodes.each do |episode|
      description = ActionView::Base.full_sanitizer.sanitize(Kramdown::Document.new(episode.description, input: 'GFM').to_html).strip
      xml.item do
        xml.title        episode.title
	xml.description  description
        xml.link         "#{@base_url}#{episode.url}"
        xml.guid({:isPermaLink => "false"}, "#{@base_url}#{episode.url}")
        xml.itunes       :explicit, "clean"
        xml.pubDate       episode.published_at.rfc2822
        xml.enclosure({
	  :url    => "#{@base_url}#{episode.url}.mp3",
	  :length => episode.filesize,
	  :type   => "audio/mpeg"}
	)
        xml.itunes       :duration, episode.duration
      end
    end
  end
end
