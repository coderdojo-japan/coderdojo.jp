require 'connpass_api_v2'

module EventService
  module Providers
      class Connpass
        # 制限が続く時に待ち続けると、ジョブが終わらず失敗にも気づけないので回数を区切る（5・10・15 秒）
        MAX_RETRIES_ON_TOO_MANY_REQUESTS = 3

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
            # ページ送りの位置は期間バッチごとに独立している。
            # 前のバッチの位置を引き継ぐと、このバッチの先頭のイベントを取りこぼす。
            params[:start] = 1

            loop do
              retry_count = 0
              begin
                args = params.merge(param_period).compact
                res = @client.get_events(**args)

                # APIキーごとに、現状「1秒間に1リクエストまで」 のリクエスト制限 (スロットリング) を設けています。
                # この制限を超過すると、HTTPステータスコード 429 Too Many Requests が返されます。
                # cf. https://connpass.com/about/api/v2/
                sleep 1
              # connpass_api_v2 は Faraday の raise_error をそのまま使うので、429 は Faraday の例外で上がる
              # （ConnpassApiV2::Error ではない。spec/lib/upcoming_events/resilience_spec.rb）
              rescue Faraday::TooManyRequestsError
                retry_count += 1
                raise if retry_count > MAX_RETRIES_ON_TOO_MANY_REQUESTS
                sleep 5 * retry_count
                retry
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
