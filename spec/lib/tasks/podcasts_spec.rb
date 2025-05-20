require 'rails_helper'
require 'rake'

RSpec.describe 'DojoCast:', podcast: true do
  before(:all) do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require 'tasks/podcasts'
    Rake::Task.define_task(:environment)
  end

  before(:each) do
    @rake[task].reenable
  end

  describe 'podcasts:upsert' do
    before :each do
      Podcast.destroy_all
      @episode = create(:podcast,
                 title:     '999 - podcast 999',
                 duration:  '00:16:40',
                 permalink: 'podcast-999',
                 enclosure_url:  'https://aaa.bbb/title.mp3',
)
    end

    let(:task) { 'podcasts:upsert' }

    it 'successfuly fetch from RSS (mock)' do
      # RSSのモック
      rss_content = <<~RSS
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <item>
              <title>001 - 日本の CoderDojo の成り立ち</title>
              <description>jishihaの説明文</description>
              <link>https://anchor.fm/coderdojo-japan/episodes/001----CoderDojo-euhits</link>
              <pubDate>Sat, 25 Mar 2017 00:00:00 GMT</pubDate>
              <enclosure url="https://example.com/podcast.mp3" length="22887860" type="audio/mpeg"/>
              <itunes:duration>2857</itunes:duration>
            </item>
          </channel>
        </rss>
      RSS

      # RSS::Parserのモック
      rss_parser = instance_double(RSS::Rss)
      rss_item = instance_double(RSS::Rss::Channel::Item)
      allow(rss_item).to receive(:title).and_return('001 - 日本の CoderDojo の成り立ち')
      allow(rss_item).to receive(:description).and_return('jishihaの説明文')
      allow(rss_item).to receive(:link).and_return('https://anchor.fm/coderdojo-japan/episodes/001----CoderDojo-euhits')
      allow(rss_item).to receive(:pubDate).and_return(Time.parse('2017-03-25'))
      allow(rss_item).to receive(:enclosure).and_return(
        instance_double(RSS::Rss::Channel::Item::Enclosure, url: 'https://example.com/podcast.mp3', length: 22887860)
      )
      allow(rss_item).to receive(:itunes_duration).and_return(double(content: '2857', to_s: '2857'))
      allow(rss_parser).to receive(:items).and_return([rss_item])
      allow(RSS::Parser).to receive(:parse).and_return(rss_parser)

      # before
      expect(Podcast.count).to eq(1)
      before_ids = Podcast.ids

      # exec
      expect(@rake[task].invoke).to be_truthy

      # after
      expect(Podcast.count).not_to eq(1)
      new_records = Podcast.where.not(id: before_ids)
      expect(new_records.count).to eq(1)
      first_track = new_records.first

      expect(first_track.title).to          eq('001 - 日本の CoderDojo の成り立ち')
      expect(first_track.description).to    start_with('jishiha')
      expect(first_track.content_size).to   eq(22887860)
      expect(first_track.duration).to       eq('2857')
      expect(first_track.permalink).to      eq('001----CoderDojo-euhits')
      expect(first_track.permalink_url).to  eq('https://anchor.fm/coderdojo-japan/episodes/001----CoderDojo-euhits')
      expect(first_track.published_date).to eq('2017-03-25'.to_date)
    end

    it 'failed to fetch from Anchor.fm RSS' do
      allow_any_instance_of(Podcast).to receive(:id).and_return(
        [
          { 'id'            => 123456001,
            'title'         => 'podcast title 001',
            'description'   => '説明 001',
            'content_size'  => 124542711,
            'duration'      => 5189815,
            'user_id'       => 123456789,
            'permalink'     => 'podcast-001',
            'permalink_url' => 'https://anchor.fm/coderdojo-japan/999-title',
            'created_at'    => '2019/01/23 01:00:00 +0000' }
        ]
      )

      # before
      expect(Podcast.count).to eq(1)
      before_ids = Podcast.ids

      # after
      expect(Podcast.count).to eq(1)
      new_records = Podcast.where.not(id: before_ids)
      expect(new_records.count).to eq(0)
    end
  end
end
