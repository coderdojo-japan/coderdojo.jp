require 'connpass_api_v2'

module EventService
  module Providers
      class Connpass
        def initialize
          @client = ConnpassApiV2.client(ENV['CONNPASS_API_KEY'])
        end

        def search(keyword:)
          @client.get_events(keyword: keyword, count: 100)
        end

        # NOTE: yyyymm, yyyymmdd は文字列を要素とする配列(Array[String])で指定
        def fetch_events(group_id:, yyyymm: nil, yyyymmdd: nil)
          group_id = group_id.join(',') if group_id.is_a?(Array)

          # API v1 -> v2 でパラメータ名が変更された
          # https://connpass.com/about/api/v2/
          # e.g. series_id -> group_id
          params = {
            group_id: group_id,
            start: 1,   # offset → start
            count: 100  # limit → count
          }

          param_period_patern = []
          if yyyymm
            yyyymm.each_slice(12) { |d| param_period_patern << { ym: d.join(',') } }
          end
          if yyyymmdd
            yyyymmdd.each_slice(10) { |d| param_period_patern << { ymd: d.join(',') } }
          end
          param_period_patern = [{}] if param_period_patern.blank?

          events = []

          param_period_patern.each do |param_period|
            loop do
              begin
                args = params.merge(param_period).compact
                res = @client.get_events(**args)
              rescue ConnpassApiV2::Error => e
                sleep 5 && retry if e.response&.status == 403

                raise e
              end

              break if res.results_returned.zero?

              events.push(*res.events)

              break if res.events.size < params[:count]

              break if params[:start] + params[:count] > res.results_available

              params[:start] += params[:count]
            end
          end

          events
        end
      end
  end
end
