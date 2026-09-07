require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  # News関連のメソッドはNewsモデルに移動しました
  # spec/models/news_spec.rb を参照

  # og:url と Twitter カードの URL を組み立てる。
  #
  # == 経緯（2026/09/07）==
  # Host ヘッダに非 ASCII のバイト列が入ると 500 になっていた。
  #
  #   ActionView::Template::Error: incompatible character encodings: UTF-8 and BINARY
  #     app/views/layouts/application.html.erb:21
  #
  # Puma が env に入れる HTTP_HOST は ASCII-8BIT で、request.url もその
  # エンコーディングを引き継ぐ。それを UTF-8 のビューに結合すると落ちる。
  # このアプリは config.hosts を設定しておらず、Host は検証されない。
  describe '#full_url' do
    context '引数が空のとき' do
      it 'リクエストの URL を返す' do
        allow(helper).to receive(:request).and_return(double(url: 'https://coderdojo.jp/kata'))
        expect(helper.full_url('')).to eq 'https://coderdojo.jp/kata'
      end

      it '非 UTF-8 のバイト列を含んでいても、ビューに埋め込める文字列を返す' do
        broken = "https://www.coderdojo.jp\xFF/kata".dup.force_encoding(Encoding::ASCII_8BIT)
        allow(helper).to receive(:request).and_return(double(url: broken))

        result = helper.full_url('')
        expect(result.encoding).to eq Encoding::UTF_8
        expect(result).to be_valid_encoding
        expect { +'' << result }.not_to raise_error
      end
    end

    context '引数がパスのとき' do
      it '本番のホストを補って返す' do
        expect(helper.full_url('/kata')).to eq 'https://coderdojo.jp/kata'
      end
    end

    context '引数が URL のとき' do
      it 'そのまま返す' do
        expect(helper.full_url('https://news.coderdojo.jp/')).to eq 'https://news.coderdojo.jp/'
      end
    end
  end
end
