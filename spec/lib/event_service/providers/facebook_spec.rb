require 'rails_helper'
require 'eventservice'

RSpec.describe EventService::Providers::Facebook do
  include_context 'Use stubs for Facebook'

  describe '#fetch_events' do
    subject { described_class.new.fetch_events(group_id: 123451234512345) }

    it do
      expect(subject).to be_instance_of(Array)
      expect(subject.size).to eq 1
      expect(subject.first['id']).to eq '125500978166443'
      expect(subject.first.dig('owner', 'id')).to eq '123451234512345'
    end
  end
end
