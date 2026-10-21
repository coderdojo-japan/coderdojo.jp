require 'rails_helper'

RSpec.feature "Top", type: :feature do
  describe "GET /" do
    scenario "Each section should exist" do
      visit "/"
      expect(page).to have_title 'CoderDojo Japan'
      expect(page).to have_text  '日本各地の道場'
      expect(page).to have_css   'section.partners_logo a[href]'
      expect(page).to have_text  '問い合わせ'
      expect(page).to have_text  '一般社団法人'
    end

    # カバー画像は画面の最初に見える一番大きな要素（LCP）なので、遅延読み込みにせず最初から本番の画像を読む
    scenario "The cover image is loaded first" do
      visit "/"
      cover = find('section.cover img')
      expect(cover[:src]).to end_with '/coderdojo-japan_cover.webp'
      expect(cover[:loading]).to eq 'eager'
      expect(cover[:fetchpriority]).to eq 'high'
    end
  end
end
