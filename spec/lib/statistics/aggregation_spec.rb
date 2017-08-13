require 'rails_helper'
require 'statistics'

RSpec.describe Statistics::Aggregation do
  include_context 'Use stubs for Faraday'

  before(:all) do
    Dojo.delete_all
    DojoEventService.delete_all
    EventHistory.delete_all
  end

  after do
    Dojo.delete_all
    DojoEventService.delete_all
    EventHistory.delete_all
  end

  describe '.run' do
    before do
      d1 = Dojo.create(name: 'Dojo1', email: 'info@dojo1.com', description: 'CoderDojo1', tags: %w(CoderDojo1), url: 'https://dojo1.com')
      d2 = Dojo.create(name: 'Dojo2', email: 'info@dojo2.com', description: 'CoderDojo2', tags: %w(CoderDojo2), url: 'https://dojo2.com')
      DojoEventService.create(dojo_id: d1.id, name: 'connpass', group_id: 9876)
      DojoEventService.create(dojo_id: d2.id, name: 'doorkeeper', group_id: 5555)
    end

    subject { Statistics::Aggregation.run(date: Time.current) }

    it do
      expect{ subject }.to change{EventHistory.count}.from(0).to(2)
    end
  end
end
