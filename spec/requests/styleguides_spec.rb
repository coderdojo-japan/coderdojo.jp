require 'rails_helper'

# 色見本（/styleguides）で色を押すとコードをコピーし、「コピーしました」を出す。
# 通知のためだけに jQuery のプラグイン notify.js（626 行）を読んでいたので、素の JS で出す
RSpec.describe '色見本のコピー', type: :request do
  let(:script) { Rails.root.join('public/js/styleguides.js').read }

  it 'notify.js を読まない' do
    get '/styleguides'
    srcs = Nokogiri::HTML(response.body).css('script[src]').map { it['src'] }

    expect(srcs).to include('/js/styleguides.js')
    expect(srcs.grep(/notify/)).to be_empty
    expect(Rails.root.join('public/js/notify.js')).not_to exist
  end

  it 'jQuery を使わずに、コピーして通知を出す' do
    expect(script).not_to include('$.')
    expect(script).not_to include('execCommand')
    expect(script).to include('navigator.clipboard.writeText')
    expect(script).to include('コピーしました')
  end
end
