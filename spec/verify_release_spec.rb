require 'rails_helper'
require 'yaml'
require_relative '../script/verify_release'

# script/verify_release.rb は「本番に届いたか」を外から機械で確かめる唯一の場所。
#
# 本番へ配る経路は 3 つ（test.yml の push・dependabot.yml からの dispatch・daily.yml）あり、
# どれも「動いた時に自分が成功したか」しか見ていない。工程がそもそも起動しなかった日には黙る。
# 実例: #1973 のマージコミット 8c5ee7f には test.yml の run が無く（マージが github-actions[bot] だった。
# #2025 で原因を修正）、そのコミットへの配達は翌朝の daily.yml だけで、その deploy は failure だった。
#
# センサー自身が黙るのが一番まずいので、判定だけを純粋な関数に切り出してここで固定する。
# 特に「読めなかった」を ok へ倒さないことを守る。
RSpec.describe VerifyRelease do
  let(:head)      { 'a' * 40 }
  let(:running)   { 'b' * 40 }
  let(:head_time) { Time.at(1_762_000_000) }
  let(:app)       { 'example-app' } # 本物の名前は secrets.HEROKU_APP_NAME

  def judge(running:, head: self.head, head_time: self.head_time, now: head_time + 10_800)
    described_class.judge(running: running, head: head, head_time: head_time, now: now)
  end

  describe '.judge' do
    it '一致していれば ok' do
      expect(judge(running: head)[:status]).to eq(:ok)
    end

    it '短い形と長い形が混ざっていても一致と見る' do
      expect(judge(running: head[0, 7])[:status]).to eq(:ok)
      expect(judge(running: head, head: head[0, 7])[:status]).to eq(:ok)
    end

    it '大文字と小文字は区別しない' do
      expect(judge(running: head.upcase)[:status]).to eq(:ok)
    end

    # デプロイは数分かかるので、マージ直後のずれで毎回鳴らすと人が見なくなる
    it 'ずれていても HEAD が新しいうちは pending' do
      expect(judge(running: running, now: head_time + 600)[:status]).to eq(:pending)
    end

    it '猶予を越えてずれていたら stale' do
      verdict = judge(running: running, now: head_time + 7201)
      expect(verdict[:status]).to eq(:stale)
      expect(verdict[:message]).to include(head[0, 7], running[0, 7])
    end

    # 猶予のちょうど境目で向きを間違えると、1 日ぶん見逃す
    it '猶予のちょうどの時刻は stale（越えた扱い）' do
      expect(judge(running: running, now: head_time + 7200)[:status]).to eq(:stale)
      expect(judge(running: running, now: head_time + 7199)[:status]).to eq(:pending)
    end

    # ここが ok に倒れると、センサー自身が黙って通す（防ぎたい事故と同じ型）
    it '本番のコミットが分からない時は ok にしない' do
      expect(judge(running: nil)[:status]).to eq(:unknown)
      expect(judge(running: '')[:status]).to eq(:unknown)
    end

    it '文面に main と書く（master と書かない）' do
      expect(judge(running: running, now: head_time + 7201)[:message]).to include('main')
    end
  end

  describe '.same_commit?' do
    it '空の値は一致と見ない' do
      expect(described_class.same_commit?(nil, head)).to be(false)
      expect(described_class.same_commit?('', head)).to be(false)
      expect(described_class.same_commit?(head, nil)).to be(false)
    end

    it '別のコミットは一致と見ない' do
      expect(described_class.same_commit?(head, running)).to be(false)
    end
  end

  describe '.minutes' do
    it '2 時間までは分、それ以上は時間で書く' do
      expect(described_class.minutes(600)).to eq('10 分')
      expect(described_class.minutes(7199)).to eq('119 分')
      expect(described_class.minutes(7200)).to eq('2.0 時間')
      expect(described_class.minutes(90_000)).to eq('25.0 時間')
    end

    # 時計のずれや、コミット日時が未来のコミットで waited が負になりうる。
    # そのまま割ると「-1 分前」と出る
    it '負の秒数は 0 分として書く' do
      expect(described_class.minutes(-30)).to eq('0 分')
      expect(described_class.minutes(-100_000)).to eq('0 分')
    end
  end

  # 09:30 に人が読む文なので、数字と単位の間だけを空ける
  describe '文面の体裁' do
    it '「分」や「時間」の後に余分な空白を入れない' do
      verdict = described_class.judge(running: running, head: head, head_time: head_time, now: head_time)

      expect(verdict[:message]).to include('0 分前')
      expect(verdict[:message]).not_to include('分 前')
    end

    it 'stale の文面も同じ' do
      verdict = described_class.judge(running: running, head: head, head_time: head_time, now: head_time + 90_000)

      expect(verdict[:message]).to include('25.0 時間前')
      expect(verdict[:message]).not_to include('時間 前')
    end
  end

  # Range を後から足すと Net::HTTP が gzip を求めたまま 206 を解凍しないので、
  # 本文が gzip のまま JSON.parse に回って `unexpected character: '\x1F\x8B'` で落ちる
  describe '.build_request' do
    let(:uri) { URI("https://api.heroku.com/apps/#{app}/releases") }

    it 'Range は Get.new に渡し、Accept-Encoding を付けない' do
      req = described_class.build_request(uri, token: 't', range: 'version ..; order=desc,max=20')

      expect(req['Range']).to eq('version ..; order=desc,max=20')
      expect(req['accept-encoding']).to be_nil
      expect(req.decode_content).to be(false)
    end

    it 'Range が無い時は自動解凍にまかせる' do
      req = described_class.build_request(uri, token: 't')

      expect(req['accept-encoding']).to include('gzip')
      expect(req.decode_content).to be(true)
    end

    it 'Accept と Authorization を付ける' do
      req = described_class.build_request(uri, token: 'abc')

      expect(req['Accept']).to eq(described_class::HEROKU_ACCEPT)
      expect(req['Authorization']).to eq('Bearer abc')
    end
  end

  # 本番のコミットが空のまま git に渡ると、`rev-list --count ..HEAD` が 0 を返し、
  # 本文が「main が 0 コミット先にいます」という嘘になる
  describe '.behind_count' do
    it '本番のコミットが分からない時は数えない（git を呼ばない）' do
      allow(Open3).to receive(:capture2)

      expect(described_class.behind_count(nil, head)).to be_nil
      expect(described_class.behind_count('', head)).to be_nil
      expect(Open3).not_to have_received(:capture2)
    end

    it '数えられたらその数を返す' do
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2).and_return(["3\n", status])

      expect(described_class.behind_count(running, head)).to eq('3')
    end

    it 'git が失敗したら nil を返す（報告は続ける）' do
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2).and_return(['', status])

      expect(described_class.behind_count(running, head)).to be_nil
    end
  end

  describe '.issue_body' do
    subject(:body) { described_class.issue_body(verdict: verdict, running: running_value, head: head, behind: behind) }

    let(:verdict) { { status: :stale, message: 'ずれています' } }
    let(:running_value) { running }
    let(:behind) { '3' }

    it '本番と main のコミットと、遅れている本数を書く' do
      expect(body).to include(running[0, 7], head[0, 7], '3 コミット')
    end

    it '代筆の明記を 1 行目に置く' do
      expect(body.lines.first).to include('Claude Code が代筆')
    end

    # ok に戻っても自動では閉じない。書いておかないと「閉じ忘れ」か「まだ直っていない」か分からない
    it '自動では閉じないことを書く' do
      expect(body).to include('自動では閉じません')
    end

    # 配る経路が 3 つあるので、どれを見るかを本文に書く
    it '3 つの経路すべてを見るところに挙げる' do
      expect(body).to include('test.yml', 'dependabot.yml', 'daily.yml')
    end

    # 本番のコミットが分からない時（:unknown）に `git rev-list --count ..HEAD` が 0 を返すので、
    # そのまま書くと「main が 0 コミット先にいます」という嘘になる
    context '本番のコミットが分からない時' do
      let(:running_value) { nil }
      let(:behind) { nil }

      it '「0 コミット先」と書かない' do
        expect(body).not_to include('0 コミット')
      end

      it '分からないことをそのまま書く' do
        expect(body).to include('分かりませんでした')
      end
    end
  end

  # schedule は既定ブランチでしか動かないが、workflow_dispatch は任意のブランチから起こせる。
  # その時 git rev-parse HEAD はそのブランチを指すので、本番と比べて偽の stale になり Issue まで立つ
  describe 'workflow の設定' do
    let(:workflow) { YAML.safe_load_file(Rails.root.join('.github/workflows/verify-release.yml')) }

    it 'main 以外のブランチから起こされた時は動かない' do
      expect(workflow.dig('jobs', 'verify', 'if').to_s).to include('refs/heads/main')
    end

    it 'Issue を立てる権限を持つ' do
      expect(workflow['permissions']).to include('issues' => 'write')
    end

    # アプリ名は secrets.HEROKU_APP_NAME にしている。ここに直接書くと公開リポジトリに出る
    it 'アプリ名を直接書かず secrets から渡す' do
      env = workflow.dig('jobs', 'verify', 'steps').last['env']

      expect(env['HEROKU_APP']).to include('secrets.HEROKU_APP_NAME')
      expect(env['HEROKU_API_KEY']).to include('secrets.HEROKU_API_KEY')
    end

    # Daily Workflow が db/news.yml を push するのは 09:20〜09:27 JST。その直後に見ると
    # HEAD が 2 時間の猶予に収まって必ず pending になり、その日の daily.yml の deploy の失敗を見逃す
    it '猶予（2 時間）を越えた時刻に動かす' do
      cron = workflow[true]['schedule'].first['cron']

      expect(cron).to eq('0 3 * * *') # 12:00 JST
    end
  end

  # Issue は 1 本だけ持つ。重複を避けられない時に立てると、毎日 1 本増えて人が見なくなる
  describe '.report_issue' do
    before do
      allow(described_class).to receive(:system).and_return(true)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('GH_TOKEN').and_return('dummy')
    end

    it '無ければ立てる' do
      allow(described_class).to receive(:open_issue_number).and_return(nil)
      described_class.report_issue('本文')

      expect(described_class).to have_received(:system).with('gh', 'issue', 'create', any_args)
    end

    it 'あれば本文を更新する（新しい通知を出さない）' do
      allow(described_class).to receive(:open_issue_number).and_return(42)
      described_class.report_issue('本文')

      expect(described_class).to have_received(:system).with('gh', 'issue', 'edit', '42', '--body', '本文')
    end

    # 一覧が取れない時に立てると、既にある分と重複して毎日増える。
    # workflow 自体は別に赤くなるので、ここは何もしないのが正しい
    it '一覧が取れなかった時は、立ても更新もしない' do
      allow(described_class).to receive(:open_issue_number).and_return(:unknown)
      described_class.report_issue('本文')

      expect(described_class).not_to have_received(:system)
    end

    it 'GH_TOKEN が無ければ何もしない' do
      allow(ENV).to receive(:[]).with('GH_TOKEN').and_return(nil)
      allow(described_class).to receive(:open_issue_number).and_return(nil)
      described_class.report_issue('本文')

      expect(described_class).not_to have_received(:system)
    end
  end

  describe '.open_issue_number' do
    def stub_gh(out, success: true)
      status = instance_double(Process::Status, success?: success)
      allow(Open3).to receive(:capture2).and_return([out, status])
    end

    it '題名が完全に一致する Issue の番号を返す' do
      stub_gh([{ 'number' => 7, 'title' => '別の件' },
               { 'number' => 42, 'title' => described_class::ISSUE_TITLE }].to_json)

      expect(described_class.open_issue_number).to eq(42)
    end

    # 部分一致で拾うと、題名が似ただけの別の Issue を書き換えてしまう
    it '題名が部分的に似ているだけの Issue は拾わない' do
      stub_gh([{ 'number' => 7, 'title' => "#{described_class::ISSUE_TITLE}（続き）" }].to_json)

      expect(described_class.open_issue_number).to be_nil
    end

    it 'gh が失敗したら :unknown を返す（nil にすると重複して立ててしまう）' do
      stub_gh('', success: false)

      expect(described_class.open_issue_number).to eq(:unknown)
    end

    it '出力が JSON でなければ :unknown を返す' do
      stub_gh('これは JSON ではない')

      expect(described_class.open_issue_number).to eq(:unknown)
    end
  end

  # 設定変数の変更などで slug が付かないリリースが挟まることがある。
  # 新しい順に探して、status が succeeded で slug を持つ最初のものを使う。
  #
  # ここで status を見落とすとセンサーが黙る。Procfile の `release: ./script/release.sh` が落ちると、
  # リリースは新しい commit の slug を持ったまま failed で残り、本番は前の版のまま。
  # status を無視すると、その slug の commit が main の HEAD と一致して ok になる
  # （status の enum は failed / pending / succeeded / expired。api.heroku.com/schema で確認）
  describe '.running_commit' do
    before do
      allow(described_class).to receive(:heroku_get).with("/apps/#{app}/releases", any_args).and_return(releases)
      allow(described_class).to receive(:heroku_get).with("/apps/#{app}/slugs/slug-2", any_args)
                                                    .and_return({ 'commit' => running })
    end

    let(:releases) do
      [
        { 'version' => 9, 'status' => 'succeeded', 'slug' => nil },
        { 'version' => 8, 'status' => 'succeeded', 'slug' => { 'id' => 'slug-2' } },
        { 'version' => 7, 'status' => 'succeeded', 'slug' => { 'id' => 'slug-1' } }
      ]
    end

    it 'slug を持つ最初のリリースの commit を返す' do
      expect(described_class.running_commit(app: app, token: 'x')).to eq(running)
    end

    it 'slug を持つリリースが無ければ nil を返す（judge が unknown にする）' do
      allow(described_class).to receive(:heroku_get).with("/apps/#{app}/releases", any_args)
                                                   .and_return([{ 'version' => 9, 'status' => 'succeeded',
                                                                  'slug' => nil }])

      expect(described_class.running_commit(app: app, token: 'x')).to be_nil
    end

    # 本題。release phase が落ちた朝に、その slug を「動いているもの」として読むと ok で黙る
    context 'release phase が落ちた（failed）リリースが最新の時' do
      let(:releases) do
        [
          { 'version' => 10, 'status' => 'failed',    'slug' => { 'id' => 'slug-3' } },
          { 'version' => 9,  'status' => 'succeeded', 'slug' => { 'id' => 'slug-2' } }
        ]
      end

      it 'failed のリリースは読まず、前の succeeded の commit を返す' do
        expect(described_class.running_commit(app: app, token: 'x')).to eq(running)
        expect(described_class).not_to have_received(:heroku_get).with("/apps/#{app}/slugs/slug-3", any_args)
      end
    end

    # 09:30 にまだ release phase が走っている時も、その slug を読むと ok で黙る
    context 'まだ走っている（pending）リリースが最新の時' do
      let(:releases) do
        [
          { 'version' => 10, 'status' => 'pending',   'slug' => { 'id' => 'slug-3' } },
          { 'version' => 9,  'status' => 'succeeded', 'slug' => { 'id' => 'slug-2' } }
        ]
      end

      it 'pending のリリースは読まず、前の succeeded の commit を返す' do
        expect(described_class.running_commit(app: app, token: 'x')).to eq(running)
      end
    end

    it 'succeeded のリリースが 1 つも無ければ nil を返す（judge が unknown にする）' do
      allow(described_class).to receive(:heroku_get).with("/apps/#{app}/releases", any_args)
                                                   .and_return([{ 'version' => 10, 'status' => 'failed',
                                                                  'slug' => { 'id' => 'slug-3' } }])

      expect(described_class.running_commit(app: app, token: 'x')).to be_nil
    end
  end

  # 例外の文にアプリ名が入ると、Issue の本文（公開）に出る
  describe '.heroku_get' do
    it '失敗の文にパスを書かない' do
      res = instance_double(Net::HTTPForbidden, code: '403')
      allow(res).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(Net::HTTP).to receive(:start).and_return(res)

      expect { described_class.heroku_get("/apps/#{app}/releases", token: 'x') }
        .to raise_error(/403/) { |e| expect(e.message).not_to include(app) }
    end
  end
end
