module Statistics
  class Aggregation
    def initialize(args)
      @from, @to = aggregation_period(args[:from], args[:to])
      dojos = fetch_dojos
      @externals = dojos[:externals]
      @internals = dojos[:internals]
    end

    def run
      puts "Aggregate for #{@from}~#{@to}"
      with_notifying do
        delete_event_histories
        execute
        execute_once
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

      [from_date, to_date]
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

    def fetch_dojos
      {
        externals: find_dojos_by(DojoEventService::EXTERNAL_SERVICES),
        internals: find_dojos_by(DojoEventService::INTERNAL_SERVICES)
      }
    end

    def find_dojos_by(services)
      services.each.with_object({}) do |name, hash|
        hash[name] = Dojo.eager_load(:dojo_event_services).where(dojo_event_services: { name: name }).to_a
      end
    end

    def with_notifying
      yield
      Notifier.notify_success(date_format(@from), date_format(@to))
    rescue => e
      Notifier.notify_failure(date_format(@from), date_format(@to), e)
    end

    def delete_event_histories
      target_period = @from.beginning_of_day..@to.end_of_day
      (@externals.keys + @internals.keys).each do |kind|
        "Statistics::Tasks::#{kind.to_s.camelize}".constantize.delete_event_histories(target_period)
      end
    end

    def execute
      target_period = @from..@to
      @externals.each do |kind, list|
        puts "Aggregate of #{kind}"
        "Statistics::Tasks::#{kind.to_s.camelize}".constantize.new(list, target_period).run
      end
    end

    def execute_once
      @internals.each do |kind, list|
        puts "Aggregate of #{kind}"
        "Statistics::Tasks::#{kind.to_s.camelize}".constantize.new(list, nil).run
      end
    end

    def date_format(date)
      date.strftime('%Y/%m/%d')
    end

    class Notifier
      class << self
        def notify_success(from, to)
          notify("#{from}~#{to}のイベント履歴の集計を行いました")
        end

        def notify_failure(from, to, exception)
          notify("#{from}~#{to}のイベント履歴の集計でエラーが発生しました\n#{exception.message}\n#{exception.backtrace.join("\n")}")
        end

        private

        def idobata_hook_url
          return @idobata_hook_url if defined?(@idobata_hook_url)
          @idobata_hook_url = ENV['IDOBATA_HOOK_URL']
        end

        def notifierable?
          idobata_hook_url.present?
        end

        def notify(msg)
          $stdout.puts msg
          puts `curl --data-urlencode "source=#{msg}" -s #{idobata_hook_url} -o /dev/null -w "idobata: %{http_code}"` if notifierable?
        end
      end
    end
  end
end
