module Statistics
  class Aggregation
    def initialize(args)
      @mode = detect_mode(args[:from])
      @from = aggregation_from(args[:from])
      @to = aggregation_to(args[:to])
      @dojos = fetch_dojos
    end

    def run
      delete_event_histories

      "Statistics::Aggregation::#{@mode.camelize}".constantize.new(@dojos, @from, @to).run
    end

    private

    def detect_mode(from)
      if from
        if from.length == 4 || from.length == 6
          'monthly'
        else
          'weekly'
        end
      else
        'weekly'
      end
    end

    def aggregation_from(from)
      if from
        if from.length == 4
          date_from(from).beginning_of_year
        elsif from.length == 6
          date_from(from).beginning_of_month
        else
          date_from(from).beginning_of_week
        end
      else
        Time.current.prev_week.beginning_of_week
      end
    end

    def aggregation_to(to)
      if to
        if to.length == 4
          date_from(to).end_of_year
        elsif to.length == 6
          date_from(to).end_of_month
        else
          date_from(to).end_of_week
        end
      else
        Time.current.prev_week.end_of_week
      end
    end

    def date_from(str)
      formats = %w(%Y%m%d %Y/%m/%d %Y-%m-%d %Y%m %Y/%m %Y-%m)
      d = formats.map { |fmt|
        begin
          Time.zone.strptime(str, fmt)
        rescue ArgumentError
          Time.zone.local(str) if str.length == 4
        end
      }.compact.first

      raise ArgumentError, "Invalid format: `#{str}`, allow format is #{formats.push('%Y').join(' or ')}" if d.nil?

      d
    end

    def delete_event_histories
      EventHistory.where(evented_at: @from..@to).delete_all
    end

    def fetch_dojos
      DojoEventService.names.keys.each.with_object({}) do |name, hash|
        hash[name] = Dojo.eager_load(:dojo_event_services).where(dojo_event_services: { name: name }).to_a
      end
    end

    class Weekly
      def initialize(dojos, from, to)
        @dojos = dojos
        @list = build_list(from, to)
        @from = from
        @to = to
      end

      def run
        @list.each do |date|
          puts "Aggregate for #{date_format(date)}~#{date_format(date.end_of_week)}"

          @dojos.each do |kind, list|
            "Statistics::Tasks::#{kind.to_s.camelize}".constantize.new(list, date, true).run
          end
        end

        Notifier.notify_success(date_format(@from), date_format(@to))
      rescue => e
        Notifier.notify_failure(date_format(@from), date_format(@to), e)
      end

      private

      def build_list(from, to)
        loop.with_object([from]) do |_, list|
          nw = list.last.next_week
          raise StopIteration if nw > to
          list << nw
        end
      end

      def date_format(date)
        date.strftime('%Y/%m/%d')
      end
    end

    class Monthly
      def initialize(dojos, from, to)
        @dojos = dojos
        @list = build_list(from, to)
        @from = from
        @to = to
      end

      def run
        @list.each do |date|
          puts "Aggregate for #{date_format(date)}"

          @dojos.each do |kind, list|
            "Statistics::Tasks::#{kind.to_s.camelize}".constantize.new(list, date, false).run
          end
        end

        Notifier.notify_success(date_format(@from), date_format(@to))
      rescue => e
        Notifier.notify_failure(date_format(@from), date_format(@to), e)
      end

      private

      def build_list(from, to)
        loop.with_object([from]) do |_, list|
          nm = list.last.next_month
          raise StopIteration if nm > to
          list << nm
        end
      end

      def date_format(date)
        date.strftime('%Y/%m')
      end
    end

    class Notifier
      class << self
        def notify_success(from, to)
          notify("#{from}~#{to}のイベント履歴の集計を行いました")
        end

        def notify_failure(from, to, exception)
          notify("#{from}~#{to}のイベント履歴の集計でエラーが発生しました\n#{exception.message}")
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
          puts `curl --data-urlencode "source=#{msg}" -s #{idobata_hook_url} -o /dev/null -w "idobata: %{http_code}"` if notifierable?
        end
      end
    end
  end
end
