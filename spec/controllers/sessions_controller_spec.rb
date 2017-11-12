require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  before(:each) do
    obj = mock_obj(PlainPage)
    allow(Obj).to receive(:root) { obj }
  end

  around(:each) do |example|
    begin
      @old_email = ENV['SCRIVITO_EMAIL'] if ENV.key?('SCRIVITO_EMAIL')
      @old_password = ENV['SCRIVITO_PASSWORD'] if ENV.key?('SCRIVITO_PASSWORD')
      ENV['SCRIVITO_EMAIL'] = 'dummy@example.com'
      ENV['SCRIVITO_PASSWORD'] = 'dummy_password'
      example.run
    ensure
      if @old_email
        ENV['SCRIVITO_EMAIL'] = @old_email
      else
        ENV.delete('SCRIVITO_EMAIL')
      end
      if @old_password
        ENV['SCRIVITO_PASSWORD'] = @old_password
      else
        ENV.delete('SCRIVITO_PASSWORD')
      end
    end
  end

  describe "GET #create" do
    it "param match" do
      get :create, params: { email: ENV['SCRIVITO_EMAIL'],
                             password: ENV['SCRIVITO_PASSWORD'] }
      expect(session[:user]).to eq ENV['SCRIVITO_EMAIL']
    end
    it "param unmatch" do
      get :create
      expect(flash[:alert]).to be_present
    end
  end
  describe "GET #destroy" do
    it 'user login' do
      session[:user] = ENV['SCRIVITO_EMAIL']
      get :destroy
      expect(flash[:success]).to be_present
      expect(session[:user]).to eq nil
    end
    it 'user not login' do
      get :destroy
      expect(flash[:danger]).to be_present
    end
  end
end
