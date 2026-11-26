require 'rails_helper'

# 色見本（/styleguides）で色を押すとコードをコピーし、「コピーしました」を出す。
# 通知のためだけに jQuery のプラグイン notify.js（626 行）を読んでいたので、素の JS で出す
RSpec.describe '色見本のコピー', type: :request do
  let(:script) { Rails.root.join('public/js/styleguides.js').read }

  def script_srcs
    get '/styleguides'
    Nokogiri::HTML(response.body).css('script[src]').map { it['src'] }
  end

  it 'notify.js を読まない' do
    expect(script_srcs.grep(/notify/)).to be_empty
    expect(Rails.root.join('public/js/notify.js')).not_to exist
  end

  it 'jQuery を使わずに、コピーして通知を出す' do
    expect(script).not_to include('$.')
    expect(script).not_to include('execCommand')
    expect(script).to include('navigator.clipboard.writeText')
    expect(script).to include('コピーしました')
  end

  # public/js は本番で 1 年キャッシュされ、URL にハッシュが付かない。JS だけ古いまま新しいページと
  # 組み合わさると壊れる（#2057 の後、以前開いた人のブラウザで古い JS が無い #copy を探して落ちた）。
  # そこで URL に中身のハッシュを付け、JS を直せば URL も変わるようにする
  it 'styleguides.js の URL に、中身のハッシュを付ける' do
    digest = Digest::SHA256.hexdigest(script)[0, 8]

    expect(script_srcs).to include("/js/styleguides.js?v=#{digest}")
  end
end
