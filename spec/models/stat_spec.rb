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
  
  describe 'グラフデータの妥当性検証' do
    let(:period) { Date.new(2012, 1, 1)..Date.new(2024, 12, 31) }
    let(:stat) { Stat.new(period) }
    
    before do
      # テスト用のDojoを作成（複数作成して、一部を非アクティブ化）
      dojo1 = Dojo.create!(
        name: 'CoderDojo テスト1',
        email: 'test1@example.com',
        description: 'テスト用Dojo1の説明',
        tags: ['Scratch'],
        url: 'https://test1.coderdojo.jp',
        created_at: Time.zone.local(2012, 4, 1),
        prefecture_id: 13,
        is_active: true
      )
      
      # 2022年に非アクティブ化される道場
      dojo2 = Dojo.create!(
        name: 'CoderDojo テスト2',
        email: 'test2@example.com',
        description: 'テスト用Dojo2の説明',
        tags: ['Python'],
        url: 'https://test2.coderdojo.jp',
        created_at: Time.zone.local(2019, 1, 1),
        prefecture_id: 14,
        is_active: false,
        inactivated_at: Time.zone.local(2022, 6, 1)
      )
      
      # 2023年に非アクティブ化される道場
      dojo3 = Dojo.create!(
        name: 'CoderDojo テスト3',
        email: 'test3@example.com',
        description: 'テスト用Dojo3の説明',
        tags: ['Ruby'],
        url: 'https://test3.coderdojo.jp',
        created_at: Time.zone.local(2020, 1, 1),
        prefecture_id: 27,
        is_active: false,
        inactivated_at: Time.zone.local(2023, 3, 1)
      )
      
      # テスト用のイベント履歴を作成（実際のデータパターンに近づける）
      # 成長曲線を再現：初期は少なく、徐々に増加、COVID後に減少、その後回復
      test_data = {
        2012 => { events: 2, participants_per_event: 4 },   # 創成期
        2013 => { events: 3, participants_per_event: 4 },   # 徐々に増加
        2014 => { events: 5, participants_per_event: 5 },
        2015 => { events: 6, participants_per_event: 6 },
        2016 => { events: 8, participants_per_event: 6 },
        2017 => { events: 12, participants_per_event: 7 },  # 成長期
        2018 => { events: 15, participants_per_event: 7 },
        2019 => { events: 20, participants_per_event: 8 },  # ピーク
        2020 => { events: 16, participants_per_event: 5 },  # COVID影響
        2021 => { events: 14, participants_per_event: 4 },  # 低迷継続
        2022 => { events: 16, participants_per_event: 5 },  # 回復開始
        2023 => { events: 18, participants_per_event: 6 },  # 回復継続
        2024 => { events: 18, participants_per_event: 6 }   # 安定
      }
      
      test_data.each do |year, data|
        data[:events].times do |i|
          # dojo1のイベント（継続的に活動）
          EventHistory.create!(
            dojo_id: dojo1.id,
            dojo_name: dojo1.name,
            service_name: 'connpass',
            event_id: "test_#{year}_#{i}",
            event_url: "https://test.connpass.com/event/#{year}_#{i}/",
            evented_at: Date.new(year, 3, 1) + (i * 2).weeks,
            participants: data[:participants_per_event]
          )
        end
      end
    end
    
    it '開催回数のグラフに負の値が含まれないこと' do
      # テストデータから集計
      event_data = stat.annual_count_of_event_histories
      
      # 各年の開催回数が0以上であることを確認
      event_data.each do |year, count|
        expect(count).to be >= 0, "#{year}年の開催回数が負の値です: #{count}"
      end
      
      # 期待される値を確認（明示的なテストデータに基づく）
      # annual_count_of_event_historiesは文字列キーを返す
      expect(event_data['2012']).to eq(2)
      expect(event_data['2013']).to eq(3)
      expect(event_data['2014']).to eq(5)
      expect(event_data['2015']).to eq(6)
      expect(event_data['2016']).to eq(8)
      expect(event_data['2017']).to eq(12)
      expect(event_data['2018']).to eq(15)
      expect(event_data['2019']).to eq(20)
      expect(event_data['2020']).to eq(16)
      expect(event_data['2021']).to eq(14)
      expect(event_data['2022']).to eq(16)
      expect(event_data['2023']).to eq(18)
      expect(event_data['2024']).to eq(18)
      
      # グラフデータを生成
      chart = HighChartsBuilder.build_annual_event_histories(event_data)
      series_data = chart.series_data
      
      if series_data
        # 年間の開催回数（棒グラフ）が負でないことを確認
        annual_counts = series_data.find { |s| s[:type] == 'column' }
        if annual_counts && annual_counts[:data]
          annual_counts[:data].each_with_index do |count, i|
            year = 2012 + i  # テストデータの開始年は2012
            expect(count).to be >= 0, "#{year}年の開催回数が負の値としてグラフに表示されます: #{count}"
          end
        end
      end
    end
    
    it '参加者数のグラフに負の値が含まれないこと' do
      # テストデータから集計
      participant_data = stat.annual_sum_of_participants
      
      # 各年の参加者数が0以上であることを確認
      participant_data.each do |year, count|
        expect(count).to be >= 0, "#{year}年の参加者数が負の値です: #{count}"
      end
      
      # 期待される値を確認（明示的なテストデータに基づく）
      # annual_sum_of_participantsも文字列キーを返す
      expect(participant_data['2012']).to eq(8)    # 2イベント × 4人
      expect(participant_data['2013']).to eq(12)   # 3イベント × 4人
      expect(participant_data['2014']).to eq(25)   # 5イベント × 5人
      expect(participant_data['2015']).to eq(36)   # 6イベント × 6人
      expect(participant_data['2016']).to eq(48)   # 8イベント × 6人
      expect(participant_data['2017']).to eq(84)   # 12イベント × 7人
      expect(participant_data['2018']).to eq(105)  # 15イベント × 7人
      expect(participant_data['2019']).to eq(160)  # 20イベント × 8人
      expect(participant_data['2020']).to eq(80)   # 16イベント × 5人
      expect(participant_data['2021']).to eq(56)   # 14イベント × 4人
      expect(participant_data['2022']).to eq(80)   # 16イベント × 5人
      expect(participant_data['2023']).to eq(108)  # 18イベント × 6人
      expect(participant_data['2024']).to eq(108)  # 18イベント × 6人
      
      # グラフデータを生成
      chart = HighChartsBuilder.build_annual_participants(participant_data)
      series_data = chart.series_data
      
      if series_data
        # 年間の参加者数（棒グラフ）が負でないことを確認
        annual_counts = series_data.find { |s| s[:type] == 'column' }
        if annual_counts && annual_counts[:data]
          annual_counts[:data].each_with_index do |count, i|
            year = 2012 + i  # テストデータの開始年は2012
            expect(count).to be >= 0, "#{year}年の参加者数が負の値としてグラフに表示されます: #{count}"
          end
        end
      end
    end
    
    it '道場数の「開設数」は負の値にならない（新規開設数のため）' do
      # 道場数のデータを取得（新しい形式）
      dojo_data = {
        active_dojos: stat.annual_dojos_with_historical_data,
        new_dojos: stat.annual_new_dojos_count
      }
      
      # グラフデータを生成
      chart = HighChartsBuilder.build_annual_dojos(dojo_data)
      series_data = chart.series_data
      
      if series_data
        # 開設数（棒グラフ）- 新規開設された道場の数
        change_data = series_data.find { |s| s[:type] == 'column' }
        if change_data && change_data[:data]
          change_data[:data].each_with_index do |value, i|
            year = 2012 + i
            # 「開設数」は新規開設を意味するため、負の値は論理的に不適切
            expect(value).to be >= 0, "#{year}年の「開設数」が負の値です: #{value}。開設数は新規開設された道場数を表すため、0以上である必要があります"
          end
        end
        
        # 累積数（線グラフ）は常に0以上
        total_data = series_data.find { |s| s[:type] == 'line' }
        if total_data && total_data[:data]
          total_data[:data].each_with_index do |count, i|
            year = 2012 + i
            expect(count).to be >= 0, "#{year}年の累積道場数が負の値です: #{count}"
          end
        end
      end
    end
  end
end
