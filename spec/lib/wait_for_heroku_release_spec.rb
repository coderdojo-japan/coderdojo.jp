require 'rails_helper'
require Rails.root.join('.github/scripts/wait_for_heroku_release')

# デプロイが本番に届いたかの判定。詳細はスクリプト冒頭のコメントと PR #1942 を参照。
RSpec.describe WaitForHerokuRelease do
  let(:sha) { 'c377d629aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' }

  def release(status:, version: 4074, description: "Deploy c377d629", current: true)
    { 'version' => version, 'status' => status, 'description' => description, 'current' => current }
  end

  describe '.verdict' do
    it 'succeeded なら届いたと判定する' do
      expect(described_class.verdict([release(status: 'succeeded')], sha)).to eq(:succeeded)
    end

    it 'failed なら届かなかったと判定する' do
      # release フェーズでの失敗。script/release.sh のどのステップで落ちてもここに出る
      expect(described_class.verdict([release(status: 'failed')], sha)).to eq(:failed)
    end

    it 'expired も届かなかったと判定する' do
      expect(described_class.verdict([release(status: 'expired')], sha)).to eq(:failed)
    end

    it 'pending なら待つ' do
      expect(described_class.verdict([release(status: 'pending')], sha)).to eq(:waiting)
    end

    it 'この commit のリリースがまだ無ければ待つ' do
      # Heroku がビルドをスキップした場合もここに留まり、最後はタイムアウトで落ちる
      others = [release(status: 'succeeded', description: 'Deploy 0123456')]
      expect(described_class.verdict(others, sha)).to eq(:waiting)
    end

    it '後から別のリリースが出ていても、届いた事実は変わらない' do
      # current を条件にすると、直後に別のデプロイが着地しただけで赤になる。
      # 本番に届いたかどうかが知りたいので current では判定しない
      expect(described_class.verdict([release(status: 'succeeded', current: false)], sha)).to eq(:succeeded)
    end

    it '短縮 SHA で照合する' do
      # 本番の description は "Deploy c377d629" の形（8 桁）。
      # 7 桁を前置として include? で探すため、桁数が変わっても一致する
      expect(described_class.verdict([release(status: 'succeeded', description: 'Deploy c377d629')], sha))
        .to eq(:succeeded)
      expect(described_class.verdict([release(status: 'succeeded', description: 'Deploy c377d62')], sha))
        .to eq(:succeeded)
    end

    it 'リリース一覧が空なら待つ' do
      # 取得に失敗した周回。一過性のエラーで CI を落とさない
      expect(described_class.verdict([], sha)).to eq(:waiting)
    end
  end
end
