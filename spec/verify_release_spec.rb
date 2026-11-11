require 'rails_helper'
require 'yaml'

# `.github/workflows/verify-release.yml` は「本番に届いたか」を外から機械で確かめる唯一の場所。
# 判定そのものは test.yml と同じ道具（Heroku CLI + jq）なので、ここで見るのは
# **設定を間違えると黙る／誤って鳴る**ところだけにする。
#
# 判定の jq は、環境変数の設定で誤って鳴った（#2033）ので、リリースの並びに当てて確かめる。
# `age -lt 7200` の 1 行は test.yml に実運用の前例があるので単体テストを置かない。
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

  # checkout が落ちた日、gh は git remote からリポジトリを決められず
  # `fatal: not a git repository` で止まる。run が赤いだけで Issue が立たない
  it 'リポジトリを --repo で渡す（checkout が落ちた日も Issue を立てる）' do
    expect(steps.last['run'].scan('--repo "$GITHUB_REPOSITORY"').size).to eq(3)
  end

  # release phase が落ちたリリースは、新しい commit の slug を持ったまま failed で残り、
  # 本番は前の版のまま。status を見ないと、その description が HEAD と一致して緑になる。
  # any() にすると過去 10 件に紛れて、ロールバック中でも緑になる
  it '最新の succeeded なリリース 1 件だけを本番と見る' do
    expect(check_code).to include('select(.status == "succeeded"', ')][0]')
    expect(check_code).not_to include('any(')
  end

  # パイプの途中が落ちた時に緑で通ると、センサー自身が黙る
  it 'シェルの失敗を握りつぶさない' do
    expect(check['run']).to include('set -euo pipefail')
  end

  # 判定の jq を、workflow から取り出してリリースの並びに当てる（jq は ubuntu のランナーにある）
  describe '判定の jq' do
    let(:filter) { check_code[/jq -e --arg sha "\$sha" \\\s*'(.+?)'/m, 1] }

    def release(version, status, description) = { version:, status:, description: }

    def caught_up?(releases, sha: '2e22bdc')
      _, status = Open3.capture2('jq', '-e', '--arg', 'sha', sha, filter, stdin_data: releases.to_json)
      status.success?
    end

    it '最新が HEAD の Deploy なら追いついている' do
      expect(caught_up?([release(4154, 'succeeded', 'Deploy 2e22bdce')])).to be true
    end

    # 環境変数の設定・アドオンの付け外しもリリースになるが、slug（コード）は変わらない。
    # これを本番の版と見ると、デプロイの後に環境変数を変えただけで赤になる（#2033）
    it 'デプロイの後に環境変数を変えても、追いついていると見る' do
      releases = [release(4155, 'succeeded', 'Set SENTRY_DSN config vars'),
                  release(4154, 'succeeded', 'Deploy 2e22bdce')]
      expect(caught_up?(releases)).to be true
    end

    it '最新の Deploy が古い版なら追いついていない' do
      releases = [release(4155, 'succeeded', 'Set SENTRY_DSN config vars'),
                  release(4153, 'succeeded', 'Deploy 4423dab4')]
      expect(caught_up?(releases)).to be false
    end

    it 'HEAD の Deploy が failed なら追いついていない' do
      releases = [release(4155, 'failed',    'Deploy 2e22bdce'),
                  release(4154, 'succeeded', 'Deploy 4423dab4')]
      expect(caught_up?(releases)).to be false
    end

    it 'ロールバック中は追いついていない' do
      releases = [release(4156, 'succeeded', 'Rollback to v4153'),
                  release(4154, 'succeeded', 'Deploy 2e22bdce')]
      expect(caught_up?(releases)).to be false
    end
  end
end
