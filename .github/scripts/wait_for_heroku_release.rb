#!/usr/bin/env ruby
# frozen_string_literal: true
#
# デプロイが本番に届いたかを、Heroku のリリース状態で確認する。
#
# GitHub Actions の deploy ジョブが success でも、本番が変わっていないことがある。
# 2026年8月から10月にかけて、heroku-deploy v4 が push 先を refs/head/main と
# 組み立てていたために Heroku がビルドをスキップし、それでも Actions は success を
# 返し続けていた（PR #1942）。push が成功すれば緑になるため、緑は配送の成功でしかない。
#
# 「本番の配信物を見る」方式も検討したが、採れなかった。script/release.sh は
# news:upsert を dojo_event_services:upsert / podcasts:upsert より先に実行し、
# release dyno は稼働中の旧 dyno と同じ DB を使う。後半のステップが落ちると
# Heroku はリリースを中止するが、DB には新しいデータが入っているため、
# 旧コードのまま配信物だけが期待どおりに見えてしまう。
#
# リリースの status なら release.sh のどこで落ちても failed になる。
# https://devcenter.heroku.com/articles/release-phase

require 'json'

module WaitForHerokuRelease
  TIMEOUT  = 900 # 秒。ビルドと release フェーズの合計を見込む
  INTERVAL = 15  # 秒

  module_function

  # リリース一覧から、この commit の配送がどうなったかを判定する。
  #
  #   :succeeded => 本番に届いた
  #   :failed    => 届かなかった（ビルドか release フェーズで失敗）
  #   :waiting   => まだ分からない（リリース未作成、またはビルド中）
  #
  # status の値は failed / pending / succeeded / expired の 4 つ。
  # https://api.heroku.com/schema
  def verdict(releases, sha)
    release = find_release(releases, sha)
    return :waiting if release.nil?

    case release['status']
    when 'succeeded'         then :succeeded
    when 'failed', 'expired' then :failed
    else :waiting
    end
  end

  # description は "Deploy c377d629" の形。桁数に依存しないよう前置で探す
  def find_release(releases, sha)
    releases.find { |r| r['description'].to_s.include?(sha[0, 7]) }
  end

  # Platform API を直接叩かず CLI を使う。heroku-deploy が ~/.netrc を書くうえ、
  # HEROKU_API_KEY でも認証でき、ubuntu-22.04 には CLI が入っている
  # （heroku-deploy v3 自身が heroku git:remote を前提にしている）
  def fetch_releases(app)
    out = `heroku releases --json --app #{app} 2>/dev/null`
    return [] unless $?.success?

    JSON.parse(out)
  rescue StandardError => e
    # 一過性の失敗で CI を落とさない。次の周回で取り直す
    warn "  リリース一覧を取得できませんでした（再試行します）: #{e.class}"
    []
  end
end

if __FILE__ == $PROGRAM_NAME
  app = ENV.fetch('HEROKU_APP_NAME')

  # GITHUB_SHA ではなく、チェックアウトした HEAD を使う。
  # daily.yml は schedule 起動で、GITHUB_SHA は daily ジョブが db/news.yml を
  # push する前の main を指す。それでは 1 つ前のリリースに一致して緑になる
  sha = `git rev-parse HEAD`.strip
  puts "デプロイした commit: #{sha[0, 7]}"

  started = Time.now
  loop do
    releases = WaitForHerokuRelease.fetch_releases(app)
    release  = WaitForHerokuRelease.find_release(releases, sha)

    case WaitForHerokuRelease.verdict(releases, sha)
    when :succeeded
      puts "✅ v#{release['version']} として本番に届きました（#{release['description']}）"
      puts '   （その後さらに別のリリースが出ています）' unless release['current']
      exit 0
    when :failed
      warn "❌ v#{release['version']} が #{release['status']} です（#{release['description']}）"
      warn "   詳細: heroku releases:output v#{release['version']} --app #{app}"
      exit 1
    end

    if Time.now - started > WaitForHerokuRelease::TIMEOUT
      warn "❌ #{WaitForHerokuRelease::TIMEOUT} 秒待っても #{sha[0, 7]} のリリースが現れませんでした。"
      warn '   Heroku がビルドをスキップした可能性があります。deploy ジョブのログで'
      warn '   push 先が refs/heads/main になっているかを確認してください。'
      exit 1
    end

    print '.'
    $stdout.flush
    sleep WaitForHerokuRelease::INTERVAL
  end
end
