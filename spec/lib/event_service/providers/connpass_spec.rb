require 'rails_helper'
require 'event_service'

RSpec.describe EventService::Providers::Connpass do
  include_context 'Use stubs for Connpass'

  describe '#search' do
    subject { described_class.new.search(keyword: 'coderdojo') }

    it do
      expect(subject).to be_a(ConnpassApiV2::Response)
      expect(subject.results_returned).to eq 100
      expect(subject.events).to be_a(Array)
    end
  end

  describe '#fetch_events' do
    context 'when a single group_id is given' do
      subject { described_class.new.fetch_events(group_id: 9876) }

      it do
        expect(subject).to be_a(Array)
        expect(subject.size).to eq 4
      end
    end

    context 'when multiple group_ids are given' do
      subject { described_class.new.fetch_events(group_id: [9876, 9877]) }

      it do
        expect(subject).to be_a(Array)
        expect(subject.size).to eq 5
      end
    end
  end
end
