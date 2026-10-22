require 'rails_helper'
require 'rake'

# news.coderdojo.jp の取得に失敗したまま空で返すと、news:fetch が db/news.yml を上書きし、
# デプロイ時の news:upsert が DB から記事を消してしまう（2026年10月22日に 120 件が消えた）
RSpec.describe 'fetch_dojo_news_posts' do
  before(:all) { Rails.application.load_tasks }

  let(:endpoint) { 'https://news.example.com/wp-json/wp/v2/posts' }

  def wp_response(posts, total_pages:)
    response = Net::HTTPOK.new('1.1', '200', 'OK')
    allow(response).to receive(:body).and_return(posts.to_json)
    response['X-WP-TotalPages'] = total_pages.to_s
    response
  end

  def wp_post(id)
    { 'link' => "https://news.example.com/#{id}", 'title' => { 'rendered' => "記事 #{id}" }, 'date_gmt' => '2026-10-01T00:00:00' }
  end

  it 'API が失敗した時は、空で返さずに例外を出す' do
    allow(Net::HTTP).to receive(:get_response).and_return(Net::HTTPServiceUnavailable.new('1.1', '503', 'Service Unavailable'))

    expect { send(:fetch_dojo_news_posts, endpoint) }.to raise_error(/503/)
  end

  it '全ページの記事を集め、最後のページの次は取りに行かない' do
    allow(Net::HTTP).to receive(:get_response) do |uri|
      page = URI.decode_www_form(uri.query).to_h['page'].to_i
      raise "ページ #{page} は存在しない" if page > 2

      wp_response([wp_post(page)], total_pages: 2)
    end

    expect(send(:fetch_dojo_news_posts, endpoint).map { it['title'] }).to eq ['記事 1', '記事 2']
  end
end
