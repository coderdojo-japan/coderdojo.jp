module EventService
  module Providers
      class Connpass
        ENDPOINT = 'https://connpass.com/api/v1'.freeze
        # NOTE: 期間は ym or ymd パラメータで指定(複数指定可能)、未指定時全期間が対象

        def initialize
          @client = EventService::Client.new(ENDPOINT)
        end

        def search(keyword:)
          @client.get('event/', { keyword: keyword, count: 100 })
        end

        # NOTE: yyyymm, yyyymmdd は文字列を要素とする配列(Array[String])で指定
        def fetch_events(series_id:, yyyymm: nil, yyyymmdd: nil)
          params = {
            series_id: series_id,
            start: 1,
            count: 100
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
              # connpass は https://connpass.com/robots.txt を守らない場合は、アクセス制限を施すので、下記の sleep を入れるようにした https://connpass.com/about/api/
              sleep 5
              part = @client.get('event/', params.merge(param_period))

              break if part['results_returned'].zero?

              events.push(*part.fetch('events'))

              break if part.size < params[:count]

              break if params[:start] + params[:count] > part['results_available']

              params[:start] += params[:count]
            end
          end

          events
        end
      end
  end
end
