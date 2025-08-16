require 'rails_helper'

RSpec.describe "Docs", type: :request do
  describe "GET /docs" do
    it "show @docs" do
      get docs_path
      expect(response.body).to include(Document.all.last.title)
    end
  end

  describe "GET /docs/:id" do
    it "show @content" do
      param    = 'charter'
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

    # /signup page has Google Form to be rendered.
    context 'signup page - Google Form rendering (Critical)' do
      before { get doc_path('signup') }

      # The iframe is essential - without it, no one can submit applications
      it('responds with 200 OK')  { expect(response).to have_http_status(:success) }
      it('contains Google Forms') { expect(response.body).to include('<iframe') }
      it('contains Google Forms URL') { expect(response.body).to include('docs.google.com/forms') }
      it('has no raw CONSTANT name')  { expect(response.body).not_to include('{{ INACTIVE_THRESHOLD }}') }
    end
  end
end
