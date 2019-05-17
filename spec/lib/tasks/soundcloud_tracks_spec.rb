require 'rails_helper'
require 'rake'

RSpec.describe 'soundcloud_tracks' do
  before(:all) do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require 'tasks/soundcloud_tracks'
    Rake::Task.define_task(:environment)
  end

  before(:each) do
    @rake[task].reenable
  end

  def calc_duration(duration)
    (duration.to_time.to_i - Time.zone.today.to_time.to_i) * 1000
  end

  describe 'soundcloud_tracks:upsert' do
    before :each do
      @sct_1 = create(:soundcloud_track, track_id: 111001, title: 'podcast 001', duration: '00:16:40', permalink: 'podcast-001')
      @sct_2 = create(:soundcloud_track, track_id: 111002, title: 'podcast 002', duration: '00:33:20', permalink: 'podcast-002')
      @sct_3 = create(:soundcloud_track, track_id: 111003, title: 'podcast 003', duration: '00:50:00', permalink: 'podcast-003')
    end

    let(:task) { 'soundcloud_tracks:upsert' }

    it '単純追加' do
      allow_any_instance_of(SoundCloud::Client).to receive(:get).and_return(
        [
          { 'id'                    => 123456001,
            'created_at'            => '2019/01/23 01:00:00 +0000',
            'description'           => '説明 001',
            'original_content_size' => 124542711,
            'title'                 => 'podcast title 001',
            'duration'              => 5189815,
            'original_format'       => 'mp3',
            'tag_list'              => 'coderdojo',
            'genre'                 => 'Technology',
            'download_url'          => 'https://api.soundcloud.com/tracks/123456001/download',
            'last_modified'         => '2019/01/24 03:00:00 +0000',
            'uri'                   => 'https://api.soundcloud.com/tracks/123456001',
            'attachments_uri'       => 'https://api.soundcloud.com/tracks/123456001/attachments',
            'license'               => 'cc-by-nc-sa',
            'user_id'               => 123456789,
            'permalink'             => 'podcast-001',
            'permalink_url'         => 'https://soundcloud.com/coderdojojp/podcast-001' }
        ]
      )

      # before
      expect(SoundCloudTrack.count).to eq(3)
      before_ids = SoundCloudTrack.ids

      # exec
      expect(@rake[task].invoke).to be_truthy

      # after
      expect(SoundCloudTrack.count).to eq(4)
      new_records = SoundCloudTrack.where.not(id: before_ids)
      expect(new_records.count).to eq(1)

      expect(new_records.first.track_id).to eq(123456001)
      expect(new_records.first.uploaded_at).to eq('2019-01-23 10:00:00'.in_time_zone)

      expect(new_records.first.title).to eq('podcast title 001')
      expect(new_records.first.description).to eq('説明 001')
      expect(new_records.first.original_content_size).to eq(124542711)
      expect(new_records.first.duration).to eq(Time.at(5189815/1000).utc.strftime('%H:%M:%S'))
      expect(new_records.first.tag_list).to eq('coderdojo')
      expect(new_records.first.download_url).to eq('https://api.soundcloud.com/tracks/123456001/download')
      expect(new_records.first.permalink).to eq('podcast-001')
      expect(new_records.first.permalink_url).to eq('https://soundcloud.com/coderdojojp/podcast-001')
    end

    it '単純更新' do
      allow_any_instance_of(SoundCloud::Client).to receive(:get).and_return(
        [
          { 'id'                    => @sct_2.track_id,
            'created_at'            => '2019/01/23 01:00:00 +0000',
            'description'           => 'podcast 説明 002',
            'original_content_size' => 124542711,
            'title'                 => 'podcast title 002',
            'duration'              => 6000000,
            'original_format'       => 'mp3',
            'tag_list'              => 'coderdojo',
            'genre'                 => 'Technology',
            'download_url'          => 'https://api.soundcloud.com/tracks/123456001/download',
            'last_modified'         => '2019/01/24 03:00:00 +0000',
            'uri'                   => 'https://api.soundcloud.com/tracks/123456001',
            'attachments_uri'       => 'https://api.soundcloud.com/tracks/123456001/attachments',
            'license'               => 'cc-by-nc-sa',
            'user_id'               => 123456789,
            'permalink'             => 'podcast-002',
            'permalink_url'         => 'https://soundcloud.com/coderdojojp/podcast-002' }
        ]
      )

      # before
      expect(SoundCloudTrack.count).to eq(3)

      # exec
      expect(@rake[task].invoke).to be_truthy

      # after
      expect(SoundCloudTrack.count).to eq(3)
      mod_record = SoundCloudTrack.find_by(track_id: @sct_2.track_id)
      expect(mod_record.title).to eq('podcast title 002')
      expect(mod_record.description).to eq('podcast 説明 002')
      expect(mod_record.duration).to eq(Time.at(6000000/1000).utc.strftime('%H:%M:%S'))
    end

    it '複数 (追加/更新)' do
      allow_any_instance_of(SoundCloud::Client).to receive(:get).and_return(
        [
          { 'id'                    => @sct_2.track_id,
            'created_at'            => @sct_2.uploaded_at.to_s,
            'description'           => @sct_2.description,
            'original_content_size' => @sct_2.original_content_size,
            'title'                 => 'podcast 002 mod',
            'duration'              => calc_duration(@sct_2.duration),
            'tag_list'              => @sct_2.tag_list,
            'download_url'          => @sct_2.download_url,
            'permalink'             => @sct_2.permalink,
            'permalink_url'         => @sct_2.permalink_url },
          { 'id'                    => 123456001,
            'created_at'            => '2019/01/23 01:00:00 +0000',
            'description'           => '説明 001',
            'original_content_size' => 124542711,
            'title'                 => 'podcast title 001',
            'duration'              => 5189815,
            'tag_list'              => 'coderdojo',
            'download_url'          => 'https://api.soundcloud.com/tracks/123456001/download',
            'permalink'             => 'podcast-004',
            'permalink_url'         => 'https://soundcloud.com/coderdojojp/podcast-004' },
          { 'id'                    => @sct_1.track_id,
            'created_at'            => @sct_1.uploaded_at.to_s,
            'description'           => @sct_1.description,
            'original_content_size' => @sct_1.original_content_size,
            'title'                 => 'podcast 001 mod',
            'duration'              => calc_duration(@sct_1.duration),
            'tag_list'              => @sct_1.tag_list,
            'download_url'          => @sct_1.download_url,
            'permalink'             => @sct_1.permalink,
            'permalink_url'         => @sct_1.permalink_url },
          { 'id'                    => @sct_3.track_id,
            'created_at'            => @sct_3.uploaded_at.to_s,
            'description'           => @sct_3.description,
            'original_content_size' => @sct_3.original_content_size,
            'title'                 => 'podcast 003 mod',
            'duration'              => calc_duration(@sct_3.duration),
            'tag_list'              => @sct_3.tag_list,
            'download_url'          => @sct_3.download_url,
            'permalink'             => @sct_3.permalink,
            'permalink_url'         => @sct_3.permalink_url }
          ]
      )

      # before
      expect(SoundCloudTrack.count).to eq(3)
      before_ids = SoundCloudTrack.ids

      # exec
      expect(@rake[task].invoke).to be_truthy

      # after
      expect(SoundCloudTrack.count).to eq(4)
      new_records = SoundCloudTrack.where.not(id: before_ids)
      expect(new_records.count).to eq(1)
      expect(new_records.first.track_id).to eq(123456001)

      after_sct_1 = SoundCloudTrack.find_by(id: @sct_1.id)
      expect(after_sct_1.track_id).to eq(111001)
      expect(after_sct_1.title).to eq('podcast 001 mod')
      expect(calc_duration(after_sct_1.duration)).to eq(1000000)

      after_sct_2 = SoundCloudTrack.find_by(id: @sct_2.id)
      expect(after_sct_2.track_id).to eq(111002)
      expect(after_sct_2.title).to eq('podcast 002 mod')
      expect(calc_duration(after_sct_2.duration)).to eq(2000000)

      after_sct_3 = SoundCloudTrack.find_by(id: @sct_3.id)
      expect(after_sct_3.track_id).to eq(111003)
      expect(after_sct_3.title).to eq('podcast 003 mod')
      expect(calc_duration(after_sct_3.duration)).to eq(3000000)
    end
  end
end
