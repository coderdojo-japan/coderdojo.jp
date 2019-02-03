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
    subject { described_class.new.fetch_events(series_id: 9876) }

    it do
      expect(subject).to be_instance_of(Array)
      expect(subject.size).to eq 1
      expect(subject.first['event_id']).to eq 12345
      expect(subject.first['series']['url']).to eq 'https://coderdojo-okutama.connpass.com/'
      expect(subject.first['series']['id']).to eq 9876
    end
  end
end
