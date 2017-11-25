require 'rails_helper'

RSpec.describe DocsController, type: :controller do
  describe "GET #index" do
    it "show @docs" do
      get :index
      expect(assigns(:docs).first.title).to eq Document.all.first.title
    end
  end
  describe "GET #show" do
    it "show @content" do
      param    = 'charter'
      get :show, params: { id: param }
      doc      = Document.new(param)
      expected = Kramdown::Document.new(doc.content, input: 'GFM').to_html
      expect(assigns(:content)).to eq expected
    end

    it 'when invalid filename' do
      get :show, params: { id: '../not_found' }
      expect(response).to redirect_to controller.root_url
      expect(response.status).to eq 302
    end
  end
end
