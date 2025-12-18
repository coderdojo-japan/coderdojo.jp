require 'rails_helper'
require 'statistics'

RSpec.describe Statistics::Aggregation do
  include_context 'Use stubs for Connpass'
  include_context 'Use stubs for Doorkeeper'

  before(:each) do
    Dojo.destroy_all
  end

  after do
    Dojo.destroy_all
  end

  describe '.run' do
    let(:yaml_provider) { instance_double(EventService::Providers::StaticYaml) }

    before do
      d1 = create(:dojo, name: 'Dojo1', email: 'info@dojo1.example.com', description: 'CoderDojo1', tags: %w(CoderDojo1), url: 'https://example.com/dojo1', prefecture_id: 13)
      d2 = create(:dojo, name: 'Dojo2', email: 'info@dojo2.example.com', description: 'CoderDojo2', tags: %w(CoderDojo2), url: 'https://example.org/dojo2', prefecture_id: 13)
      create(:dojo_event_service, dojo_id: d1.id, name: :connpass, group_id: 9876)
      create(:dojo_event_service, dojo_id: d2.id, name: :doorkeeper, group_id: 5555)

      create(:dojo, id: 194, name: 'Dojo194', email: 'info@dojo194.example.com', description: 'CoderDojo194', tags: %w(CoderDojo194), url: 'https://example.com/dojo194', prefecture_id: 13)
      allow(EventService::Providers::StaticYaml).to receive(:new).and_return(yaml_provider)
      allow(yaml_provider).to receive(:fetch_events).and_return([
        { 'dojo_id' => 194, 'event_url' => 'https://example.com/event/12345', 'evented_at' => '2023-12-10 14:00', 'participants' => 1 }
      ])
    end

    subject { Statistics::Aggregation.new(from: Time.zone.today.prev_month.strftime('%Y%m')).run }

    it do
      expect{ subject }.to change{ EventHistory.count }.from(0).to(2)
    end
  end

  describe 'private' do
    let(:sa) { Statistics::Aggregation.new(from: '-', to: '-') }

    context 'aggregation_period(from, to)' do
      it 'from/to 指定あり' do
        today = Time.zone.today
        list = [
          [{ from: '-', to: '-'},                ['2012-01-01'.to_date, Time.zone.yesterday]],
          [{ from: '2017',     to: '2018' },     ['2017-01-01'.to_date, '2018-12-31'.to_date]],
          [{ from: '2018',     to: '201801' },   ['2018-01-01'.to_date, '2018-01-31'.to_date]],
          [{ from: '2018',     to: '20180203' }, ['2018-01-01'.to_date, '2018-02-03'.to_date]],
          [{ from: '201802',   to: '2018' },     ['2018-02-01'.to_date, '2018-12-31'.to_date]],
          [{ from: '201803',   to: '201804' },   ['2018-03-01'.to_date, '2018-04-30'.to_date]],
          [{ from: '201805',   to: '20180607' }, ['2018-05-01'.to_date, '2018-06-07'.to_date]],
          [{ from: '20180809', to: '2018' },     ['2018-08-09'.to_date, '2018-12-31'.to_date]],
          [{ from: '20180810', to: '201811' },   ['2018-08-10'.to_date, '2018-11-30'.to_date]],
          [{ from: '20180811', to: '20181213' }, ['2018-08-11'.to_date, '2018-12-13'.to_date]],
          [{ from: today.year.to_s, to: today.next_year.year.to_s },                           [today.beginning_of_year, today.yesterday]],
          [{ from: today.strftime('%Y%m'), to: today.next_month.strftime('%Y%m') },            [today.beginning_of_month, today.yesterday]],
          [{ from: today.prev_day.strftime('%Y%m%d'), to: today.next_day.strftime('%Y%m%d') }, [today.yesterday, today.yesterday]]
        ]

        list.each do |d|
          expect(sa.send(:aggregation_period, d[0][:from], d[0][:to])).to eq(d[1])
        end
      end

      it 'from のみ指定あり' do
        today = Time.zone.today
        list = [
          [{ from: '2018',     to: nil }, ['2018-01-01'.to_date, '2018-12-31'.to_date]],
          [{ from: '201810',   to: nil }, ['2018-10-01'.to_date, '2018-10-31'.to_date]],
          [{ from: '20181215', to: nil }, ['2018-12-15'.to_date, '2018-12-15'.to_date]],
        ]

        list.each do |d|
          expect(sa.send(:aggregation_period, d[0][:from], d[0][:to])).to eq(d[1])
        end
      end

      it 'to のみ指定あり' do
        list = [
          [{ from: nil, to: '2018' },     ['2018-01-01'.to_date, '2018-12-31'.to_date]],
          [{ from: nil, to: '201810' },   ['2018-10-01'.to_date, '2018-10-31'.to_date]],
          [{ from: nil, to: '20181215' }, ['2018-12-15'.to_date, '2018-12-15'.to_date]],
        ]

        list.each do |d|
          expect(sa.send(:aggregation_period, d[0][:from], d[0][:to])).to eq(d[1])
        end
      end

      it 'to/from 共に指定なし' do
        expect(sa.send(:aggregation_period, nil, nil)).to eq([Time.zone.today.prev_week.beginning_of_week, Time.zone.today.prev_week.end_of_week])
      end
    end

    context 'date_from(str)' do
      it 'normal' do
        list = [['2019',       '2019-01-01'.to_date],
                ['20180203',   '2018-02-03'.to_date],
                ['2018/04/05', '2018-04-05'.to_date],
                ['2018-06-07', '2018-06-07'.to_date],
                ['201808',     '2018-08-01'.to_date],
                ['2018/09',    '2018-09-01'.to_date],
                ['2018-10',    '2018-10-01'.to_date]]

        list.each do |d|
          expect(sa.send(:date_from, d[0])).to eq(d[1])
        end
      end

      it 'raise' do
        expect{ sa.send(:date_from, 'abc') }.to raise_error(ArgumentError)
      end
    end

    context 'fetch_dojos(provider)' do
      it '指定なし' do
        dojos = sa.send(:fetch_dojos, nil)
        expect(dojos[:externals].keys).to eq(DojoEventService::EXTERNAL_SERVICES)
        expect(dojos[:internals].keys).to eq(DojoEventService::INTERNAL_SERVICES)
      end

      it 'connpass' do
        dojos = sa.send(:fetch_dojos, 'connpass')
        expect(dojos[:externals].keys).to eq(['connpass'])
        expect(dojos[:internals].keys).to eq([])
      end

      it 'doorkeeper' do
        dojos = sa.send(:fetch_dojos, 'doorkeeper')
        expect(dojos[:externals].keys).to eq(['doorkeeper'])
        expect(dojos[:internals].keys).to eq([])
      end

      it 'facebook' do
        dojos = sa.send(:fetch_dojos, 'facebook')
        expect(dojos[:externals].keys).to eq(['facebook'])
        expect(dojos[:internals].keys).to eq([])
      end

      it 'static_yaml' do
        dojos = sa.send(:fetch_dojos, 'static_yaml')
        expect(dojos[:externals].keys).to eq([])
        expect(dojos[:internals].keys).to eq(['static_yaml'])
      end

      it 'other' do
        dojos = sa.send(:fetch_dojos, 'abc')
        expect(dojos[:externals].keys).to eq([])
        expect(dojos[:internals].keys).to eq([])
      end
    end

    context 'find_dojos_by(services)' do
      before :each do
        @d1 = create(:dojo, name: 'Dojo1', email: 'info@dojo1.example.com', description: 'CoderDojo1', tags: %w(CoderDojo1), url: 'https://example.com/dojo1', prefecture_id: 13)
        @d2 = create(:dojo, name: 'Dojo2', email: 'info@dojo2.example.com', description: 'CoderDojo2', tags: %w(CoderDojo2), url: 'https://example.org/dojo2', prefecture_id: 13)
        @d3 = create(:dojo, name: 'Dojo3', email: 'info@dojo3.example.com', description: 'CoderDojo3', tags: %w(CoderDojo3), url: 'https://example.net/dojo3', prefecture_id: 13)
        @d4 = create(:dojo, name: 'Dojo4', email: 'info@dojo4.example.com', description: 'CoderDojo4', tags: %w(CoderDojo4), url: 'https://example.com/dojo4', prefecture_id: 13)
        create(:dojo_event_service, dojo_id: @d1.id, name: :connpass,   group_id: 9876)
        create(:dojo_event_service, dojo_id: @d2.id, name: :doorkeeper, group_id: 5555)
        create(:dojo_event_service, dojo_id: @d2.id, name: :connpass,   group_id: 9877)
        create(:dojo_event_service, dojo_id: @d3.id, name: :doorkeeper, group_id: 5556)
        create(:dojo_event_service, dojo_id: @d4.id, name: :facebook,   group_id: 10000)
      end

      it 'dojo_id 指定なし' do
        result = sa.send(:find_dojos_by, DojoEventService::EXTERNAL_SERVICES)
        expect(result[:connpass].size).to eq(2)
        expect(result[:connpass].map { |d| d.id }.sort).to eq([@d1.id, @d2.id].sort)
        expect(result[:doorkeeper].size).to eq(2)
        expect(result[:doorkeeper].map { |d| d.id }.sort).to eq([@d2.id, @d3.id].sort)
        expect(result[:facebook].size).to eq(1)
        expect(result[:facebook].map { |d| d.id }).to eq([@d4.id])
      end

      it 'dojo_id 指定あり' do
        sa.instance_variable_set(:@dojo_id, @d2.id)
        result = sa.send(:find_dojos_by, DojoEventService::EXTERNAL_SERVICES)
        expect(result[:connpass].size).to eq(1)
        expect(result[:connpass].map { |d| d.id }).to eq([@d2.id])
        expect(result[:doorkeeper].size).to eq(1)
        expect(result[:doorkeeper].map { |d| d.id }).to eq([@d2.id])
        expect(result[:facebook].size).to eq(0)
      end
    end
  end
end
