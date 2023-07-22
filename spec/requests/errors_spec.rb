require 'rails_helper'

RSpec.describe "Errors", type: :request do
  include Rambulance::TestHelper

  describe "Error requests" do
    it 'should render a corresponding error page' do
      with_exceptions_app do
        get '/does_not_exist'
      end

      assert_equal 404, response.status
    end
  end
end
