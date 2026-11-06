require 'rails_helper'
require 'sentry/test_helper'

# Airbrake と並べて Sentry にも送る。rescue で捕まえて Rails.error.report した例外も
# Sentry に届くことを確かめる（config/initializers/sentry.rb の register_error_subscriber）
RSpec.describe 'Sentry への報告' do
  include Sentry::TestHelper

  before do
    setup_sentry_test
    allow(Airbrake).to receive(:notify)
  end
  after { teardown_sentry_test }

  it 'Rails.error.report で報告した例外を Sentry に送る' do
    Rails.error.report(RuntimeError.new('GitHub API に届かない'))
    expect(sentry_events.map { it.exception.values.first.value }).to include('GitHub API に届かない (RuntimeError)')
  end
end
