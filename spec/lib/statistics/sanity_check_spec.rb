require 'rails_helper'
require 'statistics'

# connpass の集計が API v2 のキー変更で壊れた時、例外もエラーも出ないまま
# 14 か月ぶんのイベント履歴が欠損していた（PR #1845）。テストは緑のままで、
# 人間が統計の数字を見て初めて気づいた。
#
# 同じ「静かな欠損」を機械的に検知するため、「以前は取得できていたのに、
# 直近はまったく取得できていないプロバイダ」を洗い出す。
RSpec.describe Statistics::SanityCheck do
  let(:dojo) { create(:dojo, name: 'Dojo1', prefecture_id: 13) }

  before do
    create(:dojo_event_service, dojo_id: dojo.id, name: :connpass, group_id: 9876)
  end

  def create_event(service_name, evented_at, event_id)
    EventHistory.create!(
      dojo_id:          dojo.id,
      dojo_name:        dojo.name,
      service_name:     service_name,
      service_group_id: '9876',
      event_id:         event_id,
      event_url:        "https://example.com/events/#{event_id}",
      participants:     1,
      evented_at:       evented_at
    )
  end

  describe '#stale_providers' do
    it '直前の期間には取得できていたのに、直近が 0 件のプロバイダを検知する' do
      create_event('connpass', 100.days.ago, '1')

      expect(described_class.new(days: 60).stale_providers).to eq(['connpass'])
    end

    it '直近も取得できていれば検知しない' do
      create_event('connpass', 100.days.ago, '1')
      create_event('connpass',  10.days.ago, '2')

      expect(described_class.new(days: 60).stale_providers).to be_empty
    end

    it 'イベントが 1 件も無いプロバイダは検知しない' do
      create(:dojo_event_service, dojo_id: dojo.id, name: :facebook, group_id: 10_000)

      expect(described_class.new(days: 60).stale_providers).to be_empty
    end

    # 廃止済みの facebook（2024年以降 0 件）や、手動でしか追加されない static_yaml を
    # 毎回フラグすると、警告が無視されるようになる。実データで誤検知したケース。
    it 'ずっと前に止まったプロバイダは検知しない（直前の期間も 0 件のため）' do
      create(:dojo_event_service, dojo_id: dojo.id, name: :facebook, group_id: 10_000)
      create_event('facebook', 2.years.ago, 'fb1')

      expect(described_class.new(days: 60).stale_providers).to be_empty
    end
  end

  describe '#run' do
    it '検知したら例外を投げて、定期実行のジョブを失敗させる' do
      create_event('connpass', 100.days.ago, '1')

      expect { described_class.new(days: 60).run }
        .to raise_error(Statistics::SanityCheck::StaleDataError, /connpass/)
    end

    it '問題がなければ例外を投げない' do
      create_event('connpass', 10.days.ago, '1')

      expect { described_class.new(days: 60).run }.not_to raise_error
    end
  end
end
