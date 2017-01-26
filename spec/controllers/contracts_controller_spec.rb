require 'rails_helper'

RSpec.describe ContractsController, type: :controller do
  describe "GET #index" do
    it "show @contrcts" do
      get :index
      expect(assigns(:contracts)).to eq Contract.all
    end
  end
  describe "GET #show" do
    it "show @content" do
      get :show, params: { id: 'teikan' }
      contract = Contract.new('teikan')
      expected = Kramdown::Document.new(contract.content, input: 'GFM').to_html
      expect(assigns(:content)).to eq expected
    end
  end
end
