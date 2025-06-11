require 'rails_helper'

RSpec.describe "Errors", type: :request do
  include Rambulance::TestHelper

  describe "Error requests" do
    it 'renders the 404 error page' do
      with_exceptions_app do
        get '/does_not_exist'
      end
      expect(response.status).to eq(404)
    end

    it 'renders the 422 error page' do
      with_exceptions_app do
        get '/trigger_422'
      end
      expect(response.status).to eq(422)
    end

    it 'renders the 500 error page' do
      with_exceptions_app do
        get '/trigger_500'
      end
      expect(response.status).to eq(500)
    end
  end
end
