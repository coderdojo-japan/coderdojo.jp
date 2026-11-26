require 'rails_helper'

# Bootstrap 3 の JS は読まない。開閉（ヘッダーのメニュー・スマホの道場一覧）は layout.js で受け持ち、
# tooltip は data-tooltip 属性を CSS で描く（spec/requests/tooltip_spec.rb）
RSpec.describe 'application.js の Bootstrap 3' do
  let(:source) { Rails.application.assets.find_asset('application.js').to_s }

  it 'Bootstrap 3 の JS を読まない' do
    expect(source).not_to include('Bootstrap: ')
  end

  # collapse.js も '[data-toggle="collapse"]' を含むので、layout.js の関数の名前で確かめる
  it '開閉は layout.js が扱う' do
    expect(source).to include('function toggleCollapse(')
  end
end
