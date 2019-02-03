require 'rails_helper'

RSpec.feature "Docs", type: :feature do
  describe "GET documents" do
    scenario "Document index should be exist" do
      visit docs_path
      expect(page).to have_http_status(:success)
      expect(page).to have_css 'section.keiyaku a[href]', count: Document.all.count
    end
    scenario "Charter should be exist" do
      visit doc_path('charter')
      expect(page).to have_http_status(:success)
    end
    scenario "Load doc file with absolute path" do
      visit "#{docs_path}/"
      expect(page).to have_http_status(:success)
      expect(page).to have_link 'コントリビューター行動規範', href: "/docs/code-of-conduct"
      click_link 'コントリビューター行動規範'
      expect(page).to have_http_status(:success)
    end
  end
end
