require 'rails_helper'

RSpec.feature 'Podcasts', type: :feature do
  describe 'GET documents' do
    scenario 'Podcast index should be exist' do
      visit '/podcasts'
      expect(page).to have_http_status(:success)
    end

    scenario 'Charter should be exist' do
      @soundcloud_track = create(:soundcloud_track)
      allow(@soundcloud_track).to receive(:exists?) { true }
      allow(@soundcloud_track).to receive(:exists?).with(offset: -1) { false }
      allow(@soundcloud_track).to receive(:content) { "title\n収録日: 2019/05/10\n..." }
      allow(SoundCloudTrack).to receive(:find_by).with(id: @soundcloud_track.id.to_s) { @soundcloud_track }

      visit "/podcasts/#{@soundcloud_track.id}"
      target = '← Top'
      expect(page).to have_http_status(:success)
      expect(page).to have_link target, href: '/podcasts'
      click_link target
      expect(page).to have_http_status(:success)
    end

    scenario 'Load doc file with absolute path' do
      @soundcloud_track = create(:soundcloud_track)
      allow(@soundcloud_track).to receive(:exists?) { true }
      allow(@soundcloud_track).to receive(:content) { "title\n収録日: 2019/05/10\n..." }
      allow(SoundCloudTrack).to receive(:find_by).with(id: @soundcloud_track.id.to_s) { @soundcloud_track }

      visit  "/podcasts/#{@soundcloud_track.id}"
      target = '🎙 DojoCast'
      expect(page).to have_http_status(:success)
      expect(page).to have_link target, href: '/podcasts'
      click_link target
      expect(page).to have_http_status(:success)
    end
  end
end
