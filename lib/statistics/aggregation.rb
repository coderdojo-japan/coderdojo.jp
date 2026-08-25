module Statistics
  class Aggregation
    # 外部プロバイダをこの日数より前に遡って再集計することを禁じる。
    # 週次ジョブが遡るのは高々 13 日で、欠損に気付いてから復旧するまでの遅延を
    # 足しても数週間に収まる。ガード自身の日付計算がずれても週次ジョブを
    # 止めないよう、正当な遡りとの間に余裕を持たせている。
    REAGGREGATION_LIMIT_DAYS = 90

    def initialize(args)
      @from, @to = aggregation_period(args[:from], args[:to])
      @provider  = args[:provider]
      @dojo_id   = args[:dojo_id].to_i if args[:dojo_id].present? && /\A\d+\Z/.match?(args[:dojo_id])

      # TODO: internal service が動いてなさそう? 現在 CI/CD で実行されている
      # $ rails statistics:aggregation 実行時に以下のコマンドも実行されるようにしたい。
      # $ rails statistics:aggregation\[-,-,static_yaml\]
      dojos = fetch_dojos(@provider)
      @externals = dojos[:externals]
      @internals = dojos[:internals]
    end

    def run
      dojo_info = "[#{@dojo_id}]" if @dojo_id
      puts "Aggregate for #{@from}~#{@to}#{dojo_info}"
      with_notifying do
        # DB にも API にも触れる前に落とす
        forbid_destructive_reaggregation!

        # 「削除だけが確定し、再登録されない」状態を残さないため、全体を1つの
        # トランザクションにまとめる。呼び出し側に任せると rails console から
        # 直接呼んだときに原子性が失われる。
        # cf. https://github.com/coderdojo-japan/coderdojo.jp/pull/1881
        EventHistory.transaction do
          delete_event_histories(@externals.keys)
          execute
          # static_yaml は期間を問わず全件を入れ替えるため、削除と再登録を隣接させる。
          # 先に削除すると、外部プロバイダの失敗に巻き込まれて履歴が丸ごと消える。
          delete_event_histories(@internals.keys)
          execute_once
        end
      end
    end

    private

    def aggregation_period(from, to)
      return ['2012-01-01'.to_date, Time.zone.yesterday] if from == '-' && to == '-'
      if from.nil? && to.nil?
        return [Time.zone.today.prev_week.beginning_of_week, Time.zone.today.prev_week.end_of_week]
      end

      from ||= to
      from_date = case from&.length
                  when 4    then date_from(from).beginning_of_year
                  when 6,7  then date_from(from).beginning_of_month
                  when 8,10 then date_from(from)
                  end

      to ||= from
      to_date = case to&.length
                when 4    then date_from(to).end_of_year
                when 6,7  then date_from(to).end_of_month
                when 8,10 then date_from(to)
                end

      [from_date, [to_date, Time.zone.yesterday].min]
    end

    def date_from(str)
      formats = %w(%Y%m%d %Y/%m/%d %Y-%m-%d %Y%m %Y/%m %Y-%m %Y)
      d = formats.map { |fmt|
        begin
          Date.strptime(str, fmt)
        rescue
          nil
        end
      }.compact.first

      raise ArgumentError, "Invalid format: `#{str}`, allow format is #{formats.join(' or ')}" if d.nil?

      d
    end

    def fetch_dojos(provider)
      if provider.blank?
        # 全プロバイダ対象
        external_services = DojoEventService::EXTERNAL_SERVICES
        internal_services = DojoEventService::INTERNAL_SERVICES
      else
        external_services = []
        internal_services = []
        case provider
        when 'connpass', 'doorkeeper', 'facebook'
          external_services = [provider]
        when 'static_yaml'
          internal_services = [provider]
        end
      end

      {
        externals: find_dojos_by(external_services),
        internals: find_dojos_by(internal_services)
      }
  end

    def find_dojos_by(services)
      services.each.with_object({}) do |name, hash|
        dojos = Dojo.eager_load(:dojo_event_services).where(dojo_event_services: { name: name })
        dojos = dojos.where(id: @dojo_id) if @dojo_id
        hash[name] = dojos.to_a
      end
    end

    def with_notifying
      yield
      Notifier.notify_success(date_format(@from), date_format(@to), @provider, @dojo_id)
    rescue => e
      # 通知したうえで再送出し、週次ジョブを失敗させる。握り潰すと、データが
      # 欠けたまま正常終了したように見える。
      # cf. https://github.com/coderdojo-japan/coderdojo.jp/pull/1881
      #
      # Slack への通知自体が失敗しても、元の例外を失わないようにする。
      begin
        Notifier.notify_failure(date_format(@from), date_format(@to), @provider, @dojo_id, e)
      rescue => notification_error
        $stdout.puts "Failed to notify: #{notification_error.message}"
      end
      raise e
    end

    # 集計は「対象期間の履歴を削除してから API で取り直す」ため、API から消えた
    # イベントは復活しない。閉鎖した道場が connpass のグループごとページを削除して
    # いると、実際に開催された履歴が失われる。古い期間ほどその危険が大きい。
    #
    # static_yaml は db/static_event_histories.yml が正史なので対象外。
    # facebook は実装上 YAML を読むだけだが、外部プロバイダとして扱われている
    # 分類の歪みをここに持ち込まないため、あえて特別扱いしない。
    # cf. doc/how_to_aggregate_stats_and_events.md
    def forbid_destructive_reaggregation!
      return if @externals.empty?
      return if @from >= Time.zone.today - REAGGREGATION_LIMIT_DAYS.days

      raise ArgumentError, <<~MESSAGE
        #{date_format(@from)} からの再集計を中止しました（#{REAGGREGATION_LIMIT_DAYS} 日より前のため）。

        API から消えたイベントは再集計で復活せず、実際に開催された履歴が失われます。
        欠損を直したいときは、該当する週だけを指定してください。
        例: rails 'statistics:aggregation[#{date_format(Time.zone.today.prev_week.beginning_of_week)},#{date_format(Time.zone.today.prev_week.end_of_week)}]'
      MESSAGE
    end

    def delete_event_histories(kinds)
      target_period = @from.beginning_of_day..@to.end_of_day
      kinds.each do |kind|
        "Statistics::Tasks::#{kind.to_s.camelize}".constantize.delete_event_histories(target_period, @dojo_id)
      end
    end

    def execute
      target_period = @from..@to
      @externals.each do |kind, list|
        if @dojo_id
          puts "Aggregate of #{kind}[#{@dojo_id}]"
        else
          puts "Aggregate of #{kind}"
        end
        "Statistics::Tasks::#{kind.to_s.camelize}".constantize.new(list, target_period).run
      end
    end

    def execute_once
      @internals.each do |kind, list|
        puts "Aggregate of #{kind}"
        "Statistics::Tasks::#{kind.to_s.camelize}".constantize.new(list, nil).run
      end
    end

    # ISO 8601 で揃える。通知文にも、通知が添える再実行コマンドにも使う。
    # rake タスクの引数は %Y-%m-%d を受け付けるので、そのままコピペできる。
    def date_format(date)
      date.strftime('%Y-%m-%d')
    end

    class Notifier
      class << self
        def notify_success(from, to, provider, dojo_id)
          notify("#{from}~#{to}#{provider_info(provider)}#{dojo_info(dojo_id)}のイベント履歴の集計を行いました")
        end

        def notify_failure(from, to, provider, dojo_id, exception)
          # 期間を指定せずに再実行すると「実行時点の前週」を集計するため、翌週以降に
          # 再実行しても欠けた週は埋まらない。再実行するコマンドを添える。
          # cf. https://github.com/coderdojo-japan/coderdojo.jp/pull/1881
          # zsh では [] がグロブとして解釈されるため、引用符ごとコピペできる形にする
          retry_command = "rails 'statistics:aggregation[#{from},#{to}#{",#{provider}" if provider}]'"
          notify("#{from}~#{to}#{provider_info(provider)}#{dojo_info(dojo_id)}のイベント履歴の集計でエラーが発生しました\n" \
                 "原因を直したあと、期間を指定して再実行してください: #{retry_command}\n" \
                 "#{exception.message}\n#{exception.backtrace.join("\n")}")
        end

        private

        def provider_info(provider)
          provider ? "(#{provider})" : nil
        end

        def dojo_info(dojo_id)
          dojo_id ? "[#{dojo_id}]" : nil
        end

        def slack_hook_url
          @slack_hook_url ||= ENV['SLACK_HOOK_URL']
        end

        def notifierable?
          slack_hook_url.present?
        end

        def notify(msg)
          $stdout.puts msg
          SlackNotifier.post_message(msg, slack_hook_url) if notifierable?
        end
      end
    end
  end
end
