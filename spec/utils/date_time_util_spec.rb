require 'rails_helper'

RSpec.describe DateTimeUtil do
  describe '.every_year_array' do
    let(:from) { Time.zone.local(2015, 1, 1) }
    let(:to) { Time.zone.local(2017, 12, 31) }
    subject { DateTimeUtil.every_year_array(from, to) }
    it do
      is_expected.to match_array([Time.zone.local(2015, 1, 1),
                                  Time.zone.local(2016, 1, 1),
                                  Time.zone.local(2017, 1, 1)])
    end
  end

  describe '.ever_month_array' do
    let(:from) { Time.zone.local(2017, 4, 2) }
    let(:to) { Time.zone.local(2017, 7, 1) }
    subject { DateTimeUtil.every_month_array(from, to) }
    it do
      is_expected.to match_array([Time.zone.local(2017, 4, 2),
                                  Time.zone.local(2017, 5, 2),
                                  Time.zone.local(2017, 6, 2)])
    end
  end

  describe '.ever_week_array' do
    let(:from) { Time.zone.local(2017, 9, 3) }
    let(:to) { Time.zone.local(2017, 9, 29) }
    subject { DateTimeUtil.every_week_array(from, to) }
    it do
      is_expected.to match_array([Time.zone.local(2017, 9, 3),
                                  Time.zone.local(2017, 9, 10),
                                  Time.zone.local(2017, 9, 17),
                                  Time.zone.local(2017, 9, 24)])
    end
  end

  describe '.ever_day_array' do
    let(:from) { Time.zone.local(2017, 11, 11) }
    let(:to) { Time.zone.local(2017, 11, 15) }
    subject { DateTimeUtil.every_day_array(from, to) }
    it do
      is_expected.to match_array([Time.zone.local(2017, 11, 11),
                                  Time.zone.local(2017, 11, 12),
                                  Time.zone.local(2017, 11, 13),
                                  Time.zone.local(2017, 11, 14),
                                  Time.zone.local(2017, 11, 15)])
    end
  end
end
