require 'rails_helper'

RSpec.feature "Top", type: :feature do
  describe "GET /" do
    scenario "Each section should exist" do
      visit "/"
      expect(page).to have_title 'CoderDojo Japan'
      expect(page).to have_text  '全国の道場'
      expect(page).to have_css   'section.sponsors_logo a[href]'
      expect(page).to have_text  '問い合わせ'
      expect(page).to have_text  '一般社団法人'
    end
  end
end
