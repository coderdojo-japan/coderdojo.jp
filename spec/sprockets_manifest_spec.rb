require 'rails_helper'

# 本番の dyno と Heroku のビルドは、前回のビルドで書き出した manifest を読んでから起動する。
# CI は manifest の無い状態で動くので、manifest を読む処理が壊れても気付けない。
# json 3.1.0 で JSON.parse が create_additions を受け付けなくなり、sprockets 4.2.2 の
# manifest の読み込みが ArgumentError になって、本番のビルドが止まった（sprockets 4.4.1 で直った）。
RSpec.describe 'Sprockets の manifest' do
  it '書き出し済みの manifest を読める' do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, '.sprockets-manifest-0123456789abcdef0123456789abcdef.json'), '{"files":{},"assets":{}}')

      expect { Sprockets::Manifest.new(Rails.application.assets, dir) }.not_to raise_error
    end
  end
end
