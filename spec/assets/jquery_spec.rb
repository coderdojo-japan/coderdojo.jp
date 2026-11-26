require 'rails_helper'

# jQuery は読まない。開閉・tooltip・地図・コピーの通知を、1 つずつ素の JS・CSS・SVG に移した。
# 以前は jQuery 1.12.4 が機能判定で onfocusin 属性を付け、CSP の報告がページを開くたびに届いていた
RSpec.describe 'application.js と jQuery' do
  let(:source) { Rails.application.assets.find_asset('application.js').to_s }

  it 'jQuery を読まない' do
    expect(source).not_to include('jQuery JavaScript Library')
  end

  # jQuery を読まないので、アプリの JS に jQuery を前提にした書き方（$( や jQuery.）を残さない
  it 'アプリの JS は jQuery を使わない' do
    Dir[Rails.root.join('app/assets/javascripts/*.js')].each do |path|
      expect(File.read(path)).not_to match(/(\A|[^\w.])(\$|jQuery)[(.]/), path
    end
  end

  # ビューに data-method・data-confirm・data-remote は無く、jquery_ujs で使うのは
  # f.submit が付ける data-disable-with（二重送信を防ぐ）だけなので、layout.js で受け持つ
  it 'jquery_ujs を読まず、送信ボタンの data-disable-with は layout.js が扱う' do
    expect(source).not_to include('Unobtrusive scripting adapter for jQuery')
    expect(source).to include('[data-disable-with]')
  end

  # 「戻る」でキャッシュから表示した時に、無効にしたボタンを押せるように戻す（jquery_ujs と同じ）
  it '戻った時に送信ボタンを戻す' do
    expect(source).to include("addEventListener('pageshow'")
    expect(source).to include('event.persisted')
  end
end
