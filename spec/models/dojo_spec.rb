require 'rails_helper'

RSpec.describe Dojo, :type => :model do
  before do
    @dojo = Dojo.new(name:  "CoderDojo 下北沢", email: "shimokitazawa@coderdojo.jp",
                 order: 0, description: "東京都世田谷区で毎週開催",
                 logo: "https://graph.facebook.com/346407898743580/picture?type=large",
                 url:  "http://tokyo.coderdojo.jp/",
                 tags: ["Scratch", "Webサイト", "ゲーム"],
                 prefecture_id: 13)
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
  it { expect(Dojo.new.active?).to be(true) }

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

  describe 'validate yaml format' do
    it 'should not raise Psych::SyntaxError' do
      expect{ Dojo.load_attributes_from_yaml }.not_to raise_error
    end

    it 'should raise Psych::SyntaxError' do
      orig_yaml = Dojo::DOJO_INFO_YAML_PATH
      Dojo.send(:remove_const, :DOJO_INFO_YAML_PATH)
      Dojo::DOJO_INFO_YAML_PATH = Rails.root.join('spec', 'data', 'invalid_format_of.yaml')

      expect{ Dojo.load_attributes_from_yaml }.to raise_error(Psych::SyntaxError)

      Dojo.send(:remove_const, :DOJO_INFO_YAML_PATH)
      Dojo::DOJO_INFO_YAML_PATH = orig_yaml
    end
  end

  describe 'validate id sequence' do
    it 'has sequential ids except for allowed gaps' do
      allowed_missing_ids = [
        1, 29, 63, 80, 93, 95, 142,
        160, 161, 162, 163, 164, 166,
        167, 168, 170, 171, 213
      ]

      ids = Dojo.load_attributes_from_yaml.map { it['id'] }
      max_id = ids.max
      missing_ids = (1..max_id).to_a - ids

      expect(missing_ids).to match_array(allowed_missing_ids)
    end
  end
  
  describe 'validate inactivated_at dates' do
    it 'verifies inactivated_at dates are valid when present' do
      yaml_data = Dojo.load_attributes_from_yaml
      dojos_with_inactivated_at = yaml_data.select { |dojo| dojo['inactivated_at'].present? }
      
      dojos_with_inactivated_at.each do |dojo|
        # 日付が正しくパースできることを確認
        expect {
          Time.zone.parse(dojo['inactivated_at'])
        }.not_to raise_error, "ID: #{dojo['id']} (#{dojo['name']}) のinactivated_atが不正な形式です: #{dojo['inactivated_at']}"
        
        # 未来の日付でないことを確認
        date = Time.zone.parse(dojo['inactivated_at'])
        expect(date).to be <= Time.current, "ID: #{dojo['id']} (#{dojo['name']}) のinactivated_atが未来の日付です: #{dojo['inactivated_at']}"
        
        # created_atより後の日付であることを確認（もしcreated_atがある場合）
        if dojo['created_at'].present?
          created_date = Time.zone.parse(dojo['created_at'])
          expect(date).to be >= created_date, "ID: #{dojo['id']} (#{dojo['name']}) のinactivated_atがcreated_atより前です"
        end
      end
    end
  end
  
  # inactivated_at カラムの基本的なテスト
  describe 'inactivated_at functionality' do
    before do
      @dojo = Dojo.create!(
        name: "CoderDojo テスト",
        email: "test@coderdojo.jp",
        order: 0,
        description: "テスト用Dojo",
        logo: "https://example.com/logo.png",
        url: "https://test.coderdojo.jp",
        tags: ["Scratch"],
        prefecture_id: 13
      )
    end
    
    describe '#active?' do
      it 'returns true when inactivated_at is nil' do
        @dojo.inactivated_at = nil
        expect(@dojo.active?).to be true
      end
      
      it 'returns false when inactivated_at is present' do
        @dojo.inactivated_at = Time.current
        expect(@dojo.active?).to be false
      end
    end
  end

  describe 'YAML data integrity' do
    it 'has no duplicate IDs' do
      yaml_data = Dojo.load_attributes_from_yaml
      ids = yaml_data.map { |dojo| dojo['id'] }
      duplicate_ids = ids.select { |id| ids.count(id) > 1 }.uniq
      
      expect(duplicate_ids).to be_empty,
        "重複しているID: #{duplicate_ids.join(', ')}"
    end
  end
end
