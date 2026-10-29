require 'rails_helper'

RSpec.describe SlackNotifier do
  let(:webhook_url) { 'https://hooks.slack.example.com/services/T000/B000/XXXX' }

  # 失敗しても呼び出し元の処理は止めないが、失敗は報告する。
  # ログに書くだけだと、通知が届かなくなっても誰も気づけない
  it '送れなかったら false を返し、例外を報告する' do
    error = Net::OpenTimeout.new('execution expired')
    allow(Net::HTTP).to receive(:start).and_raise(error)
    allow(Rails.error).to receive(:report)

    expect(described_class.post_message('統計を集計しました', webhook_url)).to be false
    expect(Rails.error).to have_received(:report).with(error)
  end
end
