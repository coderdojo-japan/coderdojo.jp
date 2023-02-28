# -*- coding: utf-8 -*-
require 'rails_helper'

RSpec.feature "News", type: :feature do
  describe "GET /news/2016/12/12/new-backend" do
    scenario "Title should be formatted" do
      visit "/docs/post-backend-update-history"
      expect(page).to have_title "CoderDojo Japan のバックエンド刷新"
    end
  end
end
