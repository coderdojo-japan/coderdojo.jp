require 'rails_helper'

# Dependabot の PR は .github/workflows/dependabot.yml が yasslab/dependabot_auto_merge で
# approve し、CI を待ってからマージする。どちらも赤の出ない形で止まった実例がある。
RSpec.describe 'Dependabot auto-merge workflow' do
  # YAML 1.1 では `on:` が真偽値になるので、キーは文字列ではなく true で引く
  let(:workflow)    { YAML.safe_load_file(Rails.root.join('.github/workflows/dependabot.yml')) }
  let(:deploy)      { YAML.safe_load_file(Rails.root.join('.github/workflows/test.yml')) }
  let(:permissions) { workflow['permissions'] }
  let(:steps)       { workflow.dig('jobs', 'dependabot', 'steps') }

  # CI を待つのに gh pr view --json statusCheckRollup を使う。public のリポジトリでは権限が無くても読めるが、
  # private に変えると、欠けた時に GraphQL のエラーで止まる（approve 済み・CI 緑のまま、マージされないだけになる）
  it 'CI の結果（statusCheckRollup）を読める' do
    expect(permissions).to include('checks' => 'read', 'statuses' => 'read')
    # actions は write。下のデプロイの呼び出しにも要る（write は read を含む）
    expect(permissions['actions']).to eq('write')
  end

  it 'approve とマージのための write を持つ' do
    expect(permissions).to include('contents' => 'write', 'pull-requests' => 'write')
  end

  # GITHUB_TOKEN で起こした出来事は workflow を動かさない（GitHub の仕様。例外は
  # workflow_dispatch と repository_dispatch だけ）。自動マージの push では test.yml の
  # deploy が動かず、本番に届かないまま全部緑に見える（2026-10-21 のマージ #1973 で
  # test.yml の run が無かった）。
  #   https://docs.github.com/en/actions/concepts/security/github_token
  describe '自動マージが本番まで届く' do
    let(:dispatch_step) { steps.find { |s| s['run'].to_s.include?('workflow run test.yml') } }

    it 'マージした後にデプロイの workflow を呼ぶ手順がある' do
      expect(dispatch_step).not_to be_nil
    end

    # 自動マージの action はマージを済ませた後に失敗する経路がある。
    # 既定の「前のステップが成功した時だけ」にすると、マージ済みなのに本番が古いまま止まる
    it 'その手順は、前のステップが失敗しても動く' do
      expect(dispatch_step['if'].to_s).to include('!cancelled()')
    end

    # `gh workflow run` は 204 を返すだけで、run が作られたかは返さない
    it '呼んだだけで終わらせず、run が作られたか確かめて落ちる' do
      expect(dispatch_step['run']).to include('gh run list')
      expect(dispatch_step['run']).to include('::error::')
    end

    it 'デプロイの workflow が workflow_dispatch を受け付け、main なら deploy が動く' do
      expect(deploy[true]).to have_key('workflow_dispatch')
      expect(deploy.dig('jobs', 'deploy', 'if')).to eq("github.ref == 'refs/heads/main'")
    end
  end
end
