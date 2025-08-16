require 'rails_helper'

RSpec.describe "Dojos", type: :request do
  describe "GET /dojos with year parameter" do
    before do
      # テストデータの準備
      # 2020年に作成されたアクティブな道場
      @dojo_2020_active = create(:dojo, 
        name: "Test Dojo 2020",
        created_at: "2020-06-01",
        inactivated_at: nil
      )
      
      # 2020年に作成、2021年に非アクティブ化
      @dojo_2020_inactive = create(:dojo,
        name: "Test Dojo 2020 Inactive",
        created_at: "2020-01-01",
        inactivated_at: "2021-03-01"
      )
      
      # 2021年に作成されたアクティブな道場
      @dojo_2021_active = create(:dojo,
        name: "Test Dojo 2021",
        created_at: "2021-01-01",
        inactivated_at: nil
      )
      
      # 2019年に作成、2020年に非アクティブ化（2020年末時点では非アクティブ）
      @dojo_2019_inactive = create(:dojo,
        name: "Test Dojo 2019 Inactive",
        created_at: "2019-01-01",
        inactivated_at: "2020-06-01"
      )
      
      # counter > 1 の道場
      @dojo_multi_branch = create(:dojo,
        name: "Multi Branch Dojo",
        created_at: "2020-01-01",
        inactivated_at: nil,
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
      
      it "rejects future years" do
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
        
        it "displays default message for all periods" do
          get dojos_path(format: :html)
          expect(response.body).to include('全期間の道場を表示中（非アクティブ含む）')
          expect(response.body).to include('alert-info')
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
      
      it "includes counter field in CSV data rows" do
        get dojos_path(format: :csv)
        
        csv = CSV.parse(response.body, headers: true)
        # 各道場のcounter値が正しく含まれることを確認
        multi_branch_row = csv.find { |row| row["ID"] == @dojo_multi_branch.id.to_s }
        expect(multi_branch_row["道場数"]).to eq("3")
        
        normal_dojo_row = csv.find { |row| row["ID"] == @dojo_2020_active.id.to_s }
        expect(normal_dojo_row["道場数"]).to eq("1")
      end
      
      it "filters counter values correctly for specific year" do
        get dojos_path(year: 2020, format: :csv)
        
        csv = CSV.parse(response.body, headers: true)
        # 2020年末時点でアクティブな道場のみが含まれることを確認
        dojo_ids = csv.map { |row| row["ID"].to_i }
        expect(dojo_ids).to include(@dojo_2020_active.id)
        expect(dojo_ids).to include(@dojo_2020_inactive.id)  # 2021年に非アクティブ化されたので2020年末時点ではアクティブ
        expect(dojo_ids).to include(@dojo_multi_branch.id)
        expect(dojo_ids).not_to include(@dojo_2021_active.id)  # 2021年作成なので含まれない
      end
    end
    
    describe "CSV format specifics" do
      it "includes correct headers" do
        get dojos_path(format: :csv)
        csv = CSV.parse(response.body, headers: true)
        
        # 全期間の場合は閉鎖日カラムが追加される
        expect(csv.headers).to eq(['ID', '道場名', '道場数', '都道府県', 'URL', '設立日', '状態', '閉鎖日'])
      end
      
      it "does not include total row for better data consistency" do
        get dojos_path(format: :csv)
        csv = CSV.parse(response.body)
        
        # 合計行が含まれないことを確認（データ一貫性のため）
        csv.each do |row|
          # IDカラムに「合計」という文字列が含まれないことを確認
          expect(row[0]).not_to eq("合計") if row[0]
        end
        
        # 全ての行がデータ行またはヘッダー行であることを確認
        expect(csv.all? { |row| row.compact.any? }).to be true
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
        expect(response.body).to include('開設数:')
        expect(response.body).to include('合計数:')
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

  describe "GET /dojos/activity" do
    before do
      # アクティブな道場を作成
      @active_dojo = create(:dojo,
        name: "Active Dojo",
        created_at: 1.week.ago,
        inactivated_at: nil
      )
      
      # 非アクティブな道場を作成
      @inactive_dojo = create(:dojo,
        name: "Inactive Dojo",
        created_at: 2.years.ago,
        inactivated_at: 1.year.ago
      )
    end
    
    it "returns http success" do
      get activity_dojos_path
      expect(response).to have_http_status(:success)
    end
    
    it "displays the activity status page" do
      get activity_dojos_path
      expect(response.body).to include("道場別の直近の開催日まとめ")
    end
    
    it "includes only active dojos" do
      get activity_dojos_path
      expect(response.body).to include(@active_dojo.name)
      expect(response.body).not_to include(@inactive_dojo.name)
    end
    
    it "redirects from old URL /events/latest" do
      get "/events/latest"
      expect(response).to redirect_to(activity_dojos_path)
    end
  end
end