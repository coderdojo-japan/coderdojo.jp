require 'rails_helper'

# Bootstrap 3 の JS は、使う tooltip（と、その表示の切り替えに使う transition）だけを読む。
# 開閉（ヘッダーのメニュー・スマホの道場一覧）は layout.js で受け持つ。
# collapse.js を一緒に読むと、同じクリックで 2 回開閉して開かなくなる
RSpec.describe 'application.js の Bootstrap 3' do
  let(:source) { Rails.application.assets.find_asset('application.js').to_s }

  it 'tooltip と transition だけを読む' do
    expect(source).to include('Bootstrap: tooltip.js')
    expect(source).to include('Bootstrap: transition.js')
    expect(source).not_to include('Bootstrap: collapse.js')
    expect(source).not_to include('Bootstrap: modal.js')
  end

  # collapse.js も '[data-toggle="collapse"]' を含むので、layout.js の関数の名前で確かめる
  it '開閉は layout.js が扱う' do
    expect(source).to include('function toggleCollapse(')
  end
end
