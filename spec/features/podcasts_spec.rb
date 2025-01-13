require 'rails_helper'

RSpec.feature 'Podcasts', type: :feature do
  describe 'GET documents' do
    scenario 'Podcast index should be exist' do
      visit '/podcasts'
      expect(page).to have_selector('h1', text: 'DojoCast')
    end

    scenario 'Charter should be exist' do
      @podcast = create(:podcast)
      allow(@podcast).to receive(:exists?) { true }
      allow(@podcast).to receive(:exists?).with(offset: -1) { false }
      allow(@podcast).to receive(:content) { "title\n収録日: 2019/05/10\n..." }
      allow(Podcast).to  receive(:find_by).with(id: @podcast.id.to_s) { @podcast }

      visit "/podcasts/#{@podcast.id}"
      target = '← Top'
      expect(page).to have_selector('.episode h1#title')
      expect(page).to have_link target, href: '/podcasts'
      click_link target, match: :first
      expect(page).to have_selector('h1', text: 'DojoCast')
    end

    scenario 'Load doc file with absolute path' do
      @podcast = create(:podcast)
      allow(@podcast).to receive(:exists?) { true }
      allow(@podcast).to receive(:content) { "title\n収録日: 2019/05/10\n..." }
      allow(Podcast).to  receive(:find_by).with(id: @podcast.id.to_s) { @podcast }

      visit  "/podcasts/#{@podcast.id}"
      target = 'DojoCast'
      expect(page).to have_selector('.episode h1#title')
      expect(page).to have_link target, href: '/podcasts'
      click_link target, match: :first
      expect(page).to have_selector('h1', text: 'DojoCast')
    end
  end
end
