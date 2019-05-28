require 'rails_helper'
require 'upcoming_events'

RSpec.describe UpcomingEvents::Aggregation do
  include_context 'Use stubs UpcomingEvents for Connpass'
  include_context 'Use stubs UpcomingEvents for Doorkeeper'

  describe '.run' do
    before do
      @d1 = create(:dojo, name: 'Dojo1', email: 'info@dojo1.com', description: 'CoderDojo1', tags: %w(CoderDojo1), url: 'https://dojo1.com')
      @d2 = create(:dojo, name: 'Dojo2', email: 'info@dojo2.com', description: 'CoderDojo2', tags: %w(CoderDojo2), url: 'https://dojo2.com')
      @es1 = create(:dojo_event_service, dojo_id: @d1.id, name: :connpass,   group_id: 9876)
      @es2 = create(:dojo_event_service, dojo_id: @d2.id, name: :doorkeeper, group_id: 5555)
    end

    it 'プロバイダ指定なし' do
      expect{ UpcomingEvents::Aggregation.new({}).run }.to change{ UpcomingEvent.count }.from(0).to(3)
    end

    it 'プロバイダ指定(connpass)' do
      expect{ UpcomingEvents::Aggregation.new(provider: 'connpass').run }.to change{ UpcomingEvent.count }.from(0).to(1)
    end

    it 'プロバイダ指定(doorkeeper)' do
      expect{ UpcomingEvents::Aggregation.new(provider: 'doorkeeper').run }.to change{ UpcomingEvent.count }.from(0).to(2)
    end

    it '昨日分までは削除' do
      create(:upcoming_event, dojo_event_service_id: @es1.id, service_name: 'connpass', event_id: '1111', event_at: "#{Time.zone.today - 3.days} 13:00:00".in_time_zone)
      create(:upcoming_event, dojo_event_service_id: @es1.id, service_name: 'connpass', event_id: '2222', event_at: "#{Time.zone.today - 2.days} 14:00:00".in_time_zone)
      create(:upcoming_event, dojo_event_service_id: @es1.id, service_name: 'connpass', event_id: '3333', event_at: "#{Time.zone.today - 1.days} 15:00:00".in_time_zone)
      create(:upcoming_event, dojo_event_service_id: @es2.id, service_name: 'doorkeeper', event_id: '4444', event_at: "#{Time.zone.today - 2.days} 10:00:00".in_time_zone)
      create(:upcoming_event, dojo_event_service_id: @es2.id, service_name: 'doorkeeper', event_id: '5555', event_at: "#{Time.zone.today - 1.days} 11:00:00".in_time_zone)

      expect{ UpcomingEvents::Aggregation.new({}).run }.to change{ UpcomingEvent.count }.from(5).to(3)
    end
  end
end
