require 'rails_helper'
require 'rake'

RSpec.describe 'dojos' do
  before(:all) do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require 'tasks/postgresql'
    Rake.application.rake_require 'tasks/dojos'
    Rake::Task.define_task(:environment)
  end

  before(:each) do
    @rake[task].reenable
  end

  describe 'dojos:update_db_by_yaml' do
    before :each do
      @dojo_1 = create(:dojo, name: 'dojo_1', prefecture_id: 14, order: '142010', created_at: '2019-01-04', tags: %w(Scratch ラズベリーパイ))
      @dojo_2 = create(:dojo, name: 'dojo_2', prefecture_id: 12, order: '122040', created_at: '2019-02-01', tags: %w(Scratch))
      @dojo_3 = create(:dojo, name: 'dojo_3', prefecture_id: 34, order: '342090', created_at: '2019-03-01', tags: %w(Scratch Webサイト))
    end

    let(:task) { 'dojos:update_db_by_yaml' }

    it '単純追加' do
      allow(YAML).to receive(:unsafe_load_file).and_return([
        { 'order'         => '152064',
          'created_at'    => '2018-02-17',
          'name'          => '新発田',
          'prefecture_id' => 15,
          'logo'          => '/img/dojos/japan.png',
          'url'           => 'http://tinkerkids.jp/coderdojo.html',
          'description'   => '毎月開催',
          'tags'          => %w(Scratch ラズベリーパイ Python JavaScript) }
      ])

      # before
      expect(Dojo.count).to eq(3)
      before_ids = Dojo.ids

      # exec
      expect(@rake[task].invoke).to be_truthy

      # after
      expect(Dojo.count).to eq(4)
      new_records = Dojo.where.not(id: before_ids)
      expect(new_records.count).to eq(1)
      expect(new_records.first.order).to eq('152064')
      expect(new_records.first.created_at.to_date).to eq(Time.zone.today)
      expect(new_records.first.name).to eq('新発田')
      expect(new_records.first.prefecture_id).to eq(15)
      expect(new_records.first.logo).to eq('/img/dojos/japan.png')
      expect(new_records.first.url).to eq('http://tinkerkids.jp/coderdojo.html')
      expect(new_records.first.description).to eq('毎月開催')
      expect(new_records.first.tags).to eq(%w(Scratch ラズベリーパイ Python JavaScript))
      expect(new_records.first.active?).to eq(true)
      expect(new_records.first.is_private).to eq(false)
    end

    it '単純更新' do
      allow(YAML).to receive(:unsafe_load_file).and_return([
        @dojo_1.attributes.keep_if { |k,v| %w(id order prefecture_id logo url description tags).include?(k) }.merge('name' => 'dojo_1(mod)')
      ])

      # before
      expect(Dojo.count).to eq(3)

      # exec
      expect(@rake[task].invoke).to be_truthy

      # after
      expect(Dojo.count).to eq(3)
      mod_record = Dojo.find_by(id: @dojo_1.id)
      expect(mod_record.name).to eq('dojo_1(mod)')
    end

    context 'inactivated_at (活性状態管理)' do
      let(:dojo_base) do
        @dojo_2.attributes.keep_if { |k,v| %w(id order name prefecture_id logo url description tags).include?(k) }
      end

      it 'inactivated_at 指定なし ⇒ アクティブ' do
        allow(YAML).to receive(:unsafe_load_file).and_return([
          dojo_base
        ])

        # before
        @dojo_2.update_columns(inactivated_at: Time.current)
        expect(Dojo.count).to eq(3)
        expect(@dojo_2.reload.active?).to eq(false)

        # exec
        expect(@rake[task].invoke).to be_truthy

        # after
        expect(Dojo.count).to eq(3)
        mod_record = Dojo.find_by(id: @dojo_2.id)
        expect(mod_record.active?).to eq(true)
        expect(mod_record.inactivated_at).to be_nil
      end

      it 'inactivated_at: nil 指定 ⇒ アクティブ' do
        allow(YAML).to receive(:unsafe_load_file).and_return([
          dojo_base.merge('inactivated_at' => nil)
        ])

        # before
        @dojo_2.update_columns(inactivated_at: Time.current)
        expect(Dojo.count).to eq(3)
        expect(@dojo_2.reload.active?).to eq(false)

        # exec
        expect(@rake[task].invoke).to be_truthy

        # after
        expect(Dojo.count).to eq(3)
        mod_record = Dojo.find_by(id: @dojo_2.id)
        expect(mod_record.active?).to eq(true)
        expect(mod_record.inactivated_at).to be_nil
      end

      it 'inactivated_at に日付指定 ⇒ 非アクティブ' do
        inactivation_date = '2023-01-15'
        allow(YAML).to receive(:unsafe_load_file).and_return([
          dojo_base.merge('inactivated_at' => inactivation_date)
        ])

        # before
        expect(Dojo.count).to eq(3)
        expect(@dojo_2.active?).to eq(true)

        # exec
        expect(@rake[task].invoke).to be_truthy

        # after
        expect(Dojo.count).to eq(3)
        mod_record = Dojo.find_by(id: @dojo_2.id)
        expect(mod_record.active?).to eq(false)
        expect(mod_record.inactivated_at).to eq(Time.zone.parse(inactivation_date))
      end
    end

    context 'is_private' do
      let(:dojo_base) do
        @dojo_3.attributes.keep_if { |k,v| %w(id order name prefecture_id logo url description tags).include?(k) }
      end

      it '指定なし ⇒ 非プライベート' do
        allow(YAML).to receive(:unsafe_load_file).and_return([
          dojo_base
        ])

        # before
        @dojo_3.update_columns(is_private: true)
        expect(Dojo.count).to eq(3)
        expect(@dojo_3.is_private).to eq(true)

        # exec
        expect(@rake[task].invoke).to be_truthy

        # after
        expect(Dojo.count).to eq(3)
        mod_record = Dojo.find_by(id: @dojo_3.id)
        expect(mod_record.is_private).to eq(false)
      end

      it 'true 指定 ⇒ プライベート' do
        allow(YAML).to receive(:unsafe_load_file).and_return([
          dojo_base.merge('is_private' => true)
        ])

        # before
        expect(Dojo.count).to eq(3)
        expect(@dojo_3.is_private).to eq(false)

        # exec
        expect(@rake[task].invoke).to be_truthy

        # after
        expect(Dojo.count).to eq(3)
        mod_record = Dojo.find_by(id: @dojo_3.id)
        expect(mod_record.is_private).to eq(true)
      end

      it 'false 指定 ⇒ 非プライベート' do
        allow(YAML).to receive(:unsafe_load_file).and_return([
          dojo_base.merge('is_private' => false)
        ])

        # before
        @dojo_3.update_columns(is_private: true)
        expect(Dojo.count).to eq(3)
        expect(@dojo_3.is_private).to eq(true)

        # exec
        expect(@rake[task].invoke).to be_truthy

        # after
        expect(Dojo.count).to eq(3)
        mod_record = Dojo.find_by(id: @dojo_3.id)
        expect(mod_record.is_private).to eq(false)
      end
    end
  end
end
