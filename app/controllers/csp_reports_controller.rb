# ブラウザが送る CSP の違反の報告を受けて、ログに 1 行で残す（config/initializers/csp.rb）。
# 報告は誰でも送れるので、読む量に上限を付け、値は JSON に直して改行を埋め込ませない
class CspReportsController < ActionController::Base
  skip_forgery_protection

  MAX_BODY_BYTES = 8.kilobytes
  FIELDS         = %w(document-uri effective-directive violated-directive blocked-uri source-file line-number script-sample).freeze

  def create
    report = JSON.parse(request.body.read(MAX_BODY_BYTES).to_s)['csp-report']
    Rails.logger.info("[CSP] #{report.slice(*FIELDS).transform_values { it.to_s[0, 200] }.to_json}") if report.is_a?(Hash)
  rescue JSON::ParserError
    # 形の崩れた報告は捨てる
  ensure
    head :no_content
  end
end
