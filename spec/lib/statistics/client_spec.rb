require 'rails_helper'
require 'statistics'

RSpec.describe Statistics::Client do
  context 'Doorkeeper' do
    include_context 'Use stubs for Doorkeeper'

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

  context 'Facebook' do
    include_context 'Use stubs for Facebook'

    describe '#fetch_events' do
      subject { Statistics::Client::Facebook.new.fetch_events(group_id: 123451234512345) }

      it do
        expect(subject).to be_instance_of(Array)
        expect(subject.size).to eq 1
        expect(subject.first['id']).to eq '125500978166443'
        expect(subject.first.dig('owner', 'id')).to eq '123451234512345'
      end
    end
  end
end
