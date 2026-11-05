require 'rails_helper'
require 'yaml'

# `.github/workflows/verify-release.yml` は「本番に届いたか」を外から機械で確かめる唯一の場所。
# 判定そのものは test.yml と同じ道具（Heroku CLI + jq）なので、ここで見るのは
# **設定を間違えると黙る／誤って鳴る**ところだけにする。
#
# 判定ロジックの単体テストは置かない。中身は jq 1 行と `age -lt 7200` の 1 行で、
# どちらも test.yml に実運用の前例がある。足りないと分かった時に足す。
RSpec.describe 'Verify Release workflow' do
  let(:workflow) { YAML.safe_load_file(Rails.root.join('.github/workflows/verify-release.yml')) }
  let(:steps)    { workflow.dig('jobs', 'verify', 'steps') }
  let(:check)    { steps.find { |s| s['run'].to_s.include?('heroku releases') } }
  # 見るのは実行される行だけ。コメントでは「使わない理由」として名前を出してよい
  let(:check_code) { check['run'].lines.grep_v(/^\s*#/).join }

  # workflow_dispatch は任意のブランチから起こせる。その時 HEAD はそのブランチを指すので、
  # 本番と比べて偽の Issue が立つ
  it 'main 以外のブランチから起こされた時は動かない' do
    expect(workflow.dig('jobs', 'verify', 'if').to_s).to include('refs/heads/main')
  end

  it 'Issue を立てる権限を持つ' do
    expect(workflow['permissions']).to include('issues' => 'write')
  end

  # Daily Workflow が db/news.yml を push するのは 09:20〜09:27 JST。その直後に見ると
  # 猶予（2 時間）に必ず収まり、その日の daily.yml の deploy の失敗を見逃す
  it '猶予を越えた時刻に動かす' do
    expect(workflow[true]['schedule'].first['cron']).to eq('0 3 * * *') # 12:00 JST
  end

  # アプリ名は secret。公開リポジトリなので直接書かない
  it 'アプリ名と API キーを secrets から渡す' do
    expect(check['env']['HEROKU_APP_NAME']).to include('secrets.HEROKU_APP_NAME')
    expect(check['env']['HEROKU_API_KEY']).to include('secrets.HEROKU_API_KEY')
  end

  # 落ちた時に黙ると、気づけるのは cron の行を最後に変更した人のメールだけになる。
  # `if: failure()` は「ずれ」だけでなく「Heroku が読めない」「jq が落ちた」も拾う
  it '落ちたら必ず Issue にする' do
    notify = steps.last

    expect(notify['if']).to eq('failure()')
    expect(notify['run']).to include('gh issue create', 'gh issue edit')
  end

  # release phase が落ちたリリースは、新しい commit の slug を持ったまま failed で残り、
  # 本番は前の版のまま。status を見ないと、その description が HEAD と一致して緑になる。
  # any() にすると過去 10 件に紛れて、ロールバック中でも緑になる
  it '最新の succeeded なリリース 1 件だけを本番と見る' do
    expect(check_code).to include('select(.status == "succeeded")][0]')
    expect(check_code).not_to include('any(')
  end

  # パイプの途中が落ちた時に緑で通ると、センサー自身が黙る
  it 'シェルの失敗を握りつぶさない' do
    expect(check['run']).to include('set -euo pipefail')
  end
end
