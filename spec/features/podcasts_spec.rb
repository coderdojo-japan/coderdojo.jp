require 'rails_helper'

RSpec.feature 'Podcasts', type: :feature do
  describe 'GET documents' do
    scenario 'Podcast index should be exist' do
      visit '/podcasts'
      expect(page).to have_http_status(:success)
    end

    scenario 'Charter should be exist' do
      @podcast = create(:podcast)
      allow(@podcast).to receive(:exist?) { true }
      allow(@podcast).to receive(:exist?).with(offset: -1) { false }
      allow(@podcast).to receive(:content) { "title\n収録日: 2019/05/10\n..." }
      allow(Podcast).to  receive(:find_by).with(id: @podcast.id.to_s) { @podcast }

      visit "/podcasts/#{@podcast.id}"
      expect(page).to have_http_status(:success)

      target = 'Top'
      expect(page).to have_link target, href: podcasts_path
      click_link target, match: :first
      expect(page).to have_http_status(:success)
    end

    scenario 'Load doc file with absolute path' do
      @podcast = create(:podcast)
      allow(@podcast).to receive(:exist?) { true }
      allow(@podcast).to receive(:content) { "title\n収録日: 2019/05/10\n..." }
      allow(Podcast).to  receive(:find_by).with(id: @podcast.id.to_s) { @podcast }

      visit  "/podcasts/#{@podcast.id}"
      target = 'DojoCast'
      expect(page).to have_http_status(:success)
      expect(page).to have_link target, href: '/podcasts'
      click_link target, match: :first
      expect(page).to have_http_status(:success)
    end

    scenario 'Show note timestamps are converted to YouTube links' do
      @podcast = create(:podcast)
      allow(@podcast).to receive(:exist?) { true }
      allow(@podcast).to receive(:content) { 
        <<~CONTENT
          タイトル
          収録日: 2019/05/10
          
          YouTubeリンク: https://www.youtube.com/watch?v=Dd9IYiF0R6E
          
          ## Shownote
          
          - 00:00:00 米国系 IT 企業から CoderDojo へ、233台のノートPC寄贈
          - 00:25:01 AI と遊んでみる回の動画 https://youtu.be/BYpa1CcYtss?t=1425
          - 00:59:14 CASE Shinjuku 利用者と CoderDojo の繋がり
          - 01:00:57 CASE Shinjuku の英語アクセスページ https://case-shinjuku.com/english
        CONTENT
      }
      allow(Podcast).to  receive(:find_by).with(id: @podcast.id.to_s) { @podcast }

      visit  "/podcasts/#{@podcast.id}"
      expect(page).to have_http_status(:success)
      
      # タイムスタンプがYouTubeリンクに変換されているか確認
      expect(page).to have_link '00:00:00', href: 'https://youtu.be/Dd9IYiF0R6E?t=00h00m00s'
      expect(page).to have_link '00:25:01', href: 'https://youtu.be/Dd9IYiF0R6E?t=00h25m01s'
      expect(page).to have_link '00:59:14', href: 'https://youtu.be/Dd9IYiF0R6E?t=00h59m14s'
      expect(page).to have_link '01:00:57', href: 'https://youtu.be/Dd9IYiF0R6E?t=01h00m57s'
      
      # 既存のURL付きタイムスタンプはそのまま表示されること
      expect(page).to have_content 'AI と遊んでみる回の動画 https://youtu.be/BYpa1CcYtss?t=1425'
      expect(page).to have_content 'CASE Shinjuku の英語アクセスページ https://case-shinjuku.com/english'
    end

    scenario 'Show note timestamps with mm:ss format are converted to YouTube links' do
      @podcast = create(:podcast)
      allow(@podcast).to receive(:exist?) { true }
      allow(@podcast).to receive(:content) { 
        <<~CONTENT
          タイトル
          収録日: 2019/05/10
          
          YouTubeリンク: https://www.youtube.com/watch?v=test123
          
          ## Shownote
          
          - 00:30 オープニング
          - 05:45 メインテーマ
          - 59:59 エンディング
        CONTENT
      }
      allow(Podcast).to  receive(:find_by).with(id: @podcast.id.to_s) { @podcast }

      visit  "/podcasts/#{@podcast.id}"
      expect(page).to have_http_status(:success)
      
      # mm:ss形式のタイムスタンプもYouTubeリンクに変換されているか確認
      expect(page).to have_link '00:30', href: 'https://youtu.be/test123?t=00m30s'
      expect(page).to have_link '05:45', href: 'https://youtu.be/test123?t=05m45s'
      expect(page).to have_link '59:59', href: 'https://youtu.be/test123?t=59m59s'
    end
  end
end
