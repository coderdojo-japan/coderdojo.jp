module Statistics
  class Aggregation
    def initialize(args)
      @from, @to = aggregation_period(args[:from], args[:to])
      @provider = args[:provider]
      @dojo_id = args[:dojo_id].to_i if args[:dojo_id].present? && /\A\d+\Z/.match?(args[:dojo_id])

      dojos = fetch_dojos(@provider)
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
      Notifier.notify_success(date_format(@from), date_format(@to), @provider)
    rescue => e
      Notifier.notify_failure(date_format(@from), date_format(@to), @provider, e)
    end

    def delete_event_histories
      target_period = @from.beginning_of_day..@to.end_of_day
      (@externals.keys + @internals.keys).each do |kind|
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

    def date_format(date)
      date.strftime('%Y/%m/%d')
    end

    class Notifier
      class << self
        def notify_success(from, to, provider)
          notify("#{from}~#{to}#{provider_info(provider)}のイベント履歴の集計を行いました")
        end

        def notify_failure(from, to, provider, exception)
          notify("#{from}~#{to}#{provider_info(provider)}のイベント履歴の集計でエラーが発生しました\n#{exception.message}\n#{exception.backtrace.join("\n")}")
        end

        private

        def provider_info(provider)
          provider ? "(#{provider})" : nil
        end

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
