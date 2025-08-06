# inactivated_at カラム追加の実装計画

## 背景と目的

### 現状の問題点 (Issue #1373)
- 現在、Dojoが `is_active: false` に設定されると、統計グラフから完全に消えてしまう
- 過去に活動していたDojo（例：2012-2014年に活動）の履歴データが統計に反映されない
- Dojoの活動履歴を正確に可視化できない

### 具体例：道場数の推移グラフ（/stats）
現在の実装（`app/models/stat.rb`）:
```ruby
def annual_dojos_chart(lang = 'ja')
  # Active Dojo のみを集計対象としている
  HighChartsBuilder.build_annual_dojos(Dojo.active.annual_count(@period), lang)
end
```

**問題**: 
- 2016年に開始し2019年に非アクティブになったDojoは、2016-2018年のグラフにも表示されない
- 実際には124個（約38%）のDojoが過去の統計から除外されている

### 解決策
- `inactivated_at` カラム（DateTime型）を追加し、非アクティブになった正確な日時を記録
- 統計グラフでは、その期間中に活動していたDojoを適切に表示
- 将来的には `is_active` ブール値を `inactivated_at` で完全に置き換える

### 期待される変化
`inactivated_at` 導入後、道場数の推移グラフは以下のように変化する：
- 各年の道場数が増加（過去に活動していたDojoが含まれるため）
- より正確な成長曲線が表示される
- 例：2018年の統計に、2019年に非アクティブになったDojoも含まれる

## カラム名の選択: `inactivated_at`

### なぜ `inactivated_at` を選んだか

1. **文法的な正しさ**
   - Railsの命名規則: 動詞の過去分詞 + `_at`（例: `created_at`, `updated_at`）
   - `inactivate`（動詞）→ `inactivated`（過去分詞）
   - `inactive`は形容詞なので、`inactived`という過去分詞は存在しない

2. **CoderDojoの文脈での適切性**
   - `inactivated_at`: Dojoが活動を停止した（活動していない状態になった）
   - `deactivated_at`: Dojoを意図的に無効化した（管理者が停止した）という印象
   - CoderDojoは「活動」するものなので、「非活動」という状態変化が自然

3. **既存の `is_active` との一貫性**
   - `active` → `inactive` → `inactivated_at` という流れが論理的

## 実装計画

### フェーズ1: 基盤整備（このPRの範囲）

#### 1. データベース変更
```ruby
# db/migrate/[timestamp]_add_inactivated_at_to_dojos.rb
class AddInactivatedAtToDojos < ActiveRecord::Migration[7.0]
  def change
    add_column :dojos, :inactivated_at, :datetime, default: nil
    add_index :dojos, :inactivated_at
  end
end

# db/migrate/[timestamp]_change_note_to_text_in_dojos.rb
class ChangeNoteToTextInDojos < ActiveRecord::Migration[7.0]
  def up
    change_column :dojos, :note, :text, null: false, default: ""
  end
  
  def down
    # 255文字を超えるデータがある場合は警告
    long_notes = Dojo.where("LENGTH(note) > 255").pluck(:id, :name)
    if long_notes.any?
      raise ActiveRecord::IrreversibleMigration, 
        "Cannot revert: These dojos have notes longer than 255 chars: #{long_notes}"
    end
    
    change_column :dojos, :note, :string, null: false, default: ""
  end
end
```

**デフォルト値について**
- `inactivated_at` のデフォルト値は `NULL`
- アクティブなDojoは `inactivated_at = NULL`
- 非アクティブになった時点で日時を設定

#### 2. Dojoモデルの更新
```ruby
# app/models/dojo.rb に追加
class Dojo < ApplicationRecord
  # 既存のスコープを維持（後方互換性のため）
  scope :active,   -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  
  # 新しいスコープを追加
  scope :active_at, ->(date) { 
    where('created_at <= ?', date)
      .where('inactivated_at IS NULL OR inactivated_at > ?', date) 
  }
  
  # ヘルパーメソッド
  def active_at?(date)
    created_at <= date && (inactivated_at.nil? || inactivated_at > date)
  end
  
  def active?
    inactivated_at.nil?
  end
  
  # 再活性化メソッド
  def reactivate!
    if inactivated_at.present?
      # 非活動期間を note に記録
      inactive_period = "#{inactivated_at.strftime('%Y-%m-%d')}〜#{Date.today}"
      
      if note.present?
        self.note += "\n非活動期間: #{inactive_period}"
      else
        self.note = "非活動期間: #{inactive_period}"
      end
    end
    
    update!(
      is_active: true,
      inactivated_at: nil
    )
  end
  
  # is_activeとinactivated_atの同期（移行期間中）
  before_save :sync_active_status
  
  private
  
  def sync_active_status
    if is_active_changed?
      if is_active == false && inactivated_at.nil?
        self.inactivated_at = Time.current
      elsif is_active == true && inactivated_at.present?
        # is_activeがtrueに変更された場合、noteに履歴を残す処理を検討
        # ただし、before_saveではnoteの変更が難しいため、明示的なreactivate!の使用を推奨
      end
    end
  end
end
```

#### 3. YAMLファイルの更新サポート
```ruby
# lib/tasks/dojos.rake の更新
task update_db_by_yaml: :environment do
  dojos.each do |dojo|
    d = Dojo.find_or_initialize_by(id: dojo['id'])
    # ... 既存のフィールド設定 ...
    d.inactivated_at = dojo['inactivated_at'] if dojo['inactivated_at'].present?
    # ... 
  end
end
```

### フェーズ2: データ移行

#### 重要: YAMLファイルがマスターデータ

**db/dojos.yaml がマスターレコードであることに注意**:
- データベースの変更だけでは不十分
- `rails dojos:update_db_by_yaml` 実行時にYAMLの内容でDBが上書きされる
- 永続化にはYAMLファイルへの反映が必須

**データ更新の正しいフロー**:
1. Git履歴から日付を抽出
2. **YAMLファイルに `inactivated_at` を追加**
3. `rails dojos:update_db_by_yaml` でDBに反映
4. `rails dojos:migrate_adding_id_to_yaml` で整合性確認

#### 1. Git履歴からの日付抽出とYAML更新スクリプト

参考実装: https://github.com/remote-jp/remote-in-japan/blob/main/docs/upsert_data_by_readme.rb#L28-L44

```ruby
# lib/tasks/dojos.rake に追加
desc 'Git履歴からinactivated_at日付を抽出してYAMLファイルに反映'
task extract_inactivated_at_from_git: :environment do
  require 'git'
  
  yaml_path = Rails.root.join('db', 'dojos.yaml')
  git = Git.open(Rails.root)
  
  # YAMLファイルの内容を行番号付きで読み込む
  yaml_lines = File.readlines(yaml_path)
  
  inactive_dojos = Dojo.inactive.where(inactivated_at: nil)
  
  inactive_dojos.each do |dojo|
    puts "Processing: #{dojo.name} (ID: #{dojo.id})"
    
    # is_active: false が記載されている行を探す
    target_line_number = nil
    in_dojo_block = false
    
    yaml_lines.each_with_index do |line, index|
      # Dojoブロックの開始を検出
      if line.match?(/^- id: #{dojo.id}$/)
        in_dojo_block = true
      elsif line.match?(/^- id: \d+$/)
        in_dojo_block = false
      end
      
      # 該当Dojoブロック内で is_active: false を見つける
      if in_dojo_block && line.match?(/^\s*is_active: false/)
        target_line_number = index + 1  # git blameは1-indexedなので+1
        break
      end
    end
    
    if target_line_number
      # git blame を使って該当行の最新コミット情報を取得
      # --porcelain で解析しやすい形式で出力
      blame_cmd = "git blame #{yaml_path} -L #{target_line_number},+1 --porcelain"
      blame_output = `#{blame_cmd}`.strip
      
      # コミットIDを抽出（最初の行の最初の要素）
      commit_id = blame_output.lines[0].split.first
      
      if commit_id && commit_id.match?(/^[0-9a-f]{40}$/)
        # コミット情報を取得
        commit = git.gcommit(commit_id)
        inactivated_date = commit.author_date
        
        # YAMLファイルのDojoブロックを見つけて更新
        yaml_updated = false
        yaml_lines.each_with_index do |line, index|
          if line.match?(/^- id: #{dojo.id}$/)
            # 該当Dojoブロックの最後に inactivated_at を追加
            insert_index = index + 1
            while insert_index < yaml_lines.length && !yaml_lines[insert_index].match?(/^- id:/)
              insert_index += 1
            end
            
            # inactivated_at 行を挿入
            yaml_lines.insert(insert_index - 1, 
              "  inactivated_at: #{inactivated_date.strftime('%Y-%m-%d %H:%M:%S')}\n")
            yaml_updated = true
            break
          end
        end
        
        if yaml_updated
          # YAMLファイルを書き戻す
          File.write(yaml_path, yaml_lines.join)
          puts "  ✓ Updated YAML: inactivated_at = #{inactivated_date.strftime('%Y-%m-%d %H:%M:%S')}"
          puts "  Commit: #{commit_id[0..7]} by #{commit.author.name}"
        else
          puts "  ✗ Failed to update YAML file"
        end
      else
        puts "  ✗ Could not find commit information"
      end
    else
      puts "  ✗ Could not find 'is_active: false' line in YAML"
    end
  end
  
  puts "\nSummary:"
  puts "Total inactive dojos: #{inactive_dojos.count}"
  puts "YAML file has been updated with inactivated_at dates"
  puts "\nNext steps:"
  puts "1. Review the changes in db/dojos.yaml"
  puts "2. Run: rails dojos:update_db_by_yaml"
  puts "3. Commit the updated YAML file"
end

# 特定のDojoのみを処理するバージョン
desc 'Git履歴から特定のDojoのinactivated_at日付を抽出'
task :extract_inactivated_at_for_dojo, [:dojo_id] => :environment do |t, args|
  dojo = Dojo.find(args[:dojo_id])
  # 上記と同じロジックで単一のDojoを処理
end
```

#### 2. 手動での日付設定用CSVサポート
```ruby
# lib/tasks/dojos.rake に追加
desc 'CSVファイルからinactivated_at日付を設定'
task :set_inactivated_at_from_csv, [:csv_path] => :environment do |t, args|
  CSV.foreach(args[:csv_path], headers: true) do |row|
    dojo = Dojo.find_by(id: row['dojo_id'])
    next unless dojo
    
    dojo.update!(inactivated_at: row['inactivated_at'])
    puts "Updated #{dojo.name}: inactivated_at = #{row['inactivated_at']}"
  end
end
```

### 再活性化（Reactivation）の扱い

#### 基本方針
- Dojoが再活性化する場合は `inactivated_at` を NULL に戻す
- 過去の非活動期間は `note` カラムに記録する（自由形式）
- 将来的に履歴管理が必要になったら、その時点で専用の仕組みを検討

#### 実装例

##### 1. Rakeタスクでの再活性化
```ruby
# lib/tasks/dojos.rake
desc 'Dojoを再活性化する'
task :reactivate_dojo, [:dojo_id] => :environment do |t, args|
  dojo = Dojo.find(args[:dojo_id])
  
  if dojo.inactivated_at.present?
    inactive_period = "#{dojo.inactivated_at.strftime('%Y-%m-%d')}〜#{Date.today}"
    puts "再活性化: #{dojo.name}"
    puts "非活動期間: #{inactive_period}"
    
    dojo.reactivate!
    puts "✓ 完了しました"
  else
    puts "#{dojo.name} は既に活動中です"
  end
end
```

##### 2. noteカラムでの記録例（自由形式）
```
# シンプルな記述
"非活動期間: 2019-03-15〜2022-06-01"

# 複数回の記録
"非活動期間: 2019-03-15〜2022-06-01, 2024-01-01〜2024-03-01"

# より詳細な記録
"2019年3月から2022年6月まで運営者の都合により休止。2024年1月は会場の都合で一時休止。"

# 既存のnoteとの混在
"毎月第2土曜日開催。※非活動期間: 2019-03-15〜2022-06-01"
```

#### YAMLファイルでの扱い
```yaml
# 再活性化したDojo
- id: 104
  name: 札幌東
  is_active: true
  # inactivated_at は記載しない（NULLになる）
  note: "非活動期間: 2019-03-15〜2022-06-01"
```

### フェーズ3: 統計ロジックの更新

#### 1. Statモデルの更新
```ruby
# app/models/stat.rb
class Stat
  def annual_sum_total_of_dojo_at_year(year)
    # 特定の年にアクティブだったDojoの数を集計
    end_of_year = Time.zone.local(year).end_of_year
    Dojo.active_at(end_of_year).sum(:counter)
  end
  
  def annual_dojos_chart(lang = 'ja')
    # 変更前: Dojo.active のみを集計
    # 変更後: 各年末時点でアクティブだったDojo数を集計
    data = {}
    (@period.first.year..@period.last.year).each do |year|
      data[year.to_s] = annual_sum_total_of_dojo_at_year(year)
    end
    
    HighChartsBuilder.build_annual_dojos(data, lang)
  end
  
  # 統計値の変化の例
  # 2018年: 旧) 180道場 → 新) 220道場（2019年に非アクティブになった40道場を含む）
  # 2019年: 旧) 200道場 → 新) 220道場（その年に非アクティブになった道場も年末まで含む）
  # 2020年: 旧) 210道場 → 新) 210道場（2020年以降の非アクティブ化は影響なし）
end
```

#### 2. 集計クエリの最適化
```ruby
# 年ごとのアクティブDojo数の効率的な集計
def self.aggregatable_annual_count_with_inactive(period)
  sql = <<-SQL
    WITH yearly_counts AS (
      SELECT 
        EXTRACT(YEAR FROM generate_series(
          :start_date::date,
          :end_date::date,
          '1 year'::interval
        )) AS year,
        COUNT(DISTINCT dojos.id) AS dojo_count
      FROM dojos
      WHERE dojos.created_at <= generate_series
        AND (dojos.inactivated_at IS NULL OR dojos.inactivated_at > generate_series)
      GROUP BY year
    )
    SELECT year::text, dojo_count
    FROM yearly_counts
    ORDER BY year
  SQL
  
  result = connection.execute(
    sanitize_sql([sql, { start_date: period.first, end_date: period.last }])
  )
  
  Hash[result.values]
end
```

### フェーズ4: 将来の移行計画

#### is_active カラムの廃止準備
1. すべてのコードで `inactivated_at` ベースのロジックに移行
2. 既存のAPIとの互換性維持層を実装
3. 十分なテスト期間を経て `is_active` カラムを削除

```ruby
# 移行期間中の互換性レイヤー
class Dojo < ApplicationRecord
  # is_activeの仮想属性化
  def is_active
    inactivated_at.nil?
  end
  
  def is_active=(value)
    self.inactivated_at = value ? nil : Time.current
  end
end
```

## テスト計画

### 1. モデルテスト
- `inactivated_at` の自動設定のテスト
- `active_at?` メソッドのテスト
- `active?` メソッドのテスト
- スコープのテスト
- `reactivate!` メソッドのテスト

### 2. 統計テスト
- 過去の特定時点でのDojo数が正しく集計されるか
- 非アクティブ化されたDojoが適切に統計に含まれるか

### 3. マイグレーションテスト
- 既存データの移行が正しく行われるか
- Git履歴からの日付抽出が機能するか
- noteカラムの型変更が正しく行われるか

### 4. 再活性化テスト
- 再活性化時にnoteに履歴が記録されるか
- 複数回の再活性化が正しく記録されるか

## 実装の優先順位

1. **高優先度**
   - データベースマイグレーション（`inactivated_at` カラム追加）
   - noteカラムの型変更（string → text）
   - Dojoモデルの基本的な更新
   - YAMLファイルサポート

2. **中優先度**
   - Git履歴からの日付抽出
   - 再活性化機能の実装
   - 統計ロジックの更新
   - テストの実装

3. **低優先度**
   - is_activeカラムの廃止準備
   - パフォーマンス最適化
   - 活動履歴の完全追跡機能（将来の拡張）

## リスクと対策

### リスク
1. Git履歴から正確な日付を抽出できない可能性
2. 大量のデータ更新によるパフォーマンスへの影響
3. 既存の統計データとの不整合

### 対策
1. 手動での日付設定用のインターフェース提供
2. バッチ処理での段階的な更新
3. 移行前後での統計値の比較検証

## 成功の指標

- すべての非アクティブDojoに `inactivated_at` が設定される
- 統計グラフで過去の活動履歴が正確に表示される
- 道場数の推移グラフが過去のデータも含めて正確に表示される
- 既存の機能に影響を与えない
- パフォーマンスの劣化がない

### 統計グラフの変化の検証方法
1. 実装前に現在の各年の道場数を記録
2. `inactivated_at` 実装後の各年の道場数と比較
3. 増加した数が非アクティブDojoの活動期間と一致することを確認
4. 特に2016-2020年あたりで大きな変化が見られることを確認（多くのDojoがこの期間に非アクティブ化）

## Git履歴抽出の技術的詳細

### git blame を使用する理由
- `git log` より高速で正確
- 特定の行がいつ変更されたかを直接特定可能
- `--porcelain` オプションで機械的に解析しやすい出力形式

### 実装上の注意点
1. **YAMLの構造を正確に解析**
   - 各Dojoはハイフンで始まるブロック
   - インデントに注意（is_activeは通常2スペース）

2. **エッジケース**
   - `is_active: false` が複数回変更された場合は最初の変更を取得
   - YAMLファイルが大幅に再構成された場合の対処

3. **必要なGem**
   ```ruby
   # Gemfile
   gem 'git', '~> 1.18'  # Git操作用
   ```

## 実装スケジュール案

### Phase 1（1週目）- 基盤整備 ✅ 完了
- [x] `inactivated_at` カラム追加のマイグレーション作成
- [x] `note` カラムの型変更マイグレーション作成
- [x] Dojoモデルの基本的な変更（スコープ、メソッド追加）
- [x] 再活性化機能（`reactivate!`）の実装
- [x] モデルテストの作成

### Phase 2（2週目）- データ移行準備（YAML対応版）🔄 進行中
- [x] Git履歴からYAMLへの inactivated_at 抽出スクリプトの実装（参考実装作成済み）
- [ ] YAMLファイルの更新（ドライラン）
- [ ] dojos:update_db_by_yaml タスクの inactivated_at 対応（実装方法確定済み）
- [ ] 手動調整が必要なケースの特定
- [ ] YAMLファイルのレビューとコミット

### Phase 3（3週目）- 統計機能更新
- [ ] Statモデルの更新（`active_at` スコープの活用）
- [ ] 統計ロジックのテスト
- [ ] パフォーマンステスト
- [ ] 本番環境へのデプロイ準備

### Phase 4（4週目）- 本番デプロイ
- [ ] 本番環境でのマイグレーション実行
- [ ] Git履歴からのデータ抽出実行
- [ ] 統計ページの動作確認
- [ ] ドキュメント更新（運用手順書など）

## デバッグ用コマンド

開発中に便利なコマンド：

```bash
# 特定のDojoのis_active履歴を確認
git log -p --follow db/dojos.yaml | grep -B5 -A5 "id: 104"

# YAMLファイルの特定行のblame情報を確認
git blame db/dojos.yaml -L 17,17 --porcelain

# 非アクティブDojoの一覧を取得
rails runner "Dojo.inactive.pluck(:id, :name).each { |id, name| puts \"#{id}: #{name}\" }"

# 現在の統計値を確認（変更前の記録用）
rails runner "
  (2012..2024).each do |year|
    count = Dojo.active.where('created_at <= ?', Time.zone.local(year).end_of_year).sum(:counter)
    puts \"#{year}: #{count} dojos\"
  end
"

# inactivated_at実装後の統計値確認
rails runner "
  (2012..2024).each do |year|
    date = Time.zone.local(year).end_of_year
    count = Dojo.active_at(date).sum(:counter)
    puts \"#{year}: #{count} dojos (with historical data)\"
  end
"
```

## 今後の展望

この実装が完了した後、以下の改善を検討：

### 短期的な改善
- noteカラムから非活動期間を抽出して統計に反映する機能
- 再活性化の頻度分析
- YAMLファイルでの `inactivated_at` の一括管理ツール

### 中長期的な拡張
- 専用の活動履歴テーブル（`dojo_activity_periods`）の実装
- より詳細な活動状態の管理（一時休止、長期休止、統合、分割など）
- 活動状態の変更理由の記録と分類
- 活動期間のビジュアライゼーション（タイムライン表示など）
- 活動再開予定日の管理機能

### 現実的なアプローチ
現時点では `note` カラムを活用したシンプルな実装で十分な機能を提供できる。実際の運用で再活性化のケースが増えてきた時点で、より高度な履歴管理システムへの移行を検討する。