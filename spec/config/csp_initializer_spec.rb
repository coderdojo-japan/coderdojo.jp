require 'rails_helper'

# development は Rails のエラー画面と web-console がインラインの JS を使うので、止めずに報告だけにする。
# request spec は test 環境の分岐しか通らないので、development の分岐は設定を読み直して確かめる
RSpec.describe "config/initializers/csp.rb" do
  # secure_headers は設定を 1 回しか受け付けないので、読み直す前に内部の設定を外し、終わったら元に戻す
  around do |example|
    saved = %i[@default_config @overrides].to_h { [it, SecureHeaders::Configuration.instance_variable_get(it)] }
    example.run
  ensure
    saved.each { |name, value| SecureHeaders::Configuration.instance_variable_set(name, value) }
  end

  def headers_for(env)
    SecureHeaders::Configuration.remove_instance_variable(:@default_config)
    SecureHeaders::Configuration.instance_variable_set(:@overrides, {})
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new(env))
    load Rails.root.join("config/initializers/csp.rb")
    SecureHeaders.header_hash_for(Rack::Request.new(Rack::MockRequest.env_for("https://example.com/")))
  end

  it "development では強制せず、同じ方針を報告だけにする" do
    headers = headers_for("development")

    expect(headers).not_to have_key('content-security-policy')
    expect(headers['content-security-policy-report-only']).to include("script-src 'self' ", "object-src 'none'")
  end

  it "production では強制し、Report-Only は出さない" do
    headers = headers_for("production")

    expect(headers['content-security-policy']).to include("script-src 'self' ", "object-src 'none'")
    expect(headers).not_to have_key('content-security-policy-report-only')
  end
end
