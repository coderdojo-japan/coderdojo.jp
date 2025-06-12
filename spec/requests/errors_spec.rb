require 'rails_helper'

RSpec.describe "Errors", type: :request do
  include Rambulance::TestHelper

  describe "Error requests" do
    it 'renders the 404 error page' do
      with_exceptions_app do
        get '/does_not_exist'
      end
      expect(response.status).to eq(404)
      expect(response.body).to include("子どものためのプログラミング道場")
    end

    it 'renders the 422 error page' do
      with_exceptions_app do
        get '/trigger_422'
      end
      expect(response.status).to eq(422)
      expect(response.body).to include("子どものためのプログラミング道場")
    end

    it 'renders the 500 error page' do
      with_exceptions_app do
        get '/trigger_500'
      end
      expect(response.status).to eq(500)
      expect(response.body).to include("子どものためのプログラミング道場")
    end
  end
end
