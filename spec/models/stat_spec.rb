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
        description: 'テスト用Dojo1の説明',
        tags: ['Scratch', 'Python'],
        url: 'https://test1.coderdojo.jp',
        created_at: Time.zone.local(2020, 3, 1),
        prefecture_id: 13,
        is_active: false,
        inactivated_at: Time.zone.local(2022, 6, 15)
      )
      
      # 2021年から活動開始、現在も活動中
      @dojo2 = Dojo.create!(
        name: 'CoderDojo テスト2',
        email: 'test2@example.com',
        description: 'テスト用Dojo2の説明',
        tags: ['Scratch'],
        url: 'https://test2.coderdojo.jp', 
        created_at: Time.zone.local(2021, 1, 1),
        prefecture_id: 13,
        is_active: true,
        inactivated_at: nil
      )
      
      # 2019年から活動開始、2020年に非アクティブ化
      @dojo3 = Dojo.create!(
        name: 'CoderDojo テスト3',
        email: 'test3@example.com',
        description: 'テスト用Dojo3の説明',
        tags: ['JavaScript'],
        url: 'https://test3.coderdojo.jp',
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
    
    it '過去の活動履歴を含めた統計グラフを生成する' do
      # annual_dojos_with_historical_dataが呼ばれることを確認し、ダミーデータを返す
      expect(stat).to receive(:annual_dojos_with_historical_data).and_return({
        '2020' => 1,
        '2021' => 2,
        '2022' => 1,
        '2023' => 1
      })
      
      result = stat.annual_dojos_chart
      expect(result).to be_a(LazyHighCharts::HighChart)
    end
  end
end