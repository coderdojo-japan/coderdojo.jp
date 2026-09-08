require 'rails_helper'

# DojosController#activity は開催日を共有する道場を sync_event_date に
# ID の即値で渡している。テストで作る道場がその ID を引き当てると、
# 無関係な道場の開催日とリンクが行に混ざる。
#
# 採番の開始値は spec/rails_helper.rb の TEST_DOJO_ID_START で決めている。
# 経緯は PR #1919 を参照。
RSpec.describe 'テストで作る道場の ID' do
  # 開始値そのものを見る。DB のシーケンスの現在値に左右されないので、
  # 道場が増えて開始値を追い越したときに、実行環境によらず落ちる。
  it '採番の開始値が、実在する道場の ID より大きい' do
    max_real_id = Dojo.load_attributes_from_yaml.map { |dojo| dojo['id'].to_i }.max

    expect(TEST_DOJO_ID_START).to be > max_real_id
  end

  # 開始値を適用する before(:suite) が外れたことを検出する。
  #
  # 閾値に実在の最大 ID ではなく開始値を使う。実在の最大 ID にすると、
  # 「スイートが作る道場の数 < 実在の最大 ID」が崩れた時点で、
  # 最後に走った example だけ通ってしまう（順序依存になる）。
  #
  # なお、シーケンスが既に進んでいる環境では通ってしまう。
  # 実質的な関門は、毎回まっさらな DB で走る CI になる。
  it '実際に採番される ID が、開始値以上になる' do
    expect(create(:dojo).id).to be >= TEST_DOJO_ID_START
  end
end
