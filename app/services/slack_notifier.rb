require "net/http"
require "uri"
require "json"

class SlackNotifier
  # Webhook が消された・無効になった時は、例外ではなく 2xx 以外の応答が返る
  class DeliveryError < StandardError; end

  class << self
    # @param message [String] 通知するメッセージ
    # @param webhook_url [String] SlackのWebhook URL
    # @return [Boolean] 送信成功なら true / 失敗なら false
    def post_message(message, webhook_url)
      return false if webhook_url.blank?

      uri = URI.parse(webhook_url)

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = { text: message.to_s }.to_json

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 5,
        read_timeout: 5
      ) { |http| http.request(request) }

      Rails.logger.info("Slack通知レスポンスコード: #{response.code}")
      return true if response.code.to_i.between?(200, 299)

      Rails.error.report(DeliveryError.new("Slack通知が #{response.code} で拒否されました"))
      false
    rescue StandardError => e
      Rails.logger.warn("Slack通知エラー: #{e.class} #{e.message}")
      Rails.error.report(e)
      false
    end
  end
end
