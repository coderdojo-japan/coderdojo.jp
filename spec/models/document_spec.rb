require 'rails_helper'

RSpec.describe Document do
  describe '#initialize' do
    it 'ActiveStorage::Filename を使用してファイル名をサニタイズする' do
      doc = Document.new("test_file")
      expect(doc.filename).to eq("test_file")
    end

    it 'パストラバーサル攻撃を防ぐ' do
      doc = Document.new("../../../etc/passwd")
      # ActiveStorage::Filename はパス区切り文字 / を - に変換
      expect(doc.filename).to eq("..-..-..-etc-passwd")
    end

    it 'null バイトが含まれる場合もそのまま処理する' do
      doc = Document.new("test\x00file")
      # ActiveStorage::Filename は null バイトをそのまま保持
      expect(doc.filename).to eq("test\x00file")
    end

    it 'バックスラッシュを処理する' do
      doc = Document.new("..\\..\\..\\windows\\system32")
      # バックスラッシュは - に変換される
      expect(doc.filename).to eq("..-..-..-windows-system32")
    end
  end

  describe '#exist?' do
    it '存在するドキュメントの場合 true を返す' do
      allow(Document).to receive(:all).and_return([
        double(filename: 'existing')
      ])
      doc = Document.new('existing')
      expect(doc.exist?).to be true
    end

    it '存在しないドキュメントの場合 false を返す' do
      allow(Document).to receive(:all).and_return([
        double(filename: 'existing')
      ])
      doc = Document.new('nonexistent')
      expect(doc.exist?).to be false
    end

    it 'サニタイズ後のファイル名で許可リストをチェックする' do
      allow(Document).to receive(:all).and_return([
        double(filename: '..-..-..-etc-passwd')
      ])
      doc = Document.new('../../../etc/passwd')
      # サニタイズ後の名前で存在チェック
      expect(doc.exist?).to be true
    end
  end

  describe '#updated_at' do
    # 本番では GitHub API から最終更新日を取る。届かなくても仮の日付で表示は続けるが、失敗は報告する
    it 'GitHub API に届かなかったら仮の日付を返し、例外を報告する' do
      error = SocketError.new('getaddrinfo')
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(Net::HTTP).to receive(:get).and_raise(error)
      allow(Rails.error).to receive(:report)

      expect(Document.new('kata').updated_at).to eq '2020-02-02T12:34:56+09:00'
      expect(Rails.error).to have_received(:report).with(error)
    end
  end

  describe 'meta descriptions' do
    it 'すべての公開ドキュメントの meta description に HTML タグが含まれていないこと' do
      # 全ドキュメントファイルを取得（記録用ページ "_" で始まるものを除く）
      doc_files = Dir.glob('public/docs/*.md').map { |f| File.basename(f, '.*') }
      public_docs = doc_files.reject { |f| f.start_with?('_') }

      # 各ドキュメントの meta description をチェック
      problematic_docs = []
      public_docs.each do |filename|
        doc = Document.new(filename)
        description = doc.description

        # HTML タグまたは HTML エンティティが含まれている場合は問題あり
        if description.match?(/<|&lt;|&gt;|&amp;/)
          problematic_docs << {
            filename: filename,
            description: description[0..100] # 最初の100文字
          }
        end
      end

      # エラーメッセージを詳細に表示
      if problematic_docs.any?
        error_message = "\n以下のドキュメントの meta description に HTML タグが含まれています:\n"
        problematic_docs.each do |doc|
          error_message += "\n❌ #{doc[:filename]}\n"
          error_message += "   Description: #{doc[:description]}...\n"
        end
        fail error_message
      end

      expect(problematic_docs).to be_empty
    end
  end
end