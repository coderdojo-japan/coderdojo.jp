module Statistics
  # イベント履歴の集計が「静かに壊れていないか」を確認する。
  #
  # connpass API v1 -> v2 でレスポンスのキーが変わった際、集計側の追随が漏れ、
  # 例外もエラーも出ないまま 14 か月ぶんのイベント履歴が欠損していた（PR #1845）。
  # テストは緑のままで、人間が /stats の数字を見て初めて気づいた。
  #
  # 「以前は取得できていたのに、直近はまったく取得できていない」プロバイダは、
  # 実態としてあり得ない。集計が壊れているサインとして扱い、定期実行を失敗させる。
  class SanityCheck
    class StaleDataError < StandardError; end

    # 既定の 30 日は、実データから決めた。connpass は 30 日あたり約 90 件、
    # doorkeeper は約 25 件を記録しており、30 日間 0 件は実態としてあり得ない。
    def initialize(days: 30)
      @days = days
    end

    def run
      stale = stale_providers

      if stale.empty?
        puts "直近 #{@days} 日のイベント履歴を確認しました（問題なし）"
        return
      end

      raise StaleDataError,
            "#{stale.join(', ')} のイベント履歴が、直近 #{@days} 日で 1 件も記録されていません。" \
            '集計が壊れている可能性があります（過去には記録されています）。'
    end

    # 直前の @days 日には記録があったのに、直近の @days 日は 0 件のプロバイダ。
    #
    # 「過去に 1 件でもあれば対象」としてはいけない。廃止済みの facebook（2024年以降 0 件）や、
    # 手動でしか追加されない static_yaml（間隔が空く）を毎回フラグしてしまい、
    # 警告が無視されるようになる。「直前まで動いていたものが、急に止まった」だけを見る。
    def stale_providers
      DojoEventService.distinct.pluck(:name).select do |provider|
        recorded_in?(provider, previous_period) && !recorded_in?(provider, recent_period)
      end
    end

    private

    def recent_period
      @days.days.ago..
    end

    def previous_period
      (@days * 2).days.ago...@days.days.ago
    end

    def recorded_in?(provider, period)
      EventHistory.for(provider).where(evented_at: period).exists?
    end
  end
end
