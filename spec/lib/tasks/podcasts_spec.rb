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

    # TODO: This test is flaky? It seems fails depending on Internet and should work offline.
    xit 'successfuly fetch from Anchor.fm RSS' do
      allow_any_instance_of(Podcast).to receive(:id).and_return(
        [
          { 'id'            => 123456001,
            'title'         => '999 - podcast title',
            'description'   => '説明 999',
            'content_size'  => 124542711,
            'duration'      => 5189815,
            'user_id'       => 123456789,
            'permalink'     => '999-title',
            'permalink_url' => 'https://anchor.fm/coderdojo-japan/999-title',
            'created_at'    => '2099/01/23 01:00:00 +0000' }
        ]
      )

      # before
      expect(Podcast.count).to eq(1)
      before_ids = Podcast.ids

      # exec
      expect(@rake[task].invoke).to be_truthy

      # after
      expect(Podcast.count).not_to eq(1)
      new_records = Podcast.where.not(id: before_ids)
      expect(new_records.count).not_to eq(1)
      first_track = new_records.find(1)

      expect(first_track.title).to          eq('001 - 日本の CoderDojo の成り立ち')
      expect(first_track.description).to    start_with('jishiha')
      expect(first_track.content_size).to   eq(22887860)
      expect(first_track.duration).to       eq('2857')      # eq('00:47:37')
      expect(first_track.permalink).to      eq('001----CoderDojo-euhits') # eq('999-title')
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
