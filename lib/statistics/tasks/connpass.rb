module Statistics
  module Tasks
    class Connpass
      # MEMO: Duck Typing (COOL!!)
      #       This method is called as general provider in `lib/statistics/aggregation.rb`
      def self.delete_event_histories(period, dojo_id)
        histories = EventHistory.for(:connpass).within(period)
        histories = histories.where(dojo_id: dojo_id) if dojo_id
        histories.delete_all
      end

      def initialize(dojos, period)
        @client = EventService::Providers::Connpass.new
        @dojos  = dojos
        @params = build_params(period)
      end

      def run
        group_ids = @dojos.flat_map do |dojo|
          dojo.dojo_event_services.for(:connpass).pluck(:group_id)
        end

        @client.fetch_events(**@params.merge(group_id: group_ids)).each do |e|
          # API v1 -> v2 でイベントの所属グループを表すキーが series -> group に変わった
          # cf. https://connpass.com/about/api/v2/
          dojo_event_service = DojoEventService.find_by(group_id: e.dig('group', 'id').to_s)
          next unless dojo_event_service

          # 道場がイベントページを作り直さずに開催日だけ変更すると、集計期間の外に
          # 残った履歴と event_id が衝突して集計が止まる。作成ではなく更新にして
          # 開催日の変更に追随する。
          history = EventHistory.find_or_initialize_by(service_name: dojo_event_service.name,
                                                       event_id:     e.fetch('id').to_s)
          history.update!(dojo_id:          dojo_event_service.dojo_id,
                          dojo_name:        dojo_event_service.dojo.name,
                          service_group_id: dojo_event_service.group_id,
                          event_url:        e.fetch('url'),
                          participants:     e.fetch('accepted'),
                          evented_at:       Time.zone.parse(e.fetch('started_at')))
        end
      end

      private

      def build_params(period)
        yyyymmdd = []
        yyyymm   = []

        st_date = period.first
        ed_date = period.last

        date = period.first
        while date <= ed_date
          if date.day == 1 && date.end_of_month <= ed_date
            yyyymm << date.strftime('%Y%m')
            date += 1.month
          else
            yyyymmdd << date.strftime('%Y%m%d')
            date += 1.day
          end
        end

        {
          yyyymmdd: yyyymmdd,
          yyyymm:   yyyymm
        }
      end
    end
  end
end
