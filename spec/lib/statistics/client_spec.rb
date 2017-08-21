require 'rails_helper'
require 'statistics'

RSpec.describe Statistics::Client do
  include_context 'Use stubs for Faraday'

  context 'Connpass' do
    describe '#search' do
      subject { Statistics::Client::Connpass.new.search(keyword: 'coderdojo') }

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
      subject { Statistics::Client::Connpass.new.fetch_events(series_id: 9876) }

      it do
        expect(subject).to be_instance_of(Array)
        expect(subject.size).to eq 1
        expect(subject.first['event_id']).to eq 12345
        expect(subject.first['series']['url']).to eq 'https://coderdojo-okutama.connpass.com/'
        expect(subject.first['series']['id']).to eq 9876
      end
    end
  end

  context 'Doorkeeper' do
    describe '#search' do
      subject { Statistics::Client::Doorkeeper.new.search(keyword: 'coderdojo') }

      it do
        expect(subject).to be_instance_of(Array)
        expect(subject.size).to eq 1
        expect(subject.first['event']['id']).to eq 1234
        expect(subject.first['event']['group']).to eq 5555
      end
    end

    describe '#fetch_events' do
      subject { Statistics::Client::Doorkeeper.new.fetch_events(group_id: 5555) }

      it do
        expect(subject).to be_instance_of(Array)
        expect(subject.size).to eq 1
        expect(subject.first['id']).to eq 1234
        expect(subject.first['group']).to eq 5555
      end
    end
  end
end
