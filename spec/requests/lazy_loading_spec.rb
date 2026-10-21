require 'rails_helper'

# 画像の遅延読み込みは、JS のライブラリ（lazysizes）ではなく HTML 標準の loading="lazy" で行う
RSpec.describe '画像の遅延読み込み', type: :request do
  it 'image_tag の画像は、既定で loading="lazy" になる' do
    get root_path
    images = Nokogiri::HTML(response.body).css('img')

    expect(images).not_to be_empty
    expect(images.select { it['loading'] == 'lazy' }).not_to be_empty
  end

  it '画面の最初に見えるカバー画像は、遅延読み込みにしない' do
    get root_path
    cover = Nokogiri::HTML(response.body).at('section.cover img')

    expect(cover['loading']).to eq 'eager'
    expect(cover['fetchpriority']).to eq 'high'
  end

  it 'lazysizes を読み込まない' do
    get root_path

    expect(response.body).not_to include('lazysizes')
  end

  it 'lazysizes の書き方（data-src・lazyload）が残っていない' do
    files = Dir[Rails.root.join('app/views/**/*.erb')] + Dir[Rails.root.join('public/docs/*.md')]
    expect(files).not_to be_empty

    leftovers = files.select { File.read(it).match?(/data-src=|\blazyload\b/) }
    expect(leftovers.map { it.delete_prefix("#{Rails.root}/") }).to be_empty
  end
end
