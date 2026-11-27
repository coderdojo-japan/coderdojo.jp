require 'rails_helper'

# /stats の地図は、地方の県の基準の点（PREFECTURE_CENTERS）の平均に地方名を置き、点の無い県があると
# KeyError で /stats 全体が 500 になる。seed に県を足した時に、点を足し忘れたまま本番に出ないようにする
RSpec.describe JapanMapHelper do
  it 'seed のすべての都道府県に、地図の基準の点がある' do
    expect(JapanMapHelper::PREFECTURE_CENTERS.keys).to match_array(Prefecture.pluck(:id))
  end
end
