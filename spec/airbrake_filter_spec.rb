require 'rails_helper'

# デプロイや再起動のたびに Heroku が Puma へ SIGTERM を送る。これは障害ではないので
# Airbrake へ通知しないよう、config/initializers/airbrake.rb でフィルタしている。
#
# そのフィルタが notice.exception を呼んでいたが、Airbrake::Notice にそのメソッドは
# 無く、通知のたびに NoMethodError で落ちていた。例外を取り出すには stash を使う。
# cf. https://github.com/coderdojo-japan/coderdojo.jp/pull/1884
RSpec.describe 'Airbrake の SIGTERM フィルタ' do
  # 実際に通知が飛ばないよう、フィルタの処理だけを取り出して検証する
  let(:filter) do
    lambda do |notice|
      exception = notice.stash[:exception]
      notice.ignore! if exception.is_a?(SignalException) && exception.message == 'SIGTERM'
    end
  end

  def build_notice(exception)
    Airbrake::Notice.new(exception)
  end

  it 'SIGTERM は通知しない' do
    notice = build_notice(SignalException.new('SIGTERM'))
    filter.call(notice)
    expect(notice).to be_ignored
  end

  it 'SIGTERM 以外のシグナルは通知する' do
    notice = build_notice(SignalException.new('SIGINT'))
    filter.call(notice)
    expect(notice).not_to be_ignored
  end

  it 'ふつうの例外は通知する' do
    notice = build_notice(RuntimeError.new('何かがおかしい'))
    filter.call(notice)
    expect(notice).not_to be_ignored
  end

  # Airbrake::Notice に exception メソッドは無い。あると思い込んだまま書くと、
  # 通知が発生した瞬間に NoMethodError になる（本番でしか踏まない）。
  it 'Airbrake::Notice は exception メソッドを持たない' do
    notice = build_notice(RuntimeError.new('test'))
    expect(notice).not_to respond_to(:exception)
    expect(notice.stash[:exception]).to be_a(RuntimeError)
  end

  # 上のテストは「正しい書き方」を確かめるだけで、initializer が実際にそう書いて
  # いるかは見ていない。壊れた書き方に戻っても気付けるよう、中身を直接検査する。
  it 'initializer が notice.exception を呼んでいない' do
    source = Rails.root.join('config/initializers/airbrake.rb').read
    expect(source).not_to match(/notice\.exception/)
    expect(source).to match(/notice\.stash\[:exception\]/)
  end
end
