require 'rails_helper'

RSpec.feature "Contracts", type: :feature do
  describe "GET /mou" do
    scenario "Contract index should be exist" do
      visit "/mou"
      expect(page).to have_http_status(:success)
      expect(page).to have_css 'section.keiyaku a[href]', count:Contract.all.count
    end
    scenario "Teikan should be exist" do
      visit "/mou/charter"
      expect(page).to have_http_status(:success)
    end
  end
end
