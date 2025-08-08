require 'rails_helper'
require 'event_service'

RSpec.describe EventService::Providers::Doorkeeper do
  include_context 'Use stubs for Doorkeeper'

  describe '#search' do
    subject { described_class.new.search(keyword: 'coderdojo') }

    it do
      expect(subject).to be_instance_of(Array)
      expect(subject.size).to eq 1
      expect(subject.first['event']['id']).to eq 1234
      expect(subject.first['event']['group']).to eq 5555
    end
  end

  describe '#fetch_events' do
    subject { described_class.new.fetch_events(group_id: 5555) }

    it do
      expect(subject).to be_instance_of(Array)
      expect(subject.size).to eq 1
      expect(subject.first[:id]).to eq 1234
      expect(subject.first[:group]).to eq 5555
    end
  end
end
