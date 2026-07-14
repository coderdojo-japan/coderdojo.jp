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

    # 期間が 12 か月を超えると ym は複数のバッチに分割される。
    # バッチごとに start を 1 に戻さないと、2 つ目以降のバッチが
    # 前のバッチのページ送り位置から始まり、イベントを丸ごと取りこぼす。
    context 'when the period is split into multiple batches' do
      let(:full_page) do
        events = Array.new(100) do |i|
          { 'url' => "https://example.com/event/#{i}/", 'id' => i, 'accepted' => 1,
            'started_at' => '2025-05-07T10:00:00+09:00', 'group' => { 'id' => 9876 } }
        end
        { 'results_returned' => 100, 'results_available' => 150, 'results_start' => 1, 'events' => events }
      end

      it 'restarts pagination from the beginning for each batch' do
        requested_starts = []
        allow_any_instance_of(ConnpassApiV2::Client).to receive(:get_events) do |_client, **args|
          requested_starts << args[:start]
          ConnpassApiV2::Response.new(full_page)
        end

        yyyymm = (0..13).map { |i| (Time.zone.local(2025, 1, 1) + i.months).strftime('%Y%m') }
        described_class.new.fetch_events(group_id: 9876, yyyymm: yyyymm)

        # ym は 12 か月 + 2 か月の 2 バッチに分かれるので、start=1 の要求が 2 回あるはず
        expect(requested_starts.count(1)).to eq(2),
          "各バッチの先頭で start=1 になるべきですが、実際の start は #{requested_starts.inspect} でした"
      end
    end
  end
end
