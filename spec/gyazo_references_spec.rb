require 'rails_helper'

# ページに表示する画像やリンクは、外部の画像ホスティングに頼らずサイト内に置く。
# 対象はページとして配信するファイル（ビュー・docs・podcasts）。コードのコメントや
# db/dojos.yml の note（根拠の記録）は表示されないので対象外。
RSpec.describe 'ページから参照する画像' do
  files = Dir.glob(Rails.root.join('{app/views,public/docs,public/podcasts}/**/*.{erb,md}').to_s)

  it 'gyazo.com を参照しない' do
    offenders = files.select { |path| File.read(path).include?('gyazo.com') }
                     .map { |path| Pathname(path).relative_path_from(Rails.root).to_s }
    expect(offenders).to eq([])
  end

  it '参照しているサイト内の画像がすべて存在する' do
    missing = files.flat_map { |path| File.read(path).scan(%r{/img/[\w.-]+\.(?:png|jpg)}) }
                   .uniq
                   .reject { |src| Rails.root.join("public#{src}").exist? }
    expect(missing).to eq([])
  end
end
