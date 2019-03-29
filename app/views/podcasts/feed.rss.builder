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

    xml.itunes :author,   @author
    xml.itunes :image,    :href => @art_work_url
    xml.itunes :type,     "episodic"
    xml.itunes :explicit, "clean"
    xml.itunes :owner do
      xml.itunes :name,  "Yohei Yasukawa"
      xml.itunes :email, "yohei@coderdojo.jp"
    end
    xml.itunes :category, :text => "Education" do
      xml.itunes :category, :text => "Educational Technology"
    end
    xml.itunes :category, :text => "Government &amp; Organizations" do
      xml.itunes :category, :text => "Non-Profit"
    end

    @episodes.each do |episode|
      description = ActionView::Base.full_sanitizer.sanitize(Kramdown::Document.new(episode.description, input: 'GFM').to_html).strip
      xml.item do
        xml.title        episode.title
        xml.author       @author
	xml.content      :encoded, description
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
