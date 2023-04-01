require 'rails_helper'
require 'event_service'

RSpec.describe EventService::Providers::Facebook do
  describe '#fetch_events' do
    before :each do
      allow(YAML).to receive(:load_file).and_return(
        [
         { "dojo_id" => 5555, "participants" => 1, "evented_at" => "2018/10/01 10:30" },
         { "dojo_id" => 5555, "participants" => 1, "evented_at" => "2018/11/01 10:30" },
         { "dojo_id" => 5555, "participants" => 1, "evented_at" => "2018/12/01 10:30" },
         { "dojo_id" => 5555, "participants" => 1, "evented_at" => "2019/01/01 10:30" },
         { "dojo_id" => 5555, "participants" => 1, "evented_at" => "2019/02/01 10:30" },
         { "dojo_id" => 6666, "participants" => 1, "evented_at" => "2018/10/01 14:00" },
         { "dojo_id" => 6666, "participants" => 1, "evented_at" => "2018/11/01 14:00" },
         { "dojo_id" => 6666, "participants" => 1, "evented_at" => "2018/12/01 14:00" },
         { "dojo_id" => 6666, "participants" => 1, "evented_at" => "2019/01/01 14:00" },
         { "dojo_id" => 6666, "participants" => 1, "evented_at" => "2019/02/01 14:00" },
         { "dojo_id" => 7777, "participants" => 1, "evented_at" => "2018/10/01 17:00" },
         { "dojo_id" => 7777, "participants" => 1, "evented_at" => "2018/11/01 17:00" },
         { "dojo_id" => 7777, "participants" => 1, "evented_at" => "2018/12/01 17:00" },
         { "dojo_id" => 7777, "participants" => 1, "evented_at" => "2019/01/01 17:00" },
         { "dojo_id" => 7777, "participants" => 1, "evented_at" => "2019/02/01 17:00" }
        ]
      )
    end

    subject { described_class.new.fetch_events(**@params) }

    it 'dojo_id: nil, since_at: nil, until_at: nil => all' do
      @params = {}

      expect(subject).to be_instance_of(Array)
      expect(subject.size).to eq 15
    end

    it 'dojo_id: integer, since_at: nil, until_at: nil' do
      @params = { dojo_id: 5555 }

      expect(subject).to be_instance_of(Array)
      expect(subject.size).to eq 5
    end

    it 'dojo_id: array, since_at: nil, until_at: nil' do
      @params = { dojo_id: [5555, 7777] }

      expect(subject).to be_instance_of(Array)
      expect(subject.size).to eq 10
    end

    it 'dojo_id: nil, since_at: specify, until_at: nil' do
      @params = { since_at: '2018-12-01 0:00'.in_time_zone }

      expect(subject).to be_instance_of(Array)
      expect(subject.size).to eq 9
    end

    it 'dojo_id: nil, since_at: nil, until_at: specify' do
      @params = { until_at: '2019-01-31 0:00'.in_time_zone }

      expect(subject).to be_instance_of(Array)
      expect(subject.size).to eq 12
    end

    it 'dojo_id: nil, since_at: specify, until_at: specify' do
      @params = { since_at: '2018-12-01 0:00'.in_time_zone, until_at: '2019-01-31 0:00'.in_time_zone }

      expect(subject).to be_instance_of(Array)
      expect(subject.size).to eq 6
    end
  end
end
