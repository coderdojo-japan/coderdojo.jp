require 'rails_helper'
require 'upcoming_events'
require 'event_service'

# 近日開催イベントの収集が、外部 API の一時的な不調で全体停止しないことを守るテスト。
#
# == 不具合の経緯（2026/08）==
# Doorkeeper API が 1 つのグループに対して 500 を返し、夜間の収集が止まった。
#
#   the server responded with status 500 for
#   GET https://api.doorkeeper.jp/groups/11839/events?...
#
# 影響は 1 道場にとどまらなかった。Doorkeeper 連携の 53 道場のうち、失敗した
# 道場は 4 番目に処理されており、それ以降の 50 道場のイベント情報が更新され
# なかった。API は後に 200 を返しており、一過性の障害だった。
#
# == 2 つの欠陥 ==
#   A. リトライ対象が 502/503/504 のみで、500 が含まれていなかった。
#      A を直せば、今回のような一過性の障害は収集を止めずに済む。
#   C. 例外を握り潰していたため、ジョブは成功扱いで終わり異常に気づけなかった。
#      通知が届かなければ気づく手段がない状態だった。
#
# 「1 道場の失敗で以降の道場を巻き込まない」という改修も検討したが、A で
# 一過性の障害を吸収できるため、恒久的な失敗が実際に起きるまでは見送る。
RSpec.describe '近日開催イベント収集の耐障害性' do
  # A. 一過性のサーバエラーはリトライする
  describe EventService::Providers::Doorkeeper do
    let(:responses) { [] }

    let(:stub_connection) do
      queue = responses.dup
      Faraday.new do |f|
        f.response :json, content_type: /\bjson$/
        f.response :raise_error, include_request: true
        f.adapter :test, Faraday::Adapter::Test::Stubs.new do |stub|
          stub.get(%r{/groups/\d+/events}) { queue.shift }
        end
      end
    end

    before do
      allow(EventService::Client).to receive(:new).and_return(
        EventService::Client.allocate.tap { |c| c.instance_variable_set(:@conn, stub_connection) }
      )
      # リトライの待機で時間を使わない
      allow_any_instance_of(described_class).to receive(:sleep)
    end

    let(:success) { [200, { 'Content-Type' => 'application/json' }, [].to_json] }

    [500, 502, 503, 504].each do |status|
      context "#{status} が返ったとき" do
        let(:responses) { [[status, {}, ''], success] }

        it 'リトライして回復する' do
          expect { described_class.new.fetch_events(group_id: 5555) }.not_to raise_error
        end
      end
    end

    context 'リトライしても回復しないとき' do
      let(:responses) { [[500, {}, ''], [500, {}, ''], [500, {}, '']] }

      it '例外を送出する' do
        expect { described_class.new.fetch_events(group_id: 5555) }.to raise_error(Faraday::ServerError)
      end
    end
  end

  # C. 収集に失敗したらジョブも失敗させる
  describe UpcomingEvents::Aggregation do
    include_context 'Use stubs UpcomingEvents for Connpass'
    include_context 'Use stubs UpcomingEvents for Doorkeeper'

    before do
      dojo = create(:dojo, name: 'Dojo', prefecture_id: 13)
      create(:dojo_event_service, dojo_id: dojo.id, name: :doorkeeper, group_id: 5555)
    end

    it '収集に失敗したら例外を送出する（ジョブを失敗させる）' do
      allow_any_instance_of(UpcomingEvents::Tasks::Doorkeeper)
        .to receive(:run).and_raise(StandardError, 'boom')

      expect { described_class.new(provider: 'doorkeeper').run }.to raise_error(StandardError, /boom/)
    end

    # rake タスクは全体を UpcomingEvent.transaction で囲んでいる。例外を握り潰すと
    # コミットされてしまい、「古いイベントは削除済み・新しいものは未取得」という
    # 中途半端な状態が残る。再送出すればロールバックされる。
    it '失敗時はロールバックされ、削除済みの古いイベントも巻き戻る' do
      service = DojoEventService.find_by(group_id: '5555')
      create(:upcoming_event, dojo_event_service_id: service.id, service_name: 'doorkeeper',
                              event_id: 'old', event_title: '過去のイベント',
                              event_at:     "#{Time.zone.today - 2.months} 10:00:00".in_time_zone,
                              event_end_at: "#{Time.zone.today - 2.months} 12:00:00".in_time_zone)

      allow_any_instance_of(UpcomingEvents::Tasks::Doorkeeper)
        .to receive(:run).and_raise(StandardError, 'boom')

      expect {
        begin
          UpcomingEvent.transaction { described_class.new(provider: 'doorkeeper').run }
        rescue StandardError
          # rake タスクと同じく、例外はトランザクションの外へ抜ける
        end
      }.not_to change { UpcomingEvent.count }
    end

    it '失敗しても通知は行う' do
      allow_any_instance_of(UpcomingEvents::Tasks::Doorkeeper)
        .to receive(:run).and_raise(StandardError, 'boom')

      expect(UpcomingEvents::Aggregation::Notifier).to receive(:notify_failure)
      expect { described_class.new(provider: 'doorkeeper').run }.to raise_error(StandardError)
    end
  end
end
