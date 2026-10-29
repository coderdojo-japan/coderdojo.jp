require 'rails_helper'

# rescue で捕まえた例外は Rails.error.report で報告し、送り先（Airbrake）は
# 購読者の側で決める。送り先を替える時は購読者だけを差し替える
RSpec.describe AirbrakeErrorSubscriber do
  let(:error) { RuntimeError.new('GitHub API に届かない') }

  before { allow(Airbrake).to receive(:notify) }

  it 'Rails.error.report で報告した例外を Airbrake に送る' do
    Rails.error.report(error)
    expect(Airbrake).to have_received(:notify).with(error, hash_including(severity: :warning))
  end

  # 捕まえていない例外は、Airbrake の Rack ミドルウェアが既に送っている
  it '捕まえていない例外は送らない' do
    Rails.error.report(error, handled: false)
    expect(Airbrake).not_to have_received(:notify)
  end
end
