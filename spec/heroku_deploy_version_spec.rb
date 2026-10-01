require 'rails_helper'

# Heroku へのデプロイは test.yml (main への push) と daily.yml (毎朝のニュース取得) の
# 2 経路あり、どちらも akhileshns/heroku-deploy を使っている。
#
# このアクションの v4 は push 先を refs/head/main と組み立てる (正しくは refs/heads/main)。
# Heroku は main への push と認識できずビルドをスキップするが、push 自体は成功するため
# Actions には success と表示され、デプロイされていないことに気付けない。
#
# PR #1847 / #1848 で test.yml は v3 に戻したが daily.yml が v4 のまま残り、
# 毎朝のニュース取得のデプロイが 8/2 から 10/1 まで止まっていた (PR #1942)。
# 片方だけ直す事故を繰り返さないよう、全経路が同じ版であることをここで守る。
#
# 上流が直って版を上げる時は、このテストも同じ PR で更新する。
# 意図した更新なのか取り残しなのかを、その場で判断させるのが目的。
RSpec.describe 'Heroku deploy action version consistency' do
  PINNED_VERSION = 'v3.15.15'.freeze

  let(:workflows) { Rails.root.glob('.github/workflows/*.yml') }

  let(:used_versions) do
    workflows.flat_map { |path|
      path.read.scan(%r{uses:\s*akhileshns/heroku-deploy@(\S+)}).flatten
          .map { |version| [path.basename.to_s, version] }
    }
  end

  it 'デプロイ経路が 2 つとも見つかる' do
    # 経路が増減した時に気付けるようにする。
    # ファイル名を変えただけでテストが素通りするのを防ぐため
    expect(used_versions.map(&:first)).to contain_exactly('daily.yml', 'test.yml')
  end

  it 'すべての経路が同じ版に固定されている' do
    mismatched = used_versions.reject { |_, version| version == PINNED_VERSION }

    expect(mismatched).to be_empty,
      "heroku-deploy の版が #{PINNED_VERSION} と違います: " +
      mismatched.map { |file, version| "#{file} (#{version})" }.join(', ') +
      '。v4 は push 先を refs/head/main と組み立てるため、Heroku がビルドをスキップします。'
  end
end
