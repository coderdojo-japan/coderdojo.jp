require 'rails_helper'

RSpec.describe 'Docs', type: :request do
  describe 'GET /docs' do
    it 'show @docs' do
      get docs_path
      expect(response.body).to include(Document.all.last.title)
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
