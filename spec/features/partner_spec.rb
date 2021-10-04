require 'rails_helper'

RSpec.feature "Partner", type: :feature do
  describe "GET /" do
    scenario "Title section should exist" do
      visit "/partnership"
      expect(page).to have_title 'パートナーシップのご案内'
    end
  end
end
