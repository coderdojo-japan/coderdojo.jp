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
      Dojo::DOJO_INFO_YAML_PATH = Rails.root.join('spec', 'data', 'invalid_format_of.yml')

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

  describe 'validate created_at dates' do
    # created_at は「掲載日」（rails dojos:update_db_by_yaml が自動採番する値）。
    # 手で書き換えた際に年を取り違える事故が過去に 2 件あり、うち 1 件は
    # 年次の新規掲載数統計に誤計上されたまま残っていた。
    # そこで id の昇順に対する created_at の極端な逆行を検出する。
    #
    # id 300 未満は Parse からの移行データや再掲載を含み、created_at が
    # 掲載日ではなく道場の設立日を指すものが混在しているため対象外とする。
    # 対象範囲での逆行は最大 15 日であり、閾値 90 日は十分な余裕がある。
    #
    # 受付日ではなく掲載日を採用した理由など、検討の経緯は PR #1861 を参照。
    # https://github.com/coderdojo-japan/coderdojo.jp/pull/1861
    # 定数にすると describe を抜けて Object に定義されてしまうためローカル変数を使う。
    recent_dojo_id_from = 300
    allowed_inversion_in_days = 90

    # YYYY-MM-DD 以外や 2025-02-30 のような存在しない日付には nil を返す。
    # Time.zone.parse は 2025-02-30 を 2025-03-02 に繰り上げるため使わない。
    def parse_created_at(dojo)
      Date.iso8601(dojo['created_at'].to_s)
    rescue Date::Error
      nil
    end

    let(:dojos_with_created_at) do
      Dojo.load_attributes_from_yaml.select { |dojo| dojo['created_at'].present? }
    end

    it 'has valid and non-future created_at' do
      dojos_with_created_at.each do |dojo|
        date = parse_created_at(dojo)

        expect(date).to be_present,
          "ID: #{dojo['id']} (#{dojo['name']}) の created_at が YYYY-MM-DD 形式の日付ではありません: #{dojo['created_at']}"
        expect(date).to be <= Date.current,
          "ID: #{dojo['id']} (#{dojo['name']}) の created_at が未来の日付です: #{dojo['created_at']}"
      end
    end

    it 'has created_at roughly in ascending order of id' do
      recent_dojos = dojos_with_created_at
        .select { |dojo| dojo['id'].to_i >= recent_dojo_id_from }
        .sort_by { |dojo| dojo['id'] }

      recent_dojos.each_cons(2) do |prev_dojo, dojo|
        prev_date = parse_created_at(prev_dojo)
        date      = parse_created_at(dojo)
        next if prev_date.nil? || date.nil? # 形式の誤りは上のテストが報告する

        inversion_in_days = (prev_date - date).to_i

        expect(inversion_in_days).to be <= allowed_inversion_in_days,
          "ID: #{dojo['id']} (#{dojo['name']}) の created_at #{dojo['created_at']} が、" \
          "1つ前の ID: #{prev_dojo['id']} (#{prev_dojo['name']}) の #{prev_dojo['created_at']} より " \
          "#{inversion_in_days} 日も前になっています。どちらかが年を取り違えていないか確認してください。"
      end
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

    # global_club_id は Clubs API 上のクラブ ID (UUID)。DojoMap がこの ID で突合する。
    # 手作業のマージや追記で最も起きやすい事故が重複と typo で、
    # typo はユニーク制約では捕まらないため形式も検証する。
    describe 'global_club_id' do
      let(:dojos_with_global_club_id) do
        Dojo.load_attributes_from_yaml.select { |dojo| dojo['global_club_id'].present? }
      end

      it 'is a valid UUID' do
        dojos_with_global_club_id.each do |dojo|
          expect(dojo['global_club_id']).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/),
            "ID: #{dojo['id']} (#{dojo['name']}) の global_club_id が UUID 形式ではありません: #{dojo['global_club_id']}"
        end
      end

      it 'is not shared by two dojos' do
        ids = dojos_with_global_club_id.map { |dojo| dojo['global_club_id'] }
        duplicated = ids.tally.select { |_, count| count > 1 }.keys

        expect(duplicated).to be_empty,
          "重複している global_club_id: #{duplicated.join(', ')}"
      end
    end
  end
end
