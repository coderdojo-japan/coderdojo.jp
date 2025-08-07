require 'rails_helper'

RSpec.describe Stat, type: :model do
  describe '#annual_dojos_with_historical_data' do
    let(:period) { Date.new(2020, 1, 1)..Date.new(2023, 12, 31) }
    let(:stat) { Stat.new(period) }
    
    before do
      # 2020年から活動開始、2022年に非アクティブ化
      @dojo1 = Dojo.create!(
        name: 'CoderDojo テスト1',
        email: 'test1@example.com',
        created_at: Time.zone.local(2020, 3, 1),
        prefecture_id: 13,
        is_active: false,
        inactivated_at: Time.zone.local(2022, 6, 15)
      )
      
      # 2021年から活動開始、現在も活動中
      @dojo2 = Dojo.create!(
        name: 'CoderDojo テスト2',
        email: 'test2@example.com', 
        created_at: Time.zone.local(2021, 1, 1),
        prefecture_id: 13,
        is_active: true,
        inactivated_at: nil
      )
      
      # 2019年から活動開始、2020年に非アクティブ化
      @dojo3 = Dojo.create!(
        name: 'CoderDojo テスト3',
        email: 'test3@example.com',
        created_at: Time.zone.local(2019, 1, 1),
        prefecture_id: 13,
        is_active: false,
        inactivated_at: Time.zone.local(2020, 3, 1)
      )
    end
    
    it '各年末時点でアクティブだったDojo数を正しく集計する' do
      result = stat.annual_dojos_with_historical_data
      
      # 2020年末: dojo1(活動中) + dojo3(3月に非アクティブ化) = 1
      expect(result['2020']).to eq(1)
      
      # 2021年末: dojo1(活動中) + dojo2(活動中) = 2
      expect(result['2021']).to eq(2)
      
      # 2022年末: dojo1(6月に非アクティブ化) + dojo2(活動中) = 1
      expect(result['2022']).to eq(1)
      
      # 2023年末: dojo2(活動中) = 1
      expect(result['2023']).to eq(1)
    end
  end
  
  describe '#annual_dojos_chart' do
    let(:period) { Date.new(2020, 1, 1)..Date.new(2023, 12, 31) }
    let(:stat) { Stat.new(period) }
    
    context 'inactivated_at カラムが存在する場合' do
      it '過去の活動履歴を含めた統計を生成する' do
        allow(Dojo).to receive(:column_names).and_return(['id', 'name', 'inactivated_at'])
        expect(stat).to receive(:annual_dojos_with_historical_data)
        
        stat.annual_dojos_chart
      end
    end
    
    context 'inactivated_at カラムが存在しない場合' do
      it '従来通りアクティブなDojoのみを集計する' do
        allow(Dojo).to receive(:column_names).and_return(['id', 'name'])
        expect(Dojo.active).to receive(:annual_count).with(period)
        
        stat.annual_dojos_chart
      end
    end
  end
end