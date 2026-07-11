require 'rails_helper'

# Ruby のバージョンは .ruby-version を単一の真実の源とし、
# Gemfile (ruby file:) と CI (ruby-version: .ruby-version) はそれを参照している。
# 一方 Dockerfile の FROM だけは Docker の仕様上ファイルを読めず、ベタ書きせざるを得ない。
# そのため、両者がズレたまま気付かない事故を防ぐテストを置いている。
#
# 完全 DRY 化（ARG + build-arg）を見送った理由など、検討の経緯は PR #1836 を参照。
# https://github.com/coderdojo-japan/coderdojo.jp/pull/1836
RSpec.describe 'Ruby version consistency' do
  let(:ruby_version) { Rails.root.join('.ruby-version').read.strip }

  it 'Dockerfile の FROM が .ruby-version と一致する' do
    from_line = Rails.root.join('Dockerfile').read[/\AFROM ruby:(\S+)/, 1]

    expect(from_line).to eq(ruby_version),
      "Dockerfile の Ruby (#{from_line.inspect}) が .ruby-version (#{ruby_version.inspect}) と一致しません。" \
      '両方を同じバージョンに更新してください。'
  end
end
