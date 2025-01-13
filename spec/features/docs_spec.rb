require 'rails_helper'

RSpec.feature "Docs", type: :feature do
  describe "GET documents" do
    scenario "Document index should be exist" do
      visit docs_path
      expect(page).to have_selector('h2', text: 'CoderDojo 資料集')
      expect(page).to have_css('section.docs a[href]', minimum: 1)
    end

    scenario "Charter should be exist" do
      visit docs_path
      within('section.docs') do
        expect(page).to have_link 'CoderDojo 憲章', href: "/docs/charter"
        click_link 'CoderDojo 憲章'
      end
      expect(page).to have_selector('h1', text: 'CoderDojo 憲章')
    end

    scenario "Load doc file with absolute path" do
      visit "/docs/code-of-conduct"
      expect(page).to have_selector('h1', text: 'コントリビューター行動規範')
    end
  end
end
