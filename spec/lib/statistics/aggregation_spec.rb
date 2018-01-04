require 'rails_helper'
require 'statistics'

RSpec.describe Statistics::Aggregation do
  include_context 'Use stubs for Connpass'
  include_context 'Use stubs for Doorkeeper'
  include_context 'Use stubs for Facebook'

  before(:all) do
    Dojo.destroy_all
  end

  after do
    Dojo.destroy_all
  end

  describe '.run' do
    before do
      d1 = Dojo.create(name: 'Dojo1', email: 'info@dojo1.com', description: 'CoderDojo1', tags: %w(CoderDojo1), url: 'https://dojo1.com')
      d2 = Dojo.create(name: 'Dojo2', email: 'info@dojo2.com', description: 'CoderDojo2', tags: %w(CoderDojo2), url: 'https://dojo2.com')
      d3 = Dojo.create(name: 'Dojo3', email: 'info@dojo3.com', description: 'CoderDojo3', tags: %w(CoderDojo3), url: 'https://dojo3.com')
      DojoEventService.create(dojo_id: d1.id, name: :connpass, group_id: 9876)
      DojoEventService.create(dojo_id: d2.id, name: :doorkeeper, group_id: 5555)
      DojoEventService.create(dojo_id: d3.id, name: :facebook, group_id: 123451234512345)
    end

    subject { Statistics::Aggregation.run(date: Time.current, weekly: false) }

    it do
      expect{ subject }.to change{EventHistory.count}.from(0).to(3)
    end
  end
end
