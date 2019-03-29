xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0", "xmlns:itunes" => "http://www.itunes.com/dtds/Podcast-1.0.dtd" do
  xml.channel do
    xml.title       @title
    xml.description @description
    xml.link        root_url
    xml.image       @art_work_url
    xml.author      @author
    xml.copyright   @copyright
    xml.language    "ja"
    xml.itunes :category, :text => "Technology" do
      xml.itunes :category, :text => "Software How-To"
      xml.itunes :category, :text => "Podcasting"
    end
    xml.itunes :type,     "serial"
    xml.itunes :explicit, "clean"

    @episodes.each do |episode|
      xml.item do
        xml.title        episode.title
        xml.author       @author
	xml.description  CGI.escapeHTML(episode.description)
        xml.link         "#{@base_url}#{episode.url}"
        xml.guid({:isPermaLink => "false"}, "#{@base_url}#{episode.url}")
        xml.itunes       :explicit, "clean"
        xml.published_at episode.published_at.rfc2822
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
