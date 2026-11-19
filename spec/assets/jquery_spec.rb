require 'rails_helper'

# jQuery 1.12.4 には既知の XSS（CVE-2020-11022・CVE-2020-11023 など）があり、
# 機能判定で onfocusin 属性を付けるので、CSP の報告がページを開くたびに届いていた（文字列を組み立てるのでソースには出ない）
RSpec.describe 'application.js の jQuery' do
  let(:source) { Rails.application.assets.find_asset('application.js').to_s }

  it 'jQuery 3 を読む' do
    expect(source).to include('jQuery JavaScript Library v3.')
    expect(source).not_to include('jQuery JavaScript Library v1.')
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
