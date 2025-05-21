# frozen_string_literal: true

RSpec.configure do |config|
  # テスト中の不要な sleep を無効化して高速化する
  config.before(:each) do
    allow_any_instance_of(EventService::Providers::Connpass  ).to receive(:sleep)
    allow_any_instance_of(EventService::Providers::Doorkeeper).to receive(:sleep)
  end
end
