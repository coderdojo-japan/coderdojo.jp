require 'rails_helper'

# 集計の失敗は #coderdojo-error に、成功の知らせは #coderdojo-news に届ける。
# 失敗が news に流れると、エラーの通知と別の場所に散らばり、バックトレースが news を読む人の目に触れる
RSpec.describe '集計の通知の宛先' do
  let(:news_hook)  { 'https://hooks.example.com/news' }
  let(:error_hook) { 'https://hooks.example.com/error' }
  let(:exception)  { StandardError.new('boom').tap { it.set_backtrace(['lib/example.rb:1']) } }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('SLACK_HOOK_URL').and_return(news_hook)
    allow(ENV).to receive(:[]).with('SLACK_ERROR_HOOK_URL').and_return(error_hook)
    allow(SlackNotifier).to receive(:post_message)
    allow($stdout).to receive(:puts)
  end

  it '統計の集計の失敗は SLACK_ERROR_HOOK_URL に送る' do
    Statistics::Aggregation::Notifier.notify_failure('2026/11/01', '2026/11/07', 'connpass', nil, exception)
    expect(SlackNotifier).to have_received(:post_message).with(/エラーが発生しました/, error_hook)
  end

  it '統計の集計の成功は SLACK_HOOK_URL に送る' do
    Statistics::Aggregation::Notifier.notify_success('2026/11/01', '2026/11/07', 'connpass', nil)
    expect(SlackNotifier).to have_received(:post_message).with(/集計を行いました/, news_hook)
  end

  it '近日開催イベントの収集の失敗は SLACK_ERROR_HOOK_URL に送る' do
    UpcomingEvents::Aggregation::Notifier.notify_failure('connpass', exception)
    expect(SlackNotifier).to have_received(:post_message).with(/エラーが発生しました/, error_hook)
  end
end
