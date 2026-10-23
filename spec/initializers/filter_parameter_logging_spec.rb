require 'rails_helper'

# ログ（Heroku のログを含む）に、申請者の個人情報を平文で残さない。
# /stretch3 は個人情報を受け取らなくなったが、古いフォームや直接の送信で名前が届くことはある
RSpec.describe 'filter_parameter_logging' do
  let(:filter) { ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters) }

  it '保護者と利用者の名前、メールアドレスをログで隠す' do
    filtered = filter.filter('stretch3' => {
      'email' => 'parent@example.com', 'parent_name' => '保護者', 'participant_name' => '参加者'
    })

    expect(filtered['stretch3'].values).to all(eq('[FILTERED]'))
  end

  it '道場の選択はログに残す（調べる時に要る）' do
    expect(filter.filter('stretch3' => { 'dojo_id' => '1' })['stretch3']['dojo_id']).to eq('1')
  end
end
