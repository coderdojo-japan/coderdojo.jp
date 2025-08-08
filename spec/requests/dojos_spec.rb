require 'rails_helper'

RSpec.describe "Dojos", type: :request do
  describe "GET /dojos with year parameter" do
    before do
      # テストデータの準備
      # 2020年に作成されたアクティブな道場
      @dojo_2020_active = create(:dojo, 
        name: "Test Dojo 2020",
        created_at: "2020-06-01",
        is_active: true
      )
      
      # 2020年に作成、2021年に非アクティブ化
      @dojo_2020_inactive = create(:dojo,
        name: "Test Dojo 2020 Inactive",
        created_at: "2020-01-01",
        is_active: false,
        inactivated_at: "2021-03-01"
      )
      
      # 2021年に作成されたアクティブな道場
      @dojo_2021_active = create(:dojo,
        name: "Test Dojo 2021",
        created_at: "2021-01-01",
        is_active: true
      )
      
      # 2019年に作成、2020年に非アクティブ化（2020年末時点では非アクティブ）
      @dojo_2019_inactive = create(:dojo,
        name: "Test Dojo 2019 Inactive",
        created_at: "2019-01-01",
        is_active: false,
        inactivated_at: "2020-06-01"
      )
      
      # counter > 1 の道場
      @dojo_multi_branch = create(:dojo,
        name: "Multi Branch Dojo",
        created_at: "2020-01-01",
        is_active: true,
        counter: 3
      )
    end
    
    describe "year parameter validation" do
      it "accepts valid years (2012 to current year)" do
        current_year = Date.current.year
        [2012, 2020, current_year].each do |year|
          get dojos_path(year: year, format: :json)
          expect(response).to have_http_status(:success)
        end
      end
      
      it "rejects years before 2012" do
        get dojos_path(year: 2011, format: :json)
        expect(response).to redirect_to(dojos_path(anchor: 'table'))
        expect(flash[:inline_alert]).to include("2012年から")
      end
      
      it "rejects years after current year" do
        future_year = Date.current.year + 1
        get dojos_path(year: future_year, format: :json)
        expect(response).to redirect_to(dojos_path(anchor: 'table'))
        expect(flash[:inline_alert]).to include("指定された年は無効です")
      end
      
      it "handles invalid year strings" do
        get dojos_path(year: "invalid", format: :json)
        expect(response).to redirect_to(dojos_path(anchor: 'table'))
        expect(flash[:inline_alert]).to include("無効")
      end
    end
    
    describe "year filtering functionality" do
      context "when no year parameter is provided" do
        it "returns all dojos (active and inactive)" do
          get dojos_path(format: :json)
          json_response = JSON.parse(response.body)
          
          dojo_ids = json_response.map { |d| d["id"] }
          expect(dojo_ids).to include(@dojo_2020_active.id)
          expect(dojo_ids).to include(@dojo_2020_inactive.id)
          expect(dojo_ids).to include(@dojo_2021_active.id)
          expect(dojo_ids).to include(@dojo_2019_inactive.id)
          expect(dojo_ids).to include(@dojo_multi_branch.id)
        end
        
        it "includes inactive dojos in HTML format" do
          get dojos_path(format: :html)
          expect(assigns(:dojos).map { |d| d[:id] }).to include(@dojo_2020_inactive.id)
        end
        
        it "includes inactive dojos in CSV format" do
          get dojos_path(format: :csv)
          csv = CSV.parse(response.body, headers: true)
          csv_ids = csv.map { |row| row["ID"].to_i }
          expect(csv_ids).to include(@dojo_2020_inactive.id)
        end
      end
      
      context "when year=2020 is specified" do
        it "returns only dojos active at the end of 2020" do
          get dojos_path(year: 2020, format: :json)
          json_response = JSON.parse(response.body)
          
          dojo_ids = json_response.map { |d| d["id"] }
          # 2020年末時点でアクティブだった道場のみ含まれる
          expect(dojo_ids).to include(@dojo_2020_active.id)
          expect(dojo_ids).to include(@dojo_multi_branch.id)
          
          # 2020年末時点で非アクティブだった道場は含まれない
          expect(dojo_ids).not_to include(@dojo_2019_inactive.id)
          
          # 2021年に作成された道場は含まれない
          expect(dojo_ids).not_to include(@dojo_2021_active.id)
          
          # 2021年に非アクティブ化された道場は2020年末時点ではアクティブなので含まれる
          expect(dojo_ids).to include(@dojo_2020_inactive.id)
        end
        
        it "filters correctly in HTML format" do
          get dojos_path(year: 2020, format: :html)
          
          dojo_ids = assigns(:dojos).map { |d| d[:id] }
          expect(dojo_ids).to include(@dojo_2020_active.id)
          expect(dojo_ids).not_to include(@dojo_2019_inactive.id)
          expect(dojo_ids).not_to include(@dojo_2021_active.id)
        end
        
        it "does not show inactivated styling for dojos active in 2020" do
          get dojos_path(year: 2020, format: :html)
          
          # HTMLレスポンスを取得
          html = response.body
          
          # 2021年に非アクティブ化された道場（Test Dojo 2020 Inactive）が含まれていることを確認
          expect(html).to include("Test Dojo 2020 Inactive")
          
          # その道場の行を探す（IDで特定）
          dojo_row_match = html.match(/Test Dojo 2020 Inactive.*?<\/tr>/m)
          expect(dojo_row_match).not_to be_nil
          
          dojo_row = dojo_row_match[0]
          
          # 重要: この道場は2021年3月に非アクティブ化されたが、
          # 2020年末時点ではアクティブだったので、inactive-item クラスを持たないべき
          # 現在のコードはここで失敗するはず（現在の is_active: false を使っているため）
          expect(dojo_row).not_to include('class="inactive-item"')
        end
        
        it "filters correctly in CSV format" do
          get dojos_path(year: 2020, format: :csv)
          
          csv = CSV.parse(response.body, headers: true)
          csv_ids = csv.map { |row| row["ID"].to_i }
          expect(csv_ids).to include(@dojo_2020_active.id)
          expect(csv_ids).not_to include(@dojo_2019_inactive.id)
          expect(csv_ids).not_to include(@dojo_2021_active.id)
        end
      end
      
      context "when year=2021 is specified" do
        it "returns dojos active at the end of 2021" do
          get dojos_path(year: 2021, format: :json)
          json_response = JSON.parse(response.body)
          
          dojo_ids = json_response.map { |d| d["id"] }
          # 2021年末時点でアクティブな道場
          expect(dojo_ids).to include(@dojo_2020_active.id)
          expect(dojo_ids).to include(@dojo_2021_active.id)
          expect(dojo_ids).to include(@dojo_multi_branch.id)
          
          # 2021年3月に非アクティブ化された道場は含まれない
          expect(dojo_ids).not_to include(@dojo_2020_inactive.id)
          expect(dojo_ids).not_to include(@dojo_2019_inactive.id)
        end
        
        it "does not show any inactivated dojos for year 2021" do
          get dojos_path(year: 2021, format: :html)
          
          html = response.body
          
          # 2021年末時点でアクティブな道場のみが含まれる
          expect(html).to include("Test Dojo 2020")      # アクティブ
          expect(html).to include("Test Dojo 2021")      # アクティブ
          expect(html).to include("Multi Branch Dojo")   # アクティブ
          
          # 2021年に非アクティブ化された道場は含まれない
          expect(html).not_to include("Test Dojo 2020 Inactive")
          expect(html).not_to include("Test Dojo 2019 Inactive")
          
          # すべての表示された道場は inactive-item クラスを持たないべき
          # （2021年末時点ではすべてアクティブなので）
          expect(html.scan('class="inactive-item"').count).to eq(0)
        end
      end
    end
    
    describe "counter field in output" do
      it "includes counter field in JSON response" do
        get dojos_path(format: :json)
        json_response = JSON.parse(response.body)
        
        multi_branch = json_response.find { |d| d["id"] == @dojo_multi_branch.id }
        expect(multi_branch["counter"]).to eq(3)
      end
      
      it "includes counter column in CSV with sum total" do
        get dojos_path(format: :csv)
        csv = CSV.parse(response.body, headers: true)
        
        # ヘッダーに道場数が含まれる
        expect(csv.headers).to include("道場数")
        
        # 各道場のcounter値が含まれる
        multi_branch_row = csv.find { |row| row["ID"] == @dojo_multi_branch.id.to_s }
        expect(multi_branch_row["道場数"]).to eq("3")
      end
      
      it "calculates counter_sum correctly for CSV" do
        get dojos_path(format: :csv)
        
        expected_sum = [@dojo_2020_active, @dojo_2020_inactive, @dojo_2021_active, 
                       @dojo_2019_inactive, @dojo_multi_branch].sum(&:counter)
        # @counter_sum はCSVで使用されるので、CSVリクエスト時に検証
        csv = CSV.parse(response.body)
        last_line = csv.last
        expect(last_line[2]).to eq(expected_sum.to_s)
      end
      
      it "calculates counter_sum for filtered year in CSV" do
        get dojos_path(year: 2020, format: :csv)
        
        # 2020年末時点でアクティブな道場のcounter合計
        active_in_2020 = [@dojo_2020_active, @dojo_2020_inactive, @dojo_multi_branch]
        expected_sum = active_in_2020.sum(&:counter)
        csv = CSV.parse(response.body)
        last_line = csv.last
        expect(last_line[2]).to eq(expected_sum.to_s)
      end
    end
    
    describe "CSV format specifics" do
      it "includes correct headers" do
        get dojos_path(format: :csv)
        csv = CSV.parse(response.body, headers: true)
        
        expect(csv.headers).to eq(['ID', '道場名', '道場数', '都道府県', 'URL', '設立日', '状態'])
      end
      
      it "includes total row at the end" do
        get dojos_path(format: :csv)
        lines = response.body.split("\n")
        
        # 最後の行が合計行
        last_line = lines.last
        expect(last_line).to include("合計")
        expect(last_line).to include("道場")
      end
      
      it "formats dates correctly" do
        get dojos_path(format: :csv)
        csv = CSV.parse(response.body, headers: true)
        
        first_dojo = csv.first
        expect(first_dojo["設立日"]).to match(/\d{4}-\d{2}-\d{2}/)
      end
      
      it "shows active/inactive status correctly" do
        get dojos_path(format: :csv)
        csv = CSV.parse(response.body, headers: true)
        
        active_row = csv.find { |row| row["ID"] == @dojo_2020_active.id.to_s }
        expect(active_row["状態"]).to eq("アクティブ")
        
        inactive_row = csv.find { |row| row["ID"] == @dojo_2020_inactive.id.to_s }
        expect(inactive_row["状態"]).to eq("非アクティブ")
      end
    end
    
    describe "HTML format year selection UI" do
      it "shows year selection form with auto-submit" do
        get dojos_path
        expect(response.body).to include('対象期間')
        expect(response.body).to include('<select')
        expect(response.body).to include('onchange')
        expect(response.body).to include('2012')
        expect(response.body).to include(Date.current.year.to_s)
      end
      
      it "displays selected year message when filtered" do
        get dojos_path(year: 2020)
        expect(response.body).to include('2020年末時点')
        expect(response.body).to include('アクティブな道場を表示中')
        # 統計情報が含まれていることを確認（/statsページとの比較検証用）
        expect(response.body).to include('開設道場数:')
        expect(response.body).to include('合計道場数:')
        # inline_infoメッセージが表示されることを確認
        expect(response.body).to include('alert-info')
      end
      
      it "includes CSV and JSON download links with year parameter" do
        get dojos_path(year: 2020)
        expect(response.body).to include('CSV')
        expect(response.body).to include('JSON')
        expect(response.body).to include('year=2020')
      end
    end
  end
end