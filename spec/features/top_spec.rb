require 'rails_helper'

RSpec.feature "Top", type: :feature do
  describe "GET /" do
    scenario "Sponser links should be exist" do
      visit "/"
      expect(page).to have_css 'section.sponsors_logo a[href]', count: 7
    end
  end
end
