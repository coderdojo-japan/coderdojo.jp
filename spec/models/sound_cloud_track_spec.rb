require 'rails_helper'

RSpec.describe SoundCloudTrack, :type => :model do
  before do
    @soundcloud_track = create(:soundcloud_track)
  end

  # instance methods
  it 'path' do
    expect(@soundcloud_track.path).to eq("public/podcasts/#{@soundcloud_track.id}.md")
  end

  it 'url' do
    expect(@soundcloud_track.url).to eq("/podcasts/#{@soundcloud_track.id}")
  end

  describe 'exists?(offset: 0)' do
    it '\u0000 を含む ⇒ false' do
      allow(@soundcloud_track).to receive(:path) { "public/podcasts/\u0000" }

      expect(@soundcloud_track.exists?).to eq(false)
    end

    context 'offset 省略' do
      before :each do
        allow(File).to receive(:exists?) { false }
      end

      it 'ファイルあり ⇒ true' do
        allow(File).to receive(:exists?).with("public/podcasts/#{@soundcloud_track.id}.md") { true }

        expect(@soundcloud_track.exists?).to eq(true)
      end

      it 'ファイルなし ⇒ false' do
        expect(@soundcloud_track.exists?).to eq(false)
      end
    end

    context 'offset 指定' do
      before :each do
        allow(File).to receive(:exists?) { false }
      end

      it 'ファイルあり ⇒ true' do
        allow(File).to receive(:exists?).with("public/podcasts/#{@soundcloud_track.id + 1}.md") { true }

        expect(@soundcloud_track.exists?(offset: 1)).to eq(true)
      end

      it 'ファイルなし ⇒ false' do
        expect(@soundcloud_track.exists?(offset: 1)).to eq(false)
      end
    end
  end

  describe 'content' do
    before :each do
      @content_body = "Podcast Title\n収録日: 2019/05/10\n概要説明..."
      allow(File).to receive(:read) { @content_body }
    end

    it 'ファイル存在 ⇒ ファイルから読み込み' do
      allow(@soundcloud_track).to receive(:exists?) { true }

      expect(@soundcloud_track.content).to eq(@content_body)
    end

    it 'ファイルなし ⇒ 空文字列' do
      allow(@soundcloud_track).to receive(:exists?) { false }

      expect(@soundcloud_track.content).to eq('')
    end
  end
end
