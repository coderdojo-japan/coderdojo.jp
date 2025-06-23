require 'rails_helper'

RSpec.describe 'Errors', type: :request do
  include Rambulance::TestHelper
  include ErrorsHelper

  before do
    # テスト用のルーティングを直接定義
    Rails.application.routes.draw do
      get '/trigger_400', to: ->(env) { raise ActionController::BadRequest }
      get '/trigger_422', to: ->(env) { raise ActionController::InvalidAuthenticityToken }
      get '/trigger_500', to: ->(env) { raise 'This is a test 500 error' }
    end

    # ビューのレンダリングをスタブして、レイアウト起因のエラーを回避
    allow_any_instance_of(Rambulance::ExceptionsApp).to receive(:render).and_wrap_original do |m, *args|
      options = args.last.is_a?(Hash) ? args.pop : {}
      m.call(*args, **options.merge(layout: false))
    end
  end

  after do
    # テスト後に追加したルーティングを元に戻す
    Rails.application.reload_routes!
  end

  describe 'Error requests' do
    it 'renders the 404 error page' do
      with_exceptions_app do
        # どのルーティングにもマッチしないパスをリクエスト
        get '/does_not_exist'
      end
      expect(response.status).to eq(404)
      expect(response.body).to include(error_title(404))
      expect(response.body).to include(error_desc(404))
    end

    it 'renders the 422 error page' do
      with_exceptions_app do
        get '/trigger_422'
      end
      expect(response.status).to eq(422)
      expect(response.body).to include(error_title(422))
      expect(response.body).to include(error_desc(422))
    end

    it 'renders the 500 error page' do
      with_exceptions_app do
        get '/trigger_500'
      end
      expect(response.status).to eq(500)
      expect(response.body).to include(error_title(500))
      expect(response.body).to include(error_desc(500))
    end
    it 'renders the 400 error page' do
      with_exceptions_app do
        get '/trigger_400'
      end
      expect(response.status).to eq(400)
      expect(response.body).to include(error_title(400))
      expect(response.body).to include(error_desc(400))
    end
  end
end
