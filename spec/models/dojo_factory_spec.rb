require 'rails_helper'

# DojosController は開催日を共有している道場を ID の即値で束ねている
# (SHARED_EVENT_DATE_DOJOS)。テストで作る道場がその ID を引き当てると、
# 無関係な道場の開催日とリンクが行に混ざる。
#
# 採番の開始値は spec/rails_helper.rb の before(:suite) で進めている。
# その仕組みが外れたことを、ここで検出する。
RSpec.describe 'テストで作る道場の ID' do
  it '開催日を共有している道場の ID と衝突しない' do
    synced_ids = DojosController::SHARED_EVENT_DATE_DOJOS.to_a.flatten

    expect(create(:dojo).id).to be > synced_ids.max
  end

  it '実在する道場の ID と衝突しない' do
    max_real_id = Dojo.load_attributes_from_yaml.map { |dojo| dojo['id'].to_i }.max

    expect(create(:dojo).id).to be > max_real_id
  end
end
