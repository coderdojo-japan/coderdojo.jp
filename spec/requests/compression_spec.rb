require 'rails_helper'

# Heroku のルーターは応答を圧縮しないので、HTML と JSON は Rails で gzip する
RSpec.describe "応答の圧縮", type: :request do
  it "gzip を受け付けるブラウザには、HTML を gzip して返す" do
    get root_path, headers: { 'Accept-Encoding' => 'gzip' }

    expect(response.headers['Content-Encoding']).to eq 'gzip'
    expect(response.headers['Vary']).to include 'Accept-Encoding'
    expect(ActiveSupport::Gzip.decompress(response.body)).to include '</html>'
  end

  it "gzip を受け付けるクライアントには、JSON も gzip して返す" do
    create(:dojo)
    get dojos_path(format: :json), headers: { 'Accept-Encoding' => 'gzip' }

    expect(response.headers['Content-Encoding']).to eq 'gzip'
    expect(JSON.parse(ActiveSupport::Gzip.decompress(response.body))).to be_an Array
  end

  it "gzip して返しても、同じ ETag を送れば 304 が返る" do
    get root_path, headers: { 'Accept-Encoding' => 'gzip' }
    etag = response.headers['ETag']

    get root_path, headers: { 'Accept-Encoding' => 'gzip', 'If-None-Match' => etag }
    expect(response).to have_http_status(:not_modified)
  end

  it "gzip を受け付けないクライアントには、圧縮せずに返す" do
    get root_path

    expect(response.headers['Content-Encoding']).to be_nil
    expect(response.body).to include '</html>'
  end
end
