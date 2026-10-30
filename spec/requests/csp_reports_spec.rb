require 'rails_helper'

# 今の CSP はどのスクリプトも通すので、XSS を止めない。スクリプトを絞った方針を止めずに報告だけ（Report-Only）にして、
# 何が止まるかを数える。報告はこのアプリの /csp_report で受けて、ログに残す
RSpec.describe "CSP の報告", type: :request do
  let(:report) do
    {
      'csp-report' => {
        'document-uri'        => 'https://coderdojo.jp/',
        'effective-directive' => 'script-src-elem',
        'blocked-uri'         => 'inline',
        'script-sample'       => "alert(1)\nforged log line"
      }
    }
  end

  it "スクリプトを絞った方針を、止めずに報告だけする" do
    get root_path

    header = response.headers['Content-Security-Policy-Report-Only']
    expect(header).to include("script-src 'self' 'report-sample'", "object-src 'none'", "base-uri 'self'", 'report-uri /csp_report')
    expect(header).not_to match(/script-src[^;]*'unsafe-inline'/)
  end

  it "今の方針は、これまでどおり強制する" do
    get root_path

    expect(response.headers['Content-Security-Policy']).to include("script-src *")
  end

  it "ブラウザの報告を受け取り、1 行のログに残す" do
    allow(Rails.logger).to receive(:info).and_call_original
    post '/csp_report', params: report.to_json, headers: { 'Content-Type' => 'application/csp-report' }

    expect(response).to have_http_status(:no_content)
    expect(Rails.logger).to have_received(:info).with(a_string_starting_with('[CSP]').and(including('script-src-elem')).and(satisfy { !it.include?("\n") }))
  end

  # 報告は誰でも送れる。例外にすると 500 を返し、Airbrake にも通知が届く
  ['not json', '[]', 'null', '1', '{"csp-report": "x"}'].each do |body|
    it "形の崩れた報告（#{body}）でも、例外にせず受け流す" do
      post '/csp_report', params: body, headers: { 'Content-Type' => 'application/csp-report' }

      expect(response).to have_http_status(:no_content)
    end
  end
end
