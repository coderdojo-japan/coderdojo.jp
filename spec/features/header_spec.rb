require 'rails_helper'

RSpec.feature "ヘッダー", type: :feature do
  before do
    visit "/"
  end

  describe "リンクをクリックする" do
    scenario "統計情報に飛ぶ" do
      all(:link_or_button, '統計情報').first.click
      expect(page).to have_selector 'h1', text:'統計情報'
    end
    scenario "近日開催の道場に飛ぶ" do
      click_link '近日開催の道場'
      expect(page).to have_selector 'h1', text:'📅 近日開催の道場'
    end
    scenario "Kataに飛ぶ" do
      all(:link_or_button, 'Kata').first.click
      expect(page).to have_selector 'h1', text:'📚 Kata'
    end
  end
end
