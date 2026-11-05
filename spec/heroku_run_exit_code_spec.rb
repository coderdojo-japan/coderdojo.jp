require 'rails_helper'

# GitHub Actions から `heroku run` で本番のタスクを動かしている（daily.yml・weekly.yml）。
# `heroku run` は `--exit-code` を付けないと、dyno の中でコマンドが失敗しても 0 で終わる。
# ジョブは緑のままになり、Actions の画面だけでは失敗に気づけない。
# 2026-11-05 に upcoming_events:aggregation が connpass の 429 で止まったが、Daily Workflow は success だった。
#   https://devcenter.heroku.com/articles/heroku-cli-commands#heroku-run
RSpec.describe 'heroku run in workflows' do
  let(:calls) do
    Rails.root.glob('.github/workflows/*.yml').flat_map { |path|
      path.readlines.filter_map.with_index(1) { |line, no|
        "#{path.basename}:#{no}: #{line.strip}" if line.match?(/\bheroku run\b/) && !line.lstrip.start_with?('#')
      }
    }
  end

  it 'heroku run の呼び出しが見つかる' do
    # 書き方が変わって 1 件も拾えなくなった時に、下の検査が素通りしないようにする
    expect(calls).not_to be_empty
  end

  it 'すべての heroku run に --exit-code が付いている' do
    missing = calls.reject { |call| call.include?('--exit-code') }
    expect(missing).to be_empty, "--exit-code の無い heroku run:\n#{missing.join("\n")}"
  end
end
