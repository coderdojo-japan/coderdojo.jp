require 'rails_helper'

# このアプリは添付ファイル（has_one_attached など）を使わず、画像の加工もしない。
# 加工の仕組みが有効なままだと、image_processing gem が無いという WARN が起動のたびに出る
RSpec.describe 'Active Storage の設定' do
  it '画像の加工（variant）を無効にしている' do
    expect(ActiveStorage.variant_processor).to eq :disabled
  end
end
