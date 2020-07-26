require 'rails_helper'
require 'rake'

RSpec.describe 'podcasts', podcast: true do
  before(:all) do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require 'tasks/podcasts'
    Rake::Task.define_task(:environment)
  end

  before(:each) do
    @rake[task].reenable
  end

  def calc_duration(duration)
    (duration.to_time.to_i - Time.zone.today.to_time.to_i) * 1000
  end

  describe 'podcasts:upsert' do
    before :each do
      @episode = create(:podcast, track_id: 111001, title: 'podcast 001', duration: '00:16:40', permalink: 'podcast-001')
    end

    let(:task) { 'podcasts:upsert' }

    it 'successfuly fetch from SoundCloud RSS' do
      allow_any_instance_of(Podcast).to receive(:get).and_return(
        [
          { 'id'                    => 123456001,
            'title'                 => 'podcast title 001',
            'description'           => '説明 001',
            'original_content_size' => 124542711,
            'duration'              => 5189815,
            'user_id'               => 123456789,
            'permalink'             => 'podcast-001',
            'permalink_url'         => 'https://soundcloud.com/coderdojojp/podcast-001',
            'created_at'            => '2019/01/23 01:00:00 +0000' }
        ]
      )

      # before
      expect(Podcast.count).to eq(3)
      before_ids = Podcast.ids

      # exec
      expect(@rake[task].invoke).to be_truthy

      # after
      expect(Podcast.count).to eq(4)
      new_records = Podcast.where.not(id: before_ids)
      expect(new_records.count).to eq(1)

      expect(new_records.first.track_id).to eq(123456001)
      expect(new_records.first.uploaded_at).to eq('2019-01-23 10:00:00'.in_time_zone)

      expect(new_records.first.title).to eq('podcast title 001')
      expect(new_records.first.description).to eq('説明 001')
      expect(new_records.first.original_content_size).to eq(124542711)
      expect(new_records.first.duration).to eq(Time.at(5189815/1000).utc.strftime('%H:%M:%S'))
      expect(new_records.first.permalink).to eq('podcast-001')
      expect(new_records.first.permalink_url).to eq('https://soundcloud.com/coderdojojp/podcast-001')
      expect(new_records.first.published_date).to eq('2019-08-12'.to_date)
    end

    it 'failed to fetch from SoundCloud RSS' do
      allow_any_instance_of(Podcast).to receive(:get).and_return(
        [
          { 'id'                    => 123456001,
            'title'                 => 'podcast title 001',
            'description'           => '説明 001',
            'original_content_size' => 124542711,
            'duration'              => 5189815,
            'user_id'               => 123456789,
            'permalink'             => 'podcast-001',
            'permalink_url'         => 'https://soundcloud.com/coderdojojp/podcast-001',
            'created_at'            => '2019/01/23 01:00:00 +0000' }
        ]
      )

      # before
      expect(Podcast.count).to eq(3)
      before_ids = Podcast.ids

      # exec
      expect { @rake[task].invoke }.to raise_error('No Release Date')

      # after
      expect(Podcast.count).to eq(3)
      new_records = Podcast.where.not(id: before_ids)
      expect(new_records.count).to eq(0)
    end
  end
end
