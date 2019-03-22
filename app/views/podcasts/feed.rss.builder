xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0", "xmlns:itunes" => "http://www.itunes.com/dtds/Podcast-1.0.dtd" do
  xml.channel do
    xml.title full_title ""
    xml.description full_description ""
    xml.link root_url
    xml.author @author
    xml.copyright "Copyright © 2012-2018 一般社団法人 CoderDojo Japan"
    xml.language "ja"
    xml.itunes :category, :text => "Technology" do
      xml.itunes :category, :text => "Software How-To"
      xml.itunes :category, :text => "Podcasting"
    end
    xml.itunes :type, "serial"
    xml.itunes :explicit, "clean"

    @episodes.each do |episode|
      xml.item do
        xml.title episode.title
        xml.author @author
        xml.description episode.description
        xml.link @domainname + episode.url
        xml.guid({:isPermaLink => "false"}, @domainname + episode.url)
        xml.itunes :explicit, "clean"
        xml.pubDate episode.published_at.rfc2822
        xml.enclosure({:url => @domainname + episode.url + ".mp3", :length => episode.filesize, :type => "audio/mpeg"})
        xml.itunes :duration, episode.duration
      end
    end
  end
end
