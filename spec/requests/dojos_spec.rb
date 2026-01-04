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
      expect(response.body).to include("道場別の活動状況まとめ")
    end
    
    it "includes both active and inactive dojos" do
      get activity_dojos_path
      expect(response.body).to include(@active_dojo.name)
      expect(response.body).to include(@inactive_dojo.name)
    end
    
    it "displays inactive dojos with inactive-item class" do
      get activity_dojos_path
      doc = Nokogiri::HTML(response.body)
      
      # 非アクティブな道場の行を探す（リンク内にある名前を探す）
      inactive_link = doc.xpath("//a[contains(., '#{@inactive_dojo.name}')]").first
      expect(inactive_link).not_to be_nil
      
      # そのリンクを含む行（tr）を取得
      inactive_row = inactive_link.xpath("ancestor::tr").first
      expect(inactive_row).not_to be_nil
      
      # その行のすべてのセルに inactive-item クラスがあることを確認
      inactive_cells = inactive_row.css('td')
      expect(inactive_cells.all? { |cell| cell['class']&.include?('inactive-item') }).to be true
    end
    
    it "sorts inactive dojos by latest event date in descending order" do
      # 複数の非アクティブな道場を作成（異なる作成日で）
      older_inactive_dojo = create(:dojo,
        name: "Older Inactive Dojo",
        created_at: 2.years.ago,  # より古い作成日
        inactivated_at: 6.months.ago
      )
      
      newer_inactive_dojo = create(:dojo,
        name: "Newer Inactive Dojo",  
        created_at: 1.year.ago,  # より新しい作成日
        inactivated_at: 3.months.ago
      )
      
      # db/static_event_histories.yml の形式に合わせてEventHistory を作成
      # より古いイベント
      EventHistory.create!(
        dojo_id: older_inactive_dojo.id,
        dojo_name: older_inactive_dojo.name,
        event_url: 'https://example.com/event1',
        evented_at: 8.months.ago,
        participants: 10,
        service_name: 'static_yml',
        service_group_id: 'static',
        event_id: 1
      )
      
      # より新しいイベント
      EventHistory.create!(
        dojo_id: newer_inactive_dojo.id,
        dojo_name: newer_inactive_dojo.name,
        event_url: 'https://example.com/event2',
        evented_at: 4.months.ago,  # より最近のイベント
        participants: 15,
        service_name: 'static_yml',
        service_group_id: 'static',
        event_id: 2
      )
      
      get activity_dojos_path
      doc = Nokogiri::HTML(response.body)
      
      # 全ての道場の名前を取得（テーブルの最初のセルのリンクから）
      dojo_links = doc.css('table tr td:first-child a')
      dojo_names = dojo_links.map(&:text).map(&:strip)
      
      # 非アクティブな道場の中で、newer_inactive_dojo が older_inactive_dojo より先に表示されることを確認
      newer_index = dojo_names.find_index { |name| name.include?(newer_inactive_dojo.name) }
      older_index = dojo_names.find_index { |name| name.include?(older_inactive_dojo.name) }
      
      expect(newer_index).not_to be_nil
      expect(older_index).not_to be_nil
      expect(newer_index).to be < older_index
    end
    
    it "redirects from old URL /events/latest" do
      get "/events/latest"
      expect(response).to redirect_to(activity_dojos_path)
    end
    
    it "displays proper column headers" do
      get activity_dojos_path
      expect(response.body).to include("掲載日")
      expect(response.body).to include("記録日")
      expect(response.body).to include("ノート")
    end
    
    it "displays created_at date for active dojos" do
      get activity_dojos_path
      # 掲載日は YYYY-MM-DD 形式で表示される
      expect(response.body).to match(@active_dojo.created_at.strftime("%Y-%m-%d"))
    end
    
    it "displays dojo ID same as /dojos page" do
      get activity_dojos_path
      # /dojos ページと同じように ID が表示される
      expect(response.body).to include("(ID: #{@active_dojo.id})")
      expect(response.body).to include("道場名")
    end
    
    it "displays URLs without http://, https://, and www. in note column" do
      # URLを含むnoteを持つ道場を作成
      create(:dojo, 
        name: "Test Dojo",
        note: "Active https://www.example.com/ and http://www.example.net/ and https://example.org/",
        inactivated_at: nil
      )
      
      get activity_dojos_path
      
      # ノート欄の表示テキストに http://, https://, www. が含まれないことを確認
      doc = Nokogiri::HTML(response.body)
      note_cells = doc.css('td.url-cell')
      
      test_cell = note_cells.find { |cell| cell.text.include?("example") }
      expect(test_cell).not_to be_nil
      expect(test_cell.text).not_to include("https://")
      expect(test_cell.text).not_to include("http://")
      expect(test_cell.text).not_to include("www.")
      # リンクは保持されていることを確認
      expect(test_cell.to_html).to include('href="https://www.example.com/"')
      expect(test_cell.to_html).to include('href="http://www.example.net/"')
    end
    
    it "displays Facebook URLs as fb.com in note column" do
      # Facebook URLを含むnoteを持つ道場を作成
      create(:dojo, 
        name: "Test Dojo with Facebook",
        note: "Check out https://www.facebook.com/groups/coderdojo and https://facebook.com/events/123",
        inactivated_at: nil
      )
      
      get activity_dojos_path
      
      # ノート欄の表示テキストで facebook.com が fb.com に短縮されていることを確認
      doc = Nokogiri::HTML(response.body)
      note_cells = doc.css('td.url-cell')
      
      fb_cell = note_cells.find { |cell| cell.text.include?("fb.com") }
      expect(fb_cell).not_to be_nil
      expect(fb_cell.text).to include("fb.com/groups/coderdojo")
      expect(fb_cell.text).to include("fb.com/events/123")
      expect(fb_cell.text).not_to include("facebook.com")
      expect(fb_cell.text).not_to include("www.")
      # 元のリンクは保持されていることを確認
      expect(fb_cell.to_html).to include('href="https://www.facebook.com/groups/coderdojo"')
      expect(fb_cell.to_html).to include('href="https://facebook.com/events/123"')
    end
  end

  describe "GET /dojos/activity - note date priority" do
    before do
      # Create Wakayama-like dojo with old event history but newer note date
      @test_dojo = create(:dojo,
        name: "和歌山テスト",
        created_at: Time.zone.parse("2016-11-01"),
        inactivated_at: nil,
        note: "Active for years - 2025-03-16 https://coderdojo-wakayama.hatenablog.com/entry/2025/03/16/230604"
      )
      
      # Create an old event history record for this dojo
      @old_event = EventHistory.create!(
        dojo_id: @test_dojo.id,
        dojo_name: @test_dojo.name,
        service_name: "facebook",
        event_id: "1761517970842435", 
        participants: 10,
        evented_at: Time.zone.parse("2017-03-12 14:30:00"),
        event_url: "https://www.facebook.com/events/1761517970842435"
      )
    end
    
    it "should prioritize newer note date over older event history" do
      get activity_dojos_path
      
      # Find the dojo row in the response
      dojo_row_match = response.body.match(/#{@test_dojo.name}.*?<\/tr>/m)
      expect(dojo_row_match).not_to be_nil, "Could not find dojo row for #{@test_dojo.name}"
      
      dojo_row = dojo_row_match[0]
      
      # The 記録日 (recorded date) column should show the newer note date (2025-03-16)
      # not the older event history date (2017-03-12)
      expect(dojo_row).to include("2025-03-16"), 
        "Expected to see note date 2025-03-16 in 記録日 column, but found: #{dojo_row}"
      
      expect(dojo_row).not_to include("2017-03-12"), 
        "Should not show old event history date 2017-03-12 when newer note date exists"
    end

    it "should link to note URL when displaying note date in 記録日 column" do
      get activity_dojos_path
      
      # Find the dojo row
      dojo_row_match = response.body.match(/#{@test_dojo.name}.*?<\/tr>/m)
      expect(dojo_row_match).not_to be_nil
      
      dojo_row = dojo_row_match[0]
      
      # Should contain a link to the note URL
      expect(dojo_row).to include("https://coderdojo-wakayama.hatenablog.com/entry/2025/03/16/230604"),
        "Expected to find note URL in the 記録日 column"
    end
    
    it "handles multiple date formats in note (YYYY-MM-DD and YYYY/MM/DD)" do
      # Test with slash format
      slash_format_dojo = create(:dojo,
        name: "スラッシュ形式テスト",
        created_at: Time.zone.parse("2016-01-01"),
        inactivated_at: nil,
        note: "Active - last event 2025/03/16 using Google Forms"
      )
      
      # Create old event history
      EventHistory.create!(
        dojo_id: slash_format_dojo.id,
        dojo_name: slash_format_dojo.name,
        service_name: "connpass",
        event_id: "12345",
        participants: 5,
        evented_at: Time.zone.parse("2017-01-01"),
        event_url: "https://example.com"
      )
      
      get activity_dojos_path
      
      # Should show the note date in standard format
      expect(response.body).to include("2025-03-16"),
        "Should parse YYYY/MM/DD format and display as YYYY-MM-DD"
    end

    it "handles Japanese date format in note (YYYY年MM月DD日)" do
      # Test with Japanese date format
      japanese_format_dojo = create(:dojo,
        name: "日本語形式テスト",
        created_at: Time.zone.parse("2016-01-01"),
        inactivated_at: nil,
        note: "最終開催日: 2025年8月24日 Peatixで申込受付中"
      )
      
      # Create old event history
      EventHistory.create!(
        dojo_id: japanese_format_dojo.id,
        dojo_name: japanese_format_dojo.name,
        service_name: "connpass",
        event_id: "jp123",
        participants: 8,
        evented_at: Time.zone.parse("2017-01-01"),
        event_url: "https://example.com"
      )
      
      get activity_dojos_path
      
      # Find the dojo row
      dojo_row_match = response.body.match(/#{japanese_format_dojo.name}.*?<\/tr>/m)
      expect(dojo_row_match).not_to be_nil
      
      dojo_row = dojo_row_match[0]
      
      # Should show the Japanese date in standard format (2025-08-24)
      expect(dojo_row).to include("2025-08-24"),
        "Should parse YYYY年MM月DD日 format and display as YYYY-MM-DD"
    end

    it "shows event history date when it's newer than note date" do
      # Create dojo with older note date
      newer_event_dojo = create(:dojo,
        name: "イベント履歴が新しいテスト",
        created_at: Time.zone.parse("2016-01-01"),
        inactivated_at: nil,
        note: "Last manual event - 2025-03-16 using Google Forms"
      )
      
      # Create newer event history (newer than note date)
      newer_event = EventHistory.create!(
        dojo_id: newer_event_dojo.id,
        dojo_name: newer_event_dojo.name,
        service_name: "connpass",
        event_id: "67890",
        participants: 15,
        evented_at: Time.zone.parse("2025-08-01 19:00:00"),  # Newer than note date
        event_url: "https://example-newer.com"
      )
      
      get activity_dojos_path
      
      # Find the dojo row
      dojo_row_match = response.body.match(/#{newer_event_dojo.name}.*?<\/tr>/m)
      expect(dojo_row_match).not_to be_nil
      
      dojo_row = dojo_row_match[0]
      
      # Extract just the 記録日 column to check the date display
      td_matches = dojo_row.scan(/<td[^>]*>(.*?)<\/td>/m)
      
      # Based on debug output: td_matches[0] is the 記録日 column (列順変更後)
      # (道場名 column seems to be skipped in regex due to complex link structure)
      event_date_column = td_matches[0]&.first # 記録日 column
      
      expect(event_date_column).not_to be_nil, "Could not find 記録日 column"
      
      # Should show the newer event history date (2025-08-01) in the 記録日 column
      expect(event_date_column).to include("2025-08-01"),
        "Expected to see newer event history date 2025-08-01 in 記録日 column, but found: #{event_date_column}"
      
      # The 記録日 column should not contain the older note date
      expect(event_date_column).not_to include("2025-03-16"),
        "Should not show older note date 2025-03-16 in 記録日 column when newer event history exists"
    end
  end
end