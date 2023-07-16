require 'rails_helper'
require 'event_service'

RSpec.describe EventService::Providers::Connpass do
  include_context 'Use stubs for Connpass'

  describe '#search' do
    subject { described_class.new.search(keyword: 'coderdojo') }

    it do
      expect(subject).to be_instance_of(Hash)
      expect(subject['results_returned']).to eq 1
      expect(subject['events'].size).to eq 1
      expect(subject['events'].first['event_id']).to eq 12345
      expect(subject['events'].first['series']['url']).to eq 'https://coderdojo-okutama.connpass.com/'
      expect(subject['events'].first['series']['id']).to eq 9876
    end
  end

  describe '#fetch_events' do
    context 'when a single series_id is given' do
      subject { described_class.new.fetch_events(series_id: 9876) }

      it do
        expect(subject).to be_instance_of(Array)
        expect(subject.size).to eq 1
        expect(subject.first['event_id']).to eq 12345
        expect(subject.first['series']['url']).to eq 'https://coderdojo-okutama.connpass.com/'
        expect(subject.first['series']['id']).to eq 9876
      end
    end

    context 'when multiple series_ids are given' do
      subject { described_class.new.fetch_events(series_id: [9876, 9877]) }

      it do
        expect(subject).to be_instance_of(Array)
        expect(subject.size).to eq 2
        expect(subject.first['event_id']).to eq 12345
        expect(subject.first['series']['url']).to eq 'https://coderdojo-okutama.connpass.com/'
        expect(subject.first['series']['id']).to eq 9876
        expect(subject.second['event_id']).to eq 12346 # assuming the second event has id 12346
        expect(subject.second['series']['url']).to eq 'https://coderdojo-okutama2.connpass.com/'
        expect(subject.second['series']['id']).to eq 9877
      end
    end
  end
end
