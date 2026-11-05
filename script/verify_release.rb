#!/usr/bin/env ruby
# frozen_string_literal: true
#
# 本番で動いているコミットと main の HEAD を照合する。ずれていたら落ちる。
#
# なぜ要るか:
#   本番へ配る経路が 3 つあり、どれも**自分の中でだけ**検査している。
#
#     1. test.yml の deploy（main への push）
#     2. dependabot.yml が自動マージの後に test.yml を呼ぶ（#2025）
#     3. daily.yml の deploy（db/news.yml が変わった日だけ。FOUND_NEWS == 'true'）
#
#   どの経路も「動いた時に自分が成功したか」は見ているが、**工程がそもそも起動しなかった日**には
#   黙る。GITHUB_TOKEN で起こした push は workflow を動かさないので（例外は workflow_dispatch と
#   repository_dispatch）、自動マージや daily.yml の push では 1. が呼ばれない。
#
#   実例（2026-11-05 に API で確認）: #1973 は 2026-10-22 03:22 JST に github-actions[bot] が
#   マージし、マージコミット 8c5ee7f に test.yml の run は無い。そのコミットへの配達は翌朝 09:20 JST の
#   daily.yml だけで、その deploy は failure だった（run 39698980560）。
#   **どちらの穴も、本番が main に追いついているかを誰にも教えない。**
#
#   ここが「本番に届いた」を外から機械で確かめる唯一の場所。
#
# 捕まえる範囲（どの原因でも同じ 1 つの事実として出る）:
#   デプロイが呼ばれない / 呼ばれたが失敗 / Heroku 側で止まった / 人がマージを忘れた
#
# 使い方:
#   HEROKU_API_KEY=... HEROKU_APP=<app> ruby script/verify_release.rb
#   ずれていれば exit 1。GH_TOKEN があれば Issue を 1 本だけ立てる（既にあれば本文を更新）
#
# NOTE: アプリ名は secrets.HEROKU_APP_NAME から渡す。出力や Issue の本文には書かない

require 'net/http'
require 'json'
require 'open3'
require 'uri'

module VerifyRelease
  HEROKU_API    = 'https://api.heroku.com'
  HEROKU_ACCEPT = 'application/vnd.heroku+json; version=3'
  ISSUE_TITLE   = '🚨 本番が main に追いついていません'

  # デプロイは数分かかるので、マージ直後のずれは異常ではない
  GRACE_SECONDS = 2 * 60 * 60

  class << self
    # 判定だけを担う純粋な関数。IO を持たないのでそのまま spec で固定できる
    #
    # @param running [String, nil] 本番で動いているコミット（Heroku の slug の commit）
    # @param head [String] main の HEAD
    # @param head_time [Time] HEAD のコミット時刻
    # @param now [Time]
    # @return [Hash] {status: :ok | :pending | :stale | :unknown, message: String}
    def judge(running:, head:, head_time:, now:, grace: GRACE_SECONDS)
      return { status: :unknown, message: '本番で動いているコミットが分かりませんでした' } if running.to_s.empty?

      return { status: :ok, message: "一致しています（#{short(head)}）" } if same_commit?(running, head)

      waited = (now - head_time).to_i
      if waited < grace
        return {
          status: :pending,
          message: "ずれていますが、main の HEAD（#{short(head)}）はまだ #{minutes(waited)}前なので待ちます" \
                   "（本番は #{short(running)}）"
        }
      end

      {
        status: :stale,
        message: "本番は #{short(running)} のままで、main の HEAD（#{short(head)}）が #{minutes(waited)}前から届いていません"
      }
    end

    # 短い形と長い形が混ざっても比べられるようにする（Heroku は 40 桁、手で渡す時は 7 桁）
    def same_commit?(a, b)
      a = a.to_s.downcase
      b = b.to_s.downcase
      return false if a.empty? || b.empty?

      a.start_with?(b) || b.start_with?(a)
    end

    def short(sha) = sha.to_s[0, 7]

    # 時計のずれや、コミット日時が未来のコミットで seconds が負になりうる。
    # そのまま割ると「-1 分前」と出る
    def minutes(seconds)
      seconds = 0 if seconds.negative?
      return "#{seconds / 60} 分" if seconds < 7200

      "#{(seconds / 3600.0).round(1)} 時間"
    end

    # 最新のリリースのうち、slug を持つものの commit を返す。
    # 設定変数の変更などで slug が付かないリリースが挟まることがあるので、新しい順に探す。
    # NOTE: Cedar（Procfile と slug）の前提。Fir 世代（OCI image）に移すとリリースは
    #       `slug` ではなく `oci_image` を持つので、ここを直す。移すまでは毎日 :unknown で鳴るだけで、
    #       黙って ok になることはない
    def running_commit(app:, token:)
      releases = heroku_get("/apps/#{app}/releases", token: token,
                                                     range: 'version ..; order=desc,max=20')
      release = Array(releases).find { |r| r.dig('slug', 'id') }
      return nil unless release

      heroku_get("/apps/#{app}/slugs/#{release.dig('slug', 'id')}", token: token)['commit']
    end

    # ヘッダーは **必ず `Get.new` の第 2 引数で渡す**。後から `req['Range'] = …` を足すと、
    # Net::HTTP は gzip を求めたまま（`decode_content = true`）になるのに、`Content-Range` 付きの
    # 応答（206）は解凍しない。その結果、本文が gzip のまま JSON.parse に回って
    # `unexpected character: '\x1F\x8B'` で落ちる
    def build_request(uri, token:, range: nil)
      headers = { 'Accept' => HEROKU_ACCEPT, 'Authorization' => "Bearer #{token}" }
      headers['Range'] = range if range
      Net::HTTP::Get.new(uri, headers)
    end

    def heroku_get(path, token:, range: nil)
      uri = URI.join(HEROKU_API, path)
      req = build_request(uri, token: token, range: range)

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
      # 読めなかったことを ok 扱いにしない。黙って通すのが防ぎたい事故そのもの。
      # NOTE: パスにはアプリ名が入るので、例外の文には出さない（secrets.HEROKU_APP_NAME）
      raise "Heroku API が #{res.code} を返しました" unless res.is_a?(Net::HTTPSuccess)

      JSON.parse(res.body)
    end

    # シェルを通さず、引数は配列で渡す（brakeman の Command Injection を避けるためだけでなく、
    # 引数に空白や記号が入った時に壊れないため）。読めなければ空文字を返し、呼ぶ側で止める
    def git(*args)
      out, status = Open3.capture2('git', *args)
      status.success? ? out.strip : ''
    end

    # 何コミット遅れているかを添える。履歴が浅い・祖先でない時は諦める（報告は続ける）。
    # running は Heroku の API 由来なのでシェルを通さない。
    # running が nil の時に呼ぶと `rev-list --count ..HEAD` が 0 を返し「0 コミット先」と嘘になるので、
    # 呼ぶ側で弾く（spec の「本番のコミットが分からない時」で固定）
    def behind_count(running, head)
      return nil if running.to_s.empty?

      out, status = Open3.capture2('git', 'rev-list', '--count', "#{running}..#{head}")
      status.success? && !out.strip.empty? ? out.strip : nil
    rescue StandardError
      nil
    end

    # @param behind [String, nil] 遅れているコミット数（分からなければ nil）
    def issue_body(verdict:, running:, head:, behind:)
      running_cell = running.to_s.empty? ? '分かりませんでした' : "`#{short(running)}`"
      behind_text  = behind ? "。main が #{behind} コミット先にいます" : ''

      <<~BODY
        ### _**※ このコメントは Claude Code が代筆しています。**_

        #{verdict[:message]}#{behind_text}

        | | |
        |---|---|
        | 本番で動いているコミット | #{running_cell} |
        | main の HEAD | `#{short(head)}` |
        | 確かめた時刻 | #{Time.now.getlocal('+09:00').strftime('%Y-%m-%d %H:%M JST')} |

        ### 見るところ

        配る経路が 3 つあるので、順に見ます。

        1. `Test & Deploy`（`test.yml`）に `event: push` の run があるか。無ければデプロイが呼ばれていません
        2. 直前のマージが `github-actions[bot]` なら、`dependabot.yml` の最後の step が `test.yml` を呼べたか
        3. `Daily Workflow`（`daily.yml`）の deploy は `db/news.yml` が変わった日だけ動きます。ここは頼りになりません
        4. run があって赤ならそのログ、緑なのに届いていないなら Heroku 側（`heroku releases`）

        ### この Issue の扱い

        - 直ったら**手で閉じてください**。揃っても**自動では閉じません**
        - ずれている間は毎日この本文が更新されます（新しい Issue は立ちません）
        - ロールバック中は「main が本番に無い」のが正しい状態ですが、鳴らしたままにしています
          （意図したずれと事故のずれを機械は区別できないので、いつまでかを忘れないための記録として残します）

        ### なぜこの Issue があるか

        #1973 は `github-actions[bot]` がマージしたため、マージコミットに `test.yml` の run がありません
        （GITHUB_TOKEN で起こした push は workflow を動かさない。#2025 で原因を修正）。そのコミットへの
        配達は翌朝の `daily.yml` だけで、その deploy は failure でした。
        **どちらの穴も「本番が main に追いついているか」を誰にも教えません。** それを毎朝見るのがこのセンサーです。
      BODY
    end

    # Issue は 1 本だけ持つ。無ければ立てて通知を出し、あれば本文を更新するだけにして
    # 毎日の通知を増やさない
    def report_issue(body)
      return puts('GH_TOKEN が無いので Issue は触りません') if ENV['GH_TOKEN'].to_s.empty?

      number = open_issue_number
      # 一覧が取れなかった時に立てると、既にある分と重複して毎日 1 本増える。
      # workflow は別に赤くなるので、ここは何もしないのが正しい
      return puts('Issue の一覧が取れなかったので、立ても更新もしません') if number == :unknown

      if number
        system('gh', 'issue', 'edit', number.to_s, '--body', body) or warn 'Issue の更新に失敗しました'
        puts "既にある Issue ##{number} の本文を更新しました"
      else
        system('gh', 'issue', 'create', '--title', ISSUE_TITLE, '--body', body) or warn 'Issue の作成に失敗しました'
      end
    end

    # `--search` は語の分割や絵文字で当たり外れがあるので使わない。open な Issue を
    # 列挙して題名の完全一致だけを見る（この Issue は 1 本しか持たない運用）。
    # シェルを通さないので、題名に何が入っていても引用を壊さない
    def open_issue_number
      out, status = Open3.capture2('gh', 'issue', 'list', '--state', 'open',
                                   '--limit', '100', '--json', 'number,title')
      unless status.success?
        warn 'Issue の一覧を取れなかったので、重複を避けられません。立てるのは見送ります'
        return :unknown
      end

      JSON.parse(out).find { |issue| issue['title'] == ISSUE_TITLE }&.fetch('number')
    rescue JSON::ParserError => e
      warn "Issue の一覧が読めませんでした: #{e.message}"
      :unknown
    end
  end
end

if $PROGRAM_NAME == __FILE__
  app   = ENV['HEROKU_APP'].to_s
  token = ENV['HEROKU_API_KEY'].to_s
  abort 'HEROKU_APP がありません（secrets.HEROKU_APP_NAME を渡してください）' if app.empty?
  abort 'HEROKU_API_KEY がありません' if token.empty?

  head      = VerifyRelease.git('rev-parse', 'HEAD')
  head_time = Time.at(VerifyRelease.git('log', '-1', '--format=%ct').to_i)
  # HEAD が読めないまま進むと、本番と「空のコミット」を比べて意味のない stale を立てる
  abort 'main の HEAD が読めませんでした（fetch-depth を確かめてください）' if head.empty?

  # センサー自身が落ちた時も Issue にする。run が赤くなるだけだと、その赤を見る人が
  # 「cron の行を最後に変更した人」のメールだけになり、「赤が出ても誰も見ない」形に戻る
  begin
    running = VerifyRelease.running_commit(app: app, token: token)
    verdict = VerifyRelease.judge(running: running, head: head, head_time: head_time, now: Time.now)
  rescue StandardError => e
    verdict = { status: :broken, message: "照合そのものに失敗しました: #{e.class}: #{e.message}" }
    running = nil
  end

  puts "#{verdict[:status]}: #{verdict[:message]}"
  exit 0 if %i[ok pending].include?(verdict[:status])

  behind = VerifyRelease.behind_count(running, head)
  VerifyRelease.report_issue(VerifyRelease.issue_body(verdict: verdict, running: running, head: head, behind: behind))
  warn "::error::#{verdict[:message]}"
  exit 1
end
