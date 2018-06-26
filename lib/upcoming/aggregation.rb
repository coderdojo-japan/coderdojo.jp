module Upcoming
  class Aggregation
    def initialize(args)
      @from = TimeWithZone.beginning_of_week
      @to = TimeWithZone.next_month
      @dojos = fetch_dojos
    end

    def run
      Upcoming::Aggregation::Monthly.new(@dojos, @from, @to).run
    end

    private

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

    class Base
      def initialize(dojos, from, to)
        @externals = dojos[:externals]
        @internals = dojos[:internals]
        @list = build_list(from, to)
        @from = from
        @to = to
      end

      def run
        with_notifying do
          delete_upcoming_event
          execute
          execute_once
        end
      end

      private

      def with_notifying
        yield
        Notifier.notify_success(date_format(@from), date_format(@to))
      rescue => e
        Notifier.notify_failure(date_format(@from), date_format(@to), e)
      end

      def delete_upcoming_event
        (@externals.keys + @internals.keys).each do |kind|
          "Upcoming::Tasks::#{kind.to_s.camelize}".constantize.delete_upcoming_event
        end
      end

      def execute
        raise NotImplementedError.new("You must implement #{self.class}##{__method__}")
      end

      def execute_once
        @internals.each do |kind, list|
          "Upcoming::Tasks::#{kind.to_s.camelize}".constantize.new(list, nil).run
        end
      end

      def build_list(_from, _to)
        raise NotImplementedError.new("You must implement #{self.class}##{__method__}")
      end

      def date_format(_date)
        raise NotImplementedError.new("You must implement #{self.class}##{__method__}")
      end
    end

    class Monthly < Base
      private

      def execute
        @list.each do |date|
          puts "Aggregate for #{date_format(date)}"

          @externals.each do |kind, list|
            "Upcoming::Tasks::#{kind.to_s.camelize}".constantize.new(list, date).run
          end
        end
      end

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
          notify("#{from}~#{to}のイベント登録を行いました")
        end

        def notify_failure(from, to, exception)
          notify("#{from}~#{to}のイベント登録でエラーが発生しました\n#{exception.message}\n#{exception.backtrace.join("\n")}")
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
