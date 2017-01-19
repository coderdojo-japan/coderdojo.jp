require 'rails_helper'

feature "Sotechsha"  do
  
  describe "GET /sotechsha/num" do
    scenario "Quizzes should be permalink" do
      (0..6).each do |num|
        visit "/sotechsha/#{num}"
        ch = num.to_s.tr("0-9", "０-９").gsub("０", "序")
        expect(page).to have_selector "h1", text: "#{ch}章課題"
      end
    end
  end

  describe "GET /sotechsha" do
    scenario "SoTechSha link should be rendered" do
      visit "/sotechsha"
      expect(page).to have_selector "a[href]", count: 24
      # topimg,snsbtn
      expect(page).to have_selector "img", count: 2
    end
  end
  
  describe "GET /sotechsha/1" do
    scenario "Datetime should be formatted" do
      visit "/sotechsha/1"
      expect(page).to have_selector ".h5", text: /\d{4}年\d{2}月\d{2}日$/
    end
  end

end
