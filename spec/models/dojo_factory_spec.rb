require 'rails_helper'

# DojosController は開催日を共有している道場を ID の即値で束ねている
# (SHARED_EVENT_DATE_DOJOS)。テストで作る道場がその ID を引き当てると、
# 無関係な道場の開催日とリンクが行に混ざる。
#
# 採番の開始値は spec/rails_helper.rb の TEST_DOJO_ID_START で決めている。
RSpec.describe 'テストで作る道場の ID' do
  let(:synced_ids)  { DojosController::SHARED_EVENT_DATE_DOJOS.to_a.flatten }
  let(:max_real_id) { Dojo.load_attributes_from_yaml.map { |dojo| dojo['id'].to_i }.max }

  # 開始値そのものを見る。DB のシーケンスの現在値に左右されないので、
  # 道場が増えて開始値を追い越したときに、実行環境によらず落ちる。
  describe '採番の開始値' do
    it '開催日を共有している道場の ID より大きい' do
      expect(TEST_DOJO_ID_START).to be > synced_ids.max
    end

    it '実在する道場の ID より大きい' do
      expect(TEST_DOJO_ID_START).to be > max_real_id
    end
  end

  # 開始値を適用する before(:suite) が外れたことを検出する。
  # ただしシーケンスが既に進んでいる環境では通ってしまうため、
  # 実質的な関門は毎回まっさらな DB で走る CI になる。
  describe '実際に採番される ID' do
    it '実在する道場の ID と衝突しない' do
      expect(create(:dojo).id).to be > max_real_id
    end
  end
end
