require 'rails_helper'

# 手元のシェルに SLACK_HOOK_URL が設定されていると、集計の失敗を確かめる spec が
# 本物の Slack に通知を送ってしまう。テストでは環境変数を外して実行する
RSpec.describe 'テスト中の Slack 通知' do
  # 値は秘密なので、失敗時のメッセージに出さないよう有無だけを比べる
  it 'SLACK_HOOK_URL が設定されていない' do
    expect(ENV.key?('SLACK_HOOK_URL')).to be false
  end
end
