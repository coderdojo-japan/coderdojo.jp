require 'rails_helper'

# jQuery 1.12.4 には既知の XSS（CVE-2020-11022・CVE-2020-11023 など）があり、
# 機能判定で onfocusin 属性を付けるので、CSP の報告がページを開くたびに届いていた
RSpec.describe 'application.js の jQuery' do
  it 'jQuery 3 を読む' do
    source = Rails.application.assets.find_asset('application.js').to_s

    expect(source).to include('jQuery JavaScript Library v3.')
    expect(source).not_to include('jQuery JavaScript Library v1.')
    expect(source).not_to include('onfocusin')
  end
end
