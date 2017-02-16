require 'rails_helper'

RSpec.describe Dojo, :type => :model do
  before do
    @dojo = Dojo.new(name:  "CoderDojo 下北沢", email: "shimokitazawa@coderdojo.jp",
                 order: 0, description: "東京都世田谷区で毎週開催",
                 logo: "https://graph.facebook.com/346407898743580/picture?type=large",
                 url:  "http://tokyo.coderdojo.jp/",
                 tags: ["Scratch", "Webサイト", "ゲーム"])
  end

  subject { @dojo }

  it { should respond_to(:name) }
  it { should respond_to(:email) }
  it { should respond_to(:order) }
  it { should respond_to(:description) }
  it { should respond_to(:logo) }
  it { should respond_to(:url) }
  it { should respond_to(:tags) }

  it { should be_valid }

  describe "when name is not present" do
    before { @dojo.name = " " }
    it { should_not be_valid }
  end

  describe "when name is too long" do
    before { @dojo.name = "a" * 51 }
    it { should_not be_valid }
  end

  describe "when email is not present" do
    before { @dojo.email = " " }
    it { should be_valid }
  end

  describe "when description is not present" do
    before { @dojo.description = " " }
    it { should_not be_valid }
  end

  describe "when description is too long" do
    before { @dojo.description = "a" * 51 }
    it { should_not be_valid }
  end

  describe 'when tags is not present' do
    before { @dojo.tags = [] }
    it { should_not be_valid }
  end

  describe 'when tags are too many' do
    before { @dojo.tags = %w[Scratch RasPi HackforPlay Viscuit Arduino 電子工作] }
    it { should_not be_valid }
  end

  describe 'yaml format validator' do
    let(:valid_yaml) {      Rails.root.join('spec', 'data',   'valid_format_of.yaml') }
    let(:invalid_yaml) {    Rails.root.join('spec', 'data', 'invalid_format_of.yaml') }
    let(:production_yaml) { Rails.root.join('db','dojos.yaml')}

    it 'should return true when valid yaml format' do
      expect(Dojo.valid_yaml_format? valid_yaml).to be true
    end

    it 'should return false when invalid yaml format' do
      expect(Dojo.valid_yaml_format? invalid_yaml).to be false
    end

    it 'should always return true for production yaml file' do
      expect(Dojo.valid_yaml_format? production_yaml).to be true
    end
  end
end
