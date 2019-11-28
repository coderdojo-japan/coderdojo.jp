require 'rails_helper'
require 'rake'

RSpec.describe 'dojo_event_services' do
  before(:all) do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require 'tasks/dojo_event_services'
    Rake::Task.define_task(:environment)
  end

  before(:each) do
    @rake[task].reenable
  end

  describe 'dojo_event_services:upsert' do
    before :each do
      @dojo_1 = create(:dojo, name: 'dojo_1', email: 'mail_1@test', tags: %w(Scratch ラズベリーパイ), description: '月1回開催', prefecture_id: 13)
      @dojo_2 = create(:dojo, name: 'dojo_2', email: 'mail_2@test', tags: %w(Scratch), description: '隔週開催', prefecture_id: 13)
      @dojo_3 = create(:dojo, name: 'dojo_3', email: 'mail_3@test', tags: %w(Scratch ラズベリーパイ Webサイト), description: '月1回開催', prefecture_id: 13)

      create(:dojo_event_service, dojo_id: @dojo_1.id, name: :doorkeeper, group_id: '10001', url: 'https://coder-dojo-11.doorkeeper.jp/')
      create(:dojo_event_service, dojo_id: @dojo_1.id, name: :doorkeeper, group_id: '10002', url: 'https://coder-dojo-12.doorkeeper.jp/')
      create(:dojo_event_service, dojo_id: @dojo_2.id, name: :connpass,   group_id: '20001', url: 'https://coder-dojo-21.connpass.jp/')
    end

    let(:task) { 'dojo_event_services:upsert' }

    it '単純追加' do
      allow(YAML).to receive(:load_file).and_return([
        { 'dojo_id' => @dojo_1.id, "name" => 'doorkeeper', 'group_id' => '10001', 'url' => 'https://coder-dojo-11.doorkeeper.jp/' },
        { 'dojo_id' => @dojo_1.id, "name" => 'doorkeeper', 'group_id' => '10002', 'url' => 'https://coder-dojo-12.doorkeeper.jp/' },
        { 'dojo_id' => @dojo_2.id, "name" => 'connpass',   'group_id' => '20001', 'url' => 'https://coder-dojo-21.connpass.jp/' },
        { 'dojo_id' => @dojo_3.id, "name" => 'facebook',   'group_id' => '30001', 'url' => 'https://coder-dojo-31.facebook.com/' }
      ])

      # before
      expect(DojoEventService.count).to eq(3)

      # exec
      expect(@rake[task].invoke).to be_truthy

      # after
      expect(DojoEventService.count).to eq(4)
      new_records = DojoEventService.where(dojo_id: @dojo_3.id, name: :facebook, group_id: '30001')
      expect(new_records.count).to eq(1)
      expect(new_records.first.url).to eq('https://coder-dojo-31.facebook.com/')
    end

    it '単純更新' do
      allow(YAML).to receive(:load_file).and_return([
        { 'dojo_id' => @dojo_1.id, "name" => 'doorkeeper', 'group_id' => '10001', 'url' => 'https://coder-dojo-11.doorkeeper.jp/' },
        { 'dojo_id' => @dojo_1.id, "name" => 'doorkeeper', 'group_id' => '10002', 'url' => 'https://coder-dojo-12.doorkeeper.jp/' },
        { 'dojo_id' => @dojo_2.id, "name" => 'connpass',   'group_id' => '20001', 'url' => 'https://coder-dojo-21.connpass.jp/zzz' }
      ])

      # before
      expect(DojoEventService.count).to eq(3)

      # exec
      expect(@rake[task].invoke).to be_truthy

      # after
      expect(DojoEventService.count).to eq(3)
      mod_records = DojoEventService.where(dojo_id: @dojo_2.id, name: :connpass, group_id: '20001')
      expect(mod_records.count).to eq(1)
      expect(mod_records.first.url).to eq('https://coder-dojo-21.connpass.jp/zzz')
    end

    it '余剰データ削除 & 更新' do
      create(:dojo_event_service, dojo_id: @dojo_1.id, name: :doorkeeper, group_id: '10003', url: 'https://coder-dojo-12.doorkeeper.jp/abc')

      allow(YAML).to receive(:load_file).and_return([
        { 'dojo_id' => @dojo_1.id, "name" => 'doorkeeper', 'group_id' => '10001', 'url' => 'https://coder-dojo-11.doorkeeper.jp/' },
        { 'dojo_id' => @dojo_1.id, "name" => 'doorkeeper', 'group_id' => '10002', 'url' => 'https://coder-dojo-12.doorkeeper.jp/12345' },
        { 'dojo_id' => @dojo_2.id, "name" => 'connpass',   'group_id' => '20001', 'url' => 'https://coder-dojo-21.connpass.jp/' }
      ])

      # before
      expect(DojoEventService.count).to eq(4)
      expect(DojoEventService.where(dojo_id: @dojo_1.id, name: :doorkeeper).size).to eq(3)

      # exec
      expect(@rake[task].invoke).to be_truthy

      # after
      expect(DojoEventService.count).to eq(3)
      expect(DojoEventService.where(dojo_id: @dojo_1.id, name: :doorkeeper).size).to eq(2)
      mod_records = DojoEventService.where(dojo_id: @dojo_1.id, name: :doorkeeper, group_id: '10002')
      expect(mod_records.count).to eq(1)
      expect(mod_records.first.url).to eq('https://coder-dojo-12.doorkeeper.jp/12345')
    end
  end
end
