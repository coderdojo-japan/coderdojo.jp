# 📊 道場統計年次ダウンロード機能 - 実装計画

## 概要
CoderDojoの統計データを年次でダウンロードできる機能を実装する。`/dojos` ページにクエリパラメータ（`?year=2024`）を追加することで、特定年のデータや全年次統計をCSV/JSON形式でダウンロード可能にする。既存の `/stats` ページとの混乱を避けるため、`/dojos` エンドポイントを拡張する形で実装する。

### データの取得範囲
- **yearパラメータなし（デフォルト）**:
  - HTML表示: 現在アクティブな道場のみ（既存の動作を維持）
  - CSV/JSONダウンロード: 全道場（アクティブ + 非アクティブ）
- **yearパラメータあり（例: year=2024）**:
  - HTML/JSON/CSV すべての形式: その年末時点でアクティブだった道場のみ

## 🎯 要件定義

### Phase 1: 基本実装（MVP）
1. `/dojos` ページに年次フィルタリング機能を追加
2. 特定年のアクティブ道場リストをCSV/JSON形式でダウンロード可能に
3. データ内容：
   - yearパラメータなし: 全道場リスト（アクティブ + 非アクティブ）
   - yearパラメータあり: その年末時点のアクティブ道場リスト
4. 対応形式：
   - HTML（表示用）
   - CSV（ダウンロード用）
   - JSON（API用）

### Phase 2: 拡張機能（将来）
- 都道府県別・地域別でのフィルタリング（例: ?year=2024&prefecture=東京都）
- イベント数・参加者数の統計も含める
- 年次推移の統計データ（全年の集計データ）
- より詳細なCSVエクスポートオプション

## 🏗️ 技術設計

### 1. ルーティング設計

```ruby
# config/routes.rb

# 既存のルーティングをそのまま活用
get '/dojos',     to: 'dojos#index'      # HTML, JSON, CSV（拡張）
get '/dojos/:id', to: 'dojos#show'       # HTML, JSON, CSV

# URLパターン例：
# GET /dojos                  → 現在のアクティブ道場一覧（HTML）
# GET /dojos?year=2024        → 2024年末時点のアクティブ道場一覧（HTML）
# GET /dojos.csv              → 全道場リスト（アクティブ + 非アクティブ）
# GET /dojos.csv?year=2024    → 2024年末時点のアクティブ道場リスト（CSV）
# GET /dojos.json             → 全道場リスト（アクティブ + 非アクティブ）
# GET /dojos.json?year=2024   → 2024年末時点のアクティブ道場リスト（JSON）
```

### 2. コントローラー設計

```ruby
# app/controllers/dojos_controller.rb

class DojosController < ApplicationController
  # 既存のindexアクションを拡張
  def index
    # yearパラメータがある場合の処理
    if params[:year].present?
      year = params[:year].to_i
      # 有効な年の範囲をチェック
      unless year.between?(2012, Date.current.year)
        flash[:alert] = "指定された年（#{year}）は無効です。2012年から#{Date.current.year}年の間で指定してください。"
        return redirect_to dojos_path
      end
      
      @selected_year = year
      end_of_year = Time.zone.local(@selected_year).end_of_year
      
      # その年末時点でアクティブだった道場を取得
      @dojos = []
      Dojo.active_at(end_of_year).includes(:prefecture).order(order: :asc).each do |dojo|
        @dojos << {
          id:          dojo.id,
          url:         dojo.url,
          name:        dojo.name,
          logo:        root_url + dojo.logo[1..],
          order:       dojo.order,
          counter:     dojo.counter,
          is_active:   dojo.active_at?(end_of_year),
          prefecture:  dojo.prefecture.name,
          created_at:  dojo.created_at,
          description: dojo.description,
        }
      end
      
      @page_title = "#{@selected_year}年末時点のCoderDojo一覧"
    else
      # yearパラメータなしの場合
      # HTML表示: 現在のアクティブな道場のみ（既存の実装を維持）
      # CSV/JSONダウンロード: 全道場（アクティブ + 非アクティブ）
      if request.format.html?
        # HTMLの場合は現在アクティブな道場のみ
        dojos_scope = Dojo.active
      else
        # CSV/JSONの場合は全道場（非アクティブも含む）
        dojos_scope = Dojo.all
      end
      
      @dojos = []
      dojos_scope.includes(:prefecture).order(order: :asc).each do |dojo|
        @dojos << {
          id:          dojo.id,
          url:         dojo.url,
          name:        dojo.name,
          logo:        root_url + dojo.logo[1..],
          order:       dojo.order,
          counter:     dojo.counter,
          is_active:   dojo.is_active,
          prefecture:  dojo.prefecture.name,
          created_at:  dojo.created_at,
          description: dojo.description,
        }
      end
    end

    # respond_toで形式ごとに処理を分岐
    respond_to do |format|
      format.html { render :index }  # => app/views/dojos/index.html.erb
      format.json { render json: @dojos }
      format.csv  { send_data render_to_string, type: :csv }
    end
  end

  def show
    # 既存の実装のまま
  end
  
  private
  
  def render_yearly_stats
    @period_start = 2012
    @period_end = Date.current.year
    
    # yearパラメータが指定されている場合（整数のみ許可）
    if @selected_year  # 既にindexアクションで設定済み
      period = Time.zone.local(@selected_year).beginning_of_year..Time.zone.local(@selected_year).end_of_year
      @stat = Stat.new(period)
      @yearly_data = prepare_single_year_data(@stat, @selected_year)
      filename_suffix = @selected_year.to_s
    else
      # yearパラメータなし = 全年次データ
      period = Time.zone.local(@period_start).beginning_of_year..Time.zone.local(@period_end).end_of_year
      @stat = Stat.new(period)
      @yearly_data = prepare_all_years_data(@stat)
      filename_suffix = 'all'
    end
    
    # CSVまたはJSONとして返す
    respond_to do |format|
      format.csv do
        send_data render_to_string(template: 'dojos/yearly_stats'),
                  type: :csv,
                  filename: "coderdojo_stats_#{filename_suffix}_#{Date.current.strftime('%Y%m%d')}.csv"
      end
      format.json { render json: @yearly_data }
    end
  end
  
  def prepare_all_years_data(stat)
    active_dojos = stat.annual_dojos_with_historical_data
    new_dojos = stat.annual_new_dojos_count
    
    # 年ごとのデータを整形
    years = (@period_start..@period_end).map(&:to_s)
    years.map do |year|
      prev_year = (year.to_i - 1).to_s
      {
        year: year,
        active_dojos_at_year_end: active_dojos[year] || 0,
        new_dojos: new_dojos[year] || 0,
        inactivated_dojos: calculate_inactivated_count(year),
        cumulative_total: active_dojos[year] || 0,
        net_change: prev_year && active_dojos[prev_year] ? 
          (active_dojos[year] || 0) - active_dojos[prev_year] : 
          (active_dojos[year] || 0)
      }
    end
  end
  
  def prepare_single_year_data(stat, year)
    # 特定年のアクティブな道場リストを返す
    end_of_year = Time.zone.local(year).end_of_year
    dojos = Dojo.active_at(end_of_year).includes(:prefecture)
    
    dojos.map do |dojo|
      {
        id: dojo.id,
        name: dojo.name,
        prefecture: dojo.prefecture.name,
        url: dojo.url,
        created_at: dojo.created_at.strftime('%Y-%m-%d'),
        is_active_at_year_end: dojo.active_at?(end_of_year)
      }
    end
  end
  
  def calculate_inactivated_count(year)
    start_of_year = Time.zone.local(year.to_i).beginning_of_year
    end_of_year = Time.zone.local(year.to_i).end_of_year
    Dojo.where(inactivated_at: start_of_year..end_of_year).sum(:counter)
  end
end
```

### 3. ビュー設計

#### 3.1 `/dojos/index.html.erb` の更新

```erb
<!-- 既存のJSON変換リンクの下に追加 -->
<div class='form__terms list'>
  <ul style='list-style-type: "\2713\0020"; font-size: smaller;'>
    <li>現在は活動停止中 (In-active) の道場も表示されています</li>
    <li>道場名をクリックすると個別の統計データが確認できます</li>
    <li>下記表は <code><%= link_to dojos_path(format: :json), dojos_path(format: :json) %></code> で JSON に変換できます</li>
  </ul>
</div>

<!-- 新規追加: 年次統計ダウンロードセクション -->
<div class="yearly-stats-download" style="margin: 30px 0; padding: 20px; background: #f8f9fa; border-radius: 8px;">
  <h3>📊 年次統計データのダウンロード</h3>
  
  <% if @selected_year %>
    <div class="alert alert-info">
      <strong><%= @selected_year %>年末時点</strong>のデータを表示中
      <%= link_to '現在のデータを表示', dojos_path, class: 'btn btn-sm btn-outline-primary ml-2' %>
    </div>
  <% end %>
  
  <%= form_with(url: dojos_path, method: :get, local: true, html: { class: 'form-inline' }) do |f| %>
    <div class="form-group">
      <%= label_tag :year, '年を選択:', class: 'mr-2' %>
      <%= select_tag :year, 
          options_for_select(
            [['全年次データ', '']] + (2012..Date.current.year).map { |y| [y.to_s + '年', y] },
            params[:year]
          ),
          include_blank: false,
          class: 'form-control mr-2' %>
    </div>
    
    <div class="btn-group" role="group">
      <%= button_tag type: 'submit', class: 'btn btn-info' do %>
        <i class="fas fa-eye"></i> 表示
      <% end %>
      <%= button_tag type: 'submit', name: 'format', value: 'csv', class: 'btn btn-primary' do %>
        <i class="fas fa-file-csv"></i> CSV ダウンロード
      <% end %>
      <%= button_tag type: 'submit', name: 'format', value: 'json', class: 'btn btn-secondary' do %>
        <i class="fas fa-file-code"></i> JSON ダウンロード
      <% end %>
    </div>
  <% end %>
  
  <p class="text-muted mt-2" style="font-size: smaller;">
    ※ 年を選択すると、その年末時点でアクティブだった道場の統計データをダウンロードできます。<br>
    ※ 「全年次データ」を選択すると、2012年〜現在までの年次推移データをダウンロードできます。
  </p>
</div>
```

#### 3.2 `/dojos/yearly_stats.csv.ruby` の新規作成

```ruby
require 'csv'

csv_data = CSV.generate do |csv|
  if @selected_year
    # 特定年のデータ（道場リスト）
    csv << ['ID', '道場名', '都道府県', 'URL', '設立日', '状態']
    
    @yearly_data.each do |dojo|
      csv << [
        dojo[:id],
        dojo[:name],
        dojo[:prefecture],
        dojo[:url],
        dojo[:created_at],
        dojo[:is_active_at_year_end] ? 'アクティブ' : '非アクティブ'
      ]
    end
  else
    # 全年次統計データ
    csv << ['年', '年末アクティブ道場数', '新規開設数', '非アクティブ化数', '累積合計', '純増減']
    
    @yearly_data.each do |data|
      csv << [
        data[:year],
        data[:active_dojos_at_year_end],
        data[:new_dojos],
        data[:inactivated_dojos],
        data[:cumulative_total],
        data[:net_change]
      ]
    end
    
    # 合計行
    csv << []
    csv << ['合計', '', 
            @yearly_data.sum { |d| d[:new_dojos] },
            @yearly_data.sum { |d| d[:inactivated_dojos] },
            @yearly_data.last[:cumulative_total],
            '']
  end
end
```

### 4. データ構造

#### CSVファイル例
```csv
年,年末アクティブ道場数,新規開設数,非アクティブ化数,累積合計,純増減
2012,1,1,0,1,1
2013,4,3,0,4,3
2014,8,4,0,8,4
2015,16,8,0,16,8
2016,29,13,0,29,13
2017,77,48,0,77,48
2018,172,54,0,172,95
2019,200,50,22,200,28
2020,222,26,4,222,22
2021,236,19,5,236,14
2022,225,20,31,225,-11
2023,199,20,46,199,-26
2024,206,15,8,206,7

合計,,329,116,206,
```

#### JSON形式例
```json
[
  {
    "year": "2012",
    "active_dojos_at_year_end": 1,
    "new_dojos": 1,
    "inactivated_dojos": 0,
    "cumulative_total": 1,
    "net_change": 1
  },
  {
    "year": "2013",
    "active_dojos_at_year_end": 4,
    "new_dojos": 3,
    "inactivated_dojos": 0,
    "cumulative_total": 4,
    "net_change": 3
  },
  // ...
]
```

## 🧪 テスト計画

### 1. コントローラーテスト

```ruby
# spec/controllers/dojos_controller_spec.rb

RSpec.describe DojosController, type: :controller do
  describe 'GET #index with year parameter' do
    before do
      # テストデータの準備
      create(:dojo, created_at: '2020-01-01', is_active: true)
      create(:dojo, created_at: '2020-06-01', is_active: false, inactivated_at: '2021-03-01')
      create(:dojo, created_at: '2021-01-01', is_active: true)
    end
    
    context '全年次データ（yearパラメータなし）' do
      it 'CSVファイルがダウンロードされる' do
        get :index, format: :csv
        expect(response.content_type).to eq('text/csv')
        expect(response.headers['Content-Disposition']).to include('coderdojo_stats_all_')
      end
      
      it '正しいヘッダーとデータが含まれる' do
        get :index, format: :csv
        csv = CSV.parse(response.body)
        expect(csv[0]).to eq(['年', '年末アクティブ道場数', '新規開設数', '非アクティブ化数', '累積合計', '純増減'])
      end
      
      it 'yearパラメータなしの場合は非アクティブな道場も含む（CSV/JSON）' do
        active_dojo = create(:dojo, is_active: true)
        inactive_dojo = create(:dojo, is_active: false, inactivated_at: '2021-03-01')
        
        # JSON形式: 全道場を含む
        get :index, format: :json
        json_response = JSON.parse(response.body)
        json_ids = json_response.map { |d| d['id'] }
        expect(json_ids).to include(active_dojo.id)
        expect(json_ids).to include(inactive_dojo.id)
        
        # CSV形式: 全道場を含む
        get :index, format: :csv
        csv = CSV.parse(response.body, headers: true)
        csv_ids = csv.map { |row| row['ID'].to_i }
        expect(csv_ids).to include(active_dojo.id)
        expect(csv_ids).to include(inactive_dojo.id)
        
        # HTML形式: アクティブな道場のみ（既存の動作を維持）
        get :index, format: :html
        expect(assigns(:dojos).map { |d| d[:id] }).to include(active_dojo.id)
        expect(assigns(:dojos).map { |d| d[:id] }).not_to include(inactive_dojo.id)
      end
    end
    
    context '特定年のデータ（year=2020）' do
      it 'CSVファイルがダウンロードされる' do
        get :index, params: { year: '2020' }, format: :csv
        expect(response.content_type).to eq('text/csv')
        expect(response.headers['Content-Disposition']).to include('coderdojo_stats_2020_')
      end
      
      it '2020年末時点のアクティブな道場リストが返される' do
        get :index, params: { year: '2020' }, format: :csv
        csv = CSV.parse(response.body)
        expect(csv[0]).to eq(['ID', '道場名', '都道府県', 'URL', '設立日', '状態'])
        expect(csv.size - 1).to eq(2)  # ヘッダーを除いて2道場
      end
      
      it 'yearパラメータ指定時は非アクティブな道場を含まない（全形式）' do
        # テストデータ: 2020年にアクティブ、2021年に非アクティブ化した道場
        inactive_dojo = create(:dojo, 
          created_at: '2019-01-01', 
          is_active: false, 
          inactivated_at: '2021-03-01'
        )
        
        # HTML形式
        get :index, params: { year: '2020' }, format: :html
        expect(assigns(:dojos).map { |d| d[:id] }).not_to include(inactive_dojo.id)
        
        # JSON形式
        get :index, params: { year: '2020' }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response.map { |d| d['id'] }).not_to include(inactive_dojo.id)
        
        # CSV形式
        get :index, params: { year: '2020' }, format: :csv
        csv = CSV.parse(response.body, headers: true)
        csv_ids = csv.map { |row| row['ID'].to_i }
        expect(csv_ids).not_to include(inactive_dojo.id)
      end
    end
    
    context '無効な年が指定された場合' do
      it 'エラーが返される' do
        get :index, params: { year: '1999' }, format: :csv
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to include('Year must be between')
      end
      
      it '文字列が指定された場合も適切に処理される' do
        get :index, params: { year: 'invalid' }, format: :csv
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
```

### 2. 統合テスト

```ruby
# spec/features/dojos_download_spec.rb

RSpec.feature 'Dojos yearly stats download', type: :feature do
  scenario 'ユーザーが全年次統計をダウンロードする' do
    visit dojos_path
    
    # 年選択セクションが表示される
    expect(page).to have_select('year')
    expect(page).to have_button('CSV ダウンロード')
    
    # 全年次データを選択
    select '全年次データ', from: 'year'
    click_button 'CSV ダウンロード'
    
    # ファイルがダウンロードされる
    expect(page.response_headers['Content-Type']).to eq('text/csv')
    expect(page.response_headers['Content-Disposition']).to include('coderdojo_stats_all')
  end
  
  scenario 'ユーザーが特定年のデータをダウンロードする' do
    visit dojos_path
    
    # 2024年を選択
    select '2024年', from: 'year'
    click_button 'CSV ダウンロード'
    
    # ファイルがダウンロードされる
    expect(page.response_headers['Content-Type']).to eq('text/csv')
    expect(page.response_headers['Content-Disposition']).to include('coderdojo_stats_2024')
  end
end
```

## 📋 実装ステップ

### Phase 1: 基本実装（2-3日）
1. [ ] `dojos_controller.rb` の `index` アクションを拡張
2. [ ] `render_yearly_stats` プライベートメソッドの実装
3. [ ] `prepare_all_years_data` と `prepare_single_year_data` メソッドの実装
4. [ ] CSVビューテンプレート (`yearly_stats.csv.ruby`) の作成
5. [ ] `/dojos/index.html.erb` に年選択フォームとダウンロードボタンを追加
6. [ ] テストの作成と実行
7. [ ] 本番データでの動作確認

### Phase 2: 拡張機能（将来）
1. [ ] 年別フィルタリング機能
2. [ ] 都道府県別統計の追加
3. [ ] イベント数・参加者数の統計追加
4. [ ] より詳細なCSVエクスポートオプション

## 🎨 UIデザイン案

### オプション1: シンプルなリンク
現在のJSONリンクと同じスタイルで、CSVダウンロードリンクを追加

### オプション2: ボタン形式
```html
<div class="download-section">
  <h3>📊 統計データのダウンロード</h3>
  <div class="btn-group">
    <a href="/dojos/stats/yearly.csv" class="btn btn-primary">
      <i class="fas fa-file-csv"></i> CSV形式
    </a>
    <a href="/dojos/stats/yearly.json" class="btn btn-secondary">
      <i class="fas fa-file-code"></i> JSON形式
    </a>
  </div>
</div>
```

### オプション3: ドロップダウンメニュー（将来的な拡張用）
```html
<div class="dropdown">
  <button class="btn btn-primary dropdown-toggle" data-toggle="dropdown">
    📊 統計データをダウンロード
  </button>
  <div class="dropdown-menu">
    <h6 class="dropdown-header">年次統計</h6>
    <a class="dropdown-item" href="/dojos/stats/yearly.csv">全期間 (CSV)</a>
    <a class="dropdown-item" href="/dojos/stats/yearly.json">全期間 (JSON)</a>
    <div class="dropdown-divider"></div>
    <h6 class="dropdown-header">年別データ</h6>
    <a class="dropdown-item" href="/dojos/stats/2024.csv">2024年</a>
    <a class="dropdown-item" href="/dojos/stats/2023.csv">2023年</a>
    <!-- ... -->
  </div>
</div>
```

## 🚀 性能考慮事項

1. **キャッシング**
   - 統計データの計算は重いため、結果をキャッシュすることを検討
   - Rails.cache を使用して1日単位でキャッシュ

2. **データ量**
   - 現在は約13年分のデータなので問題ないが、将来的にデータが増えた場合はページネーションや期間指定を検討

3. **バックグラウンド処理**
   - 大量データの場合は、CSVファイル生成をバックグラウンドジョブで処理し、完了後にダウンロードリンクを送信することも検討

## 📝 注意事項

1. **データの正確性**
   - `inactivated_at` が設定されているDojoのみが非アクティブ化数に含まれる
   - 過去のデータは `annual_dojos_with_historical_data` メソッドに依存

2. **国際化対応**
   - 将来的に英語版も必要な場合は、ヘッダーの翻訳を考慮

3. **セキュリティ**
   - 公開データのみを含めること
   - 個人情報や内部情報は含めない

## 🔗 関連リソース

- 既存の個別道場CSV実装: `/app/views/dojos/show.csv.ruby`
- 統計ページの実装: `/app/controllers/stats_controller.rb`
- Statモデル: `/app/models/stat.rb`
- Issue: #[未定]

## 📅 タイムライン

- **Week 1**: 基本実装（Phase 1）
  - Day 1-2: コントローラーとビューの実装
  - Day 3: テストとデバッグ
- **Week 2**: レビューと改善
  - フィードバックの反映
  - ドキュメント更新
- **将来**: Phase 2の実装（必要に応じて）