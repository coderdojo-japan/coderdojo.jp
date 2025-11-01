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
end