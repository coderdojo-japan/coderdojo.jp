require 'rails_helper'

RSpec.feature "Podcasts", type: :feature do
  describe "GET documents" do
    scenario "Podcast index should be exist" do
      visit "/podcasts"
      expect(page).to have_http_status(:success)
    end

    scenario "Charter should be exist" do
      visit "/podcasts/1"
      target = '← 目次へ'
      expect(page).to have_http_status(:success)
      expect(page).to have_link target, href: "/podcasts"
      click_link target
      expect(page).to have_http_status(:success)
    end

    scenario "Load doc file with absolute path" do
      visit  "/podcasts/10"
      target = '目次へ戻る'
      expect(page).to have_http_status(:success)
      expect(page).to have_link target, href: "/podcasts"
      click_link target
      expect(page).to have_http_status(:success)
    end
  end
end
