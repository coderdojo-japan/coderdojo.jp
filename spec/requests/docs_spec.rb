require 'rails_helper'

RSpec.describe 'Docs', type: :request do
  describe 'GET /docs' do
    it 'show @docs' do
      get docs_path
      expect(response.body).to include(Document.all.last.title)
    end

    # カバー画像は画面の最初に見える一番大きな要素（LCP）なので、遅延読み込みにしない
    it 'loads the cover image first' do
      get docs_path
      cover = Nokogiri::HTML(response.body).at('section.cover img')
      expect(cover['src']).to end_with '/img/ogp-docs.jpg'
      expect(cover['loading']).to be_nil
      expect(cover['fetchpriority']).to eq 'high'
    end
  end

  describe 'GET /docs/:id のカバー画像' do
    subject(:html) do
      get doc_path('about-coderdojo-japan')
      Nokogiri::HTML(response.body)
    end

    it '見出しの直後のカバー画像は、遅延読み込みにせず最初から本番の画像を読む' do
      cover = html.at('section.doc img')
      expect(cover['src']).to end_with '/coderdojo-japan_mix-cover.webp'
      expect(cover['loading']).to be_nil
      expect(cover['fetchpriority']).to eq 'high'
    end

    it 'OGP の画像は、カバー画像から作る' do
      expect(html.at('meta[property="og:image"]')['content']).to end_with '/coderdojo-japan_mix-cover.png'
    end
  end

  describe 'GET /docs/:id' do
    it 'show @content' do
      param = 'charter'
      get doc_path(param)
      doc      = Document.new(param)
      expected = Kramdown::Document.new(doc.content, input: 'GFM').to_html
      expect(response.body).to include(expected.strip)
    end

    it 'when invalid filename' do
      get doc_path('not_found')
      expect(response).to redirect_to root_url
      expect(response.status).to eq 302
    end

    # /kata page internal links should not be dead links
    context 'kata page - internal links check' do
      it 'has no dead internal links' do
        get '/kata'
        doc   = Nokogiri::HTML(response.body)
        links = doc.css('a[href]').map { |a| a['href'] }
                   .select { |href| href.start_with?('/') && !href.start_with?('/#') }
                   .map    { |href| href.split('#').first }
                   .uniq

        dead_links = links.reject do |path|
          get path
          response.status < 400
        end

        puts "Checked #{links.count} internal links"
        expect(dead_links).to be_empty, "Dead links found: #{dead_links.join(', ')}"
      end
    end

    # /signup page has Google Form to be rendered.
    context 'signup page - Google Form rendering (Critical)' do
      before { get doc_path('signup') }

      # The iframe is essential - without it, no one can submit applications
      it('responds with 200 OK')  { expect(response).to have_http_status(:success) }
      it('contains Google Forms') { expect(response.body).to include('<iframe') }
      it('contains Google Forms URL') { expect(response.body).to include('docs.google.com/forms') }
      it('has no raw CONSTANT name')  { expect(response.body).not_to include('{{ INACTIVE_THRESHOLD_IN_MONTH }}') }
    end
  end
end
