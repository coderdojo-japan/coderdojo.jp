xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title full_title ""
    xml.description full_description ""
    xml.link root_url

    @episodes.each do |episode|
      xml.item do
        xml.title episode.title
        xml.description episode.description
        xml.link @domainname + episode.url + ".mp3"
        xml.guid({:isPermaLink => "false"}, @domainname + episode.url)
      end
    end
  end
end