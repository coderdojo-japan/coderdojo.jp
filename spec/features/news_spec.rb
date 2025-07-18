# -*- coding: utf-8 -*-
require 'rails_helper'

RSpec.feature "NewsSection", type: :feature do
  let!(:news_item) { create(:news) }

  scenario "ニュースセクションにニュース項目が表示される" do
    visit root_path(anchor: 'news')

    within 'section#news' do
      expect(page).to have_link(href: news_item.url)
      expect(page).to have_content(news_item.title)
      expect(page).to have_selector("a[target='_blank']")
    end
  end
end
