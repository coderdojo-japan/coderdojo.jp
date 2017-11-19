# -*- coding: utf-8 -*-
require 'rails_helper'
include Scrivito::ControllerHelper

RSpec.xfeature "Users", type: :feature do
  subject { page }

  describe "log in" do
    let!(:login)     { LoginPage.instance }
    let(:login_path) { login.slug + login.id }

    before do
      visit '/kata'
      visit login_path
    end

    describe "with invalid information" do
      before do
        fill_in "email",    with: ''
        fill_in "password", with: ''
        click_button 'ログイン'
      end
      it { should have_content('ログイン') }
      it { should_not have_content('道場情報まとめ') }
    end

    describe "with valid information" do
      before do
        fill_in "email",    with: ENV["SCRIVITO_EMAIL"]
        fill_in "password", with: ENV["SCRIVITO_PASSWORD"]
        click_button 'ログイン'
      end
      it { should have_content('道場情報まとめ') }
    end
  end
end
