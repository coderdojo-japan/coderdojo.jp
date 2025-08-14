# リファクタリング実装計画: `is_active` → `inactivated_at` 統一

## 📋 概要

Issue #1734 のリファクタリング実装計画書です。`is_active` カラムを削除し、`inactivated_at` カラムに統一することで、データの一貫性と保守性を向上させます。

## 🎯 目標

1. **データ一貫性**: 単一情報源（Single Source of Truth）の実現
2. **履歴追跡**: タイムスタンプによる非アクティブ化時期の記録
3. **命名統一**: `inactive` → `inactivated` への統一
4. **技術的負債の解消**: 重複したロジックの排除

## 🔍 現状分析

### 影響範囲マッピング

```
is_active の参照箇所: 13ファイル
├── モデル層
│   ├── app/models/dojo.rb (スコープ、同期処理、reactivate!)
│   └── spec/models/dojo_spec.rb
├── ビュー層
│   └── app/views/dojos/index.html.erb
├── コントローラー層
│   └── app/controllers/dojos_controller.rb (ソート条件)
├── データ層
│   ├── db/dojos.yaml (YAMLマスターデータ)
│   ├── db/schema.rb
│   └── db/migrate/20180604070534_add_is_active_to_dojos.rb
├── タスク層
│   └── lib/tasks/dojos.rake (line 47)
└── テスト層
    ├── spec/factories/dojos.rb
    ├── spec/requests/dojos_spec.rb
    ├── spec/models/stat_spec.rb
    └── spec/lib/tasks/dojos_spec.rb

inactive-item CSSクラスの使用箇所: 3ファイル
├── app/assets/stylesheets/custom.scss
├── app/views/dojos/index.html.erb
└── app/views/stats/show.html.erb
```

### 技術的詳細

#### 現在の実装パターン

```ruby
# 1. ブール値ベース（削除対象）
scope :active,   -> { where(is_active: true) }
scope :inactive, -> { where(is_active: false) }

# 2. タイムスタンプベース（保持・強化）
scope :active_at, ->(date) { 
  where('created_at <= ?', date)
    .where('inactivated_at IS NULL OR inactivated_at > ?', date) 
}

# 3. 同期処理（削除対象）
before_save :sync_active_status
```

## 📝 実装計画

### 実装戦略: TDD による安全なリファクタリング

1. **検出フェーズ**: エラーを発生させて依存箇所を特定
2. **修正フェーズ**: 特定された箇所を順次修正
3. **移行フェーズ**: 新しい実装に切り替え
4. **削除フェーズ**: 不要なコードとカラムを削除

この戦略により、見落としなく安全にリファクタリングを実施できます。

### Phase 0: 準備作業（30分）

#### 0.1 データ整合性の最終確認
```ruby
# Rails console で実行
dojos_with_mismatch = Dojo.where(
  "(is_active = true AND inactivated_at IS NOT NULL) OR 
   (is_active = false AND inactivated_at IS NULL)"
)
puts "不整合データ: #{dojos_with_mismatch.count}件"
dojos_with_mismatch.each do |dojo|
  puts "ID: #{dojo.id}, Name: #{dojo.name}, is_active: #{dojo.is_active}, inactivated_at: #{dojo.inactivated_at}"
end
```

#### 0.2 バックアップ作成
```bash
# 本番データベースのバックアップ
heroku pg:backups:capture --app coderdojo-japan

# YAMLファイルのバックアップ
cp db/dojos.yaml db/dojos.yaml.backup_$(date +%Y%m%d)
```

#### 0.3 ブランチ作成
```bash
git checkout -b refactor-to-merge-inactive-into-inactivated-columns
```

### Phase 1: テストファースト実装（45分）

#### 1.0 依存箇所の検出（TDDアプローチ）
```ruby
# app/models/dojo.rb
# 一時的にエラーを発生させて、これらのスコープを使用している箇所を検出
scope :active, -> { 
  raise NotImplementedError, 
    "DEPRECATED: Use `where(inactivated_at: nil)` instead of `.active` scope. Called from: #{caller.first}"
}
scope :inactive, -> { 
  raise NotImplementedError,
    "DEPRECATED: Use `where.not(inactivated_at: nil)` instead of `.inactive` scope. Called from: #{caller.first}"
}

# テストを実行して、どこでエラーが発生するか確認
# bundle exec rspec
# これにより、リファクタリングが必要な全ての箇所を特定できる
```

#### 1.1 テストの更新
```ruby
# spec/models/dojo_spec.rb
# is_active 関連のテストを inactivated_at ベースに書き換え

describe 'スコープ' do
  describe '.active' do
    it 'inactivated_atがnilのDojoを返す' do
      active_dojo = create(:dojo, inactivated_at: nil)
      inactive_dojo = create(:dojo, inactivated_at: 1.day.ago)
      
      expect(Dojo.active).to include(active_dojo)
      expect(Dojo.active).not_to include(inactive_dojo)
    end
  end
  
  describe '.inactive' do
    it 'inactivated_atが設定されているDojoを返す' do
      active_dojo = create(:dojo, inactivated_at: nil)
      inactive_dojo = create(:dojo, inactivated_at: 1.day.ago)
      
      expect(Dojo.inactive).not_to include(active_dojo)
      expect(Dojo.inactive).to include(inactive_dojo)
    end
  end
end
```

#### 1.2 Factory の更新
```ruby
# spec/factories/dojos.rb
FactoryBot.define do
  factory :dojo do
    # is_active を削除
    # inactivated_at のみ使用
    
    trait :inactive do
      inactivated_at { 1.month.ago }
    end
  end
end
```

### Phase 2: モデル層のリファクタリング（30分）

#### 2.1 スコープの更新（段階的移行）
```ruby
# app/models/dojo.rb
class Dojo < ApplicationRecord
  # Step 1: エラー検出フェーズ（Phase 1.0で実施）
  # scope :active, -> { raise NotImplementedError, "..." }
  # scope :inactive, -> { raise NotImplementedError, "..." }
  
  # Step 2: 警告フェーズ（オプション）
  # scope :active, -> { 
  #   Rails.logger.warn "DEPRECATED: .active scope will be updated to use inactivated_at"
  #   where(is_active: true)
  # }
  
  # Step 3: 最終的な実装
  scope :active,   -> { where(inactivated_at: nil) }
  scope :inactive, -> { where.not(inactivated_at: nil) }
  
  # active_at スコープはそのまま維持
  scope :active_at, ->(date) { 
    where('created_at <= ?', date)
      .where('inactivated_at IS NULL OR inactivated_at > ?', date) 
  }
  
  # sync_active_status と関連コードを削除
  # before_save :sync_active_status を削除
end
```

#### 2.2 reactivate! メソッドの更新
```ruby
def reactivate!
  if inactivated_at.present?
    inactive_period = "#{inactivated_at.strftime('%Y-%m-%d')}〜#{Date.today}"
    
    if note.present?
      self.note += "\n非活動期間: #{inactive_period}"
    else
      self.note = "非活動期間: #{inactive_period}"
    end
  end
  
  # is_active: true を削除
  update!(inactivated_at: nil)
end
```

### Phase 3: コントローラー層の更新（15分）

#### 3.1 ソート条件の更新
```ruby
# app/controllers/dojos_controller.rb
def index
  @dojos = Dojo.includes(:prefecture)
               .order(Arel.sql('CASE WHEN inactivated_at IS NULL THEN 0 ELSE 1 END'), order: :asc)
               .page(params[:page])
end
```

### Phase 4: Rakeタスクの更新（15分）

#### 4.1 dojos.rake の更新
```ruby
# lib/tasks/dojos.rake
task update_db_by_yaml: :environment do
  dojos = Dojo.load_attributes_from_yaml
  
  dojos.each do |dojo|
    raise_if_invalid_dojo(dojo)
    
    d = Dojo.find_or_initialize_by(id: dojo['id'])
    # ... 他のフィールド設定 ...
    
    # is_active の処理を削除
    # d.is_active = dojo['is_active'].nil? ? true : dojo['is_active']
    
    # inactivated_at のみ処理
    d.inactivated_at = dojo['inactivated_at'] ? Time.zone.parse(dojo['inactivated_at']) : nil
    
    d.save!
  end
end
```

### Phase 5: CSS/ビューの更新（20分）

#### 5.1 CSS クラス名の変更
```scss
// app/assets/stylesheets/custom.scss
// .inactive-item → .inactivated-item
.inactivated-item {
  opacity: 0.6;
  background-color: #f5f5f5;
}
```

#### 5.2 ビューファイルの更新
```erb
<!-- app/views/dojos/index.html.erb -->
<tr class="<%= dojo.inactivated_at.present? ? 'inactivated-item' : '' %>">
  <!-- 内容 -->
</tr>

<!-- app/views/stats/show.html.erb -->
<!-- 同様の変更 -->
```

### Phase 6: マイグレーション実行（15分）

#### 6.1 マイグレーションファイルの作成
```ruby
# db/migrate/XXXXXXXXXX_remove_is_active_from_dojos.rb
class RemoveIsActiveFromDojos < ActiveRecord::Migration[7.2]
  def up
    # 最終的なデータ同期
    execute <<~SQL
      UPDATE dojos 
      SET inactivated_at = CURRENT_TIMESTAMP 
      WHERE is_active = false AND inactivated_at IS NULL
    SQL
    
    execute <<~SQL
      UPDATE dojos 
      SET inactivated_at = NULL 
      WHERE is_active = true AND inactivated_at IS NOT NULL
    SQL
    
    # カラム削除
    remove_column :dojos, :is_active
  end
  
  def down
    add_column :dojos, :is_active, :boolean, default: true, null: false
    add_index :dojos, :is_active
    
    # データ復元
    execute <<~SQL
      UPDATE dojos 
      SET is_active = false 
      WHERE inactivated_at IS NOT NULL
    SQL
  end
end
```

### Phase 7: YAMLデータのクリーンアップ（10分）

#### 7.1 is_active フィールドの削除
```ruby
# スクリプトで一括削除
dojos = YAML.unsafe_load_file('db/dojos.yaml')
dojos.each { |dojo| dojo.delete('is_active') }
File.write('db/dojos.yaml', YAML.dump(dojos))
```

### Phase 8: テスト実行と確認（20分）

#### 8.1 全テストの実行
```bash
bundle exec rspec
```

#### 8.2 手動確認項目
- [ ] `/dojos` ページで非アクティブ道場の表示確認
- [ ] `/stats` ページで統計の正確性確認
- [ ] 道場の再活性化機能の動作確認
- [ ] YAMLからのデータ更新機能の確認

## 🚨 リスク管理

### リスクマトリクス

| リスク | 可能性 | 影響度 | 対策 |
|-------|--------|--------|------|
| データ不整合 | 低 | 高 | 事前のデータ検証、バックアップ |
| パフォーマンス劣化 | 低 | 中 | インデックス既存、クエリ最適化 |
| テスト失敗 | 中 | 低 | テストファースト開発 |
| デプロイ失敗 | 低 | 高 | ステージング環境でのテスト |

### ロールバック計画

```bash
# 1. Git でのロールバック
git revert HEAD

# 2. データベースのロールバック
rails db:rollback

# 3. YAMLファイルの復元
cp db/dojos.yaml.backup_$(date +%Y%m%d) db/dojos.yaml

# 4. Herokuでの緊急ロールバック
heroku rollback --app coderdojo-japan
```

## 📊 成功指標

1. **機能面**
   - 全テストが成功（100%）
   - 既存機能の完全な維持
   - エラーレート 0%

2. **パフォーマンス面**
   - クエリ実行時間の維持または改善
   - ページロード時間の変化なし

3. **コード品質**
   - 重複コードの削除（sync_active_status）
   - 命名の一貫性（100% inactivated）
   - コードカバレッジの維持

## ⏱️ タイムライン

| フェーズ | 推定時間 | 累積時間 |
|---------|----------|----------|
| Phase 0: 準備 | 30分 | 30分 |
| Phase 1: テスト | 45分 | 1時間15分 |
| Phase 2: モデル | 30分 | 1時間45分 |
| Phase 3: コントローラー | 15分 | 2時間 |
| Phase 4: Rake | 15分 | 2時間15分 |
| Phase 5: CSS/View | 20分 | 2時間35分 |
| Phase 6: マイグレーション | 15分 | 2時間50分 |
| Phase 7: YAML | 10分 | 3時間 |
| Phase 8: テスト・確認 | 20分 | 3時間20分 |
| **合計** | **3時間20分** | - |

## 📝 チェックリスト

### 実装前
- [ ] Issue #1734 の内容を完全に理解
- [ ] バックアップの作成
- [ ] ステージング環境の準備

### 実装中
- [ ] テストファースト開発の実践
- [ ] 各フェーズ完了後のテスト実行
- [ ] コミットメッセージの明確化

### 実装後
- [ ] 全テストの成功確認
- [ ] 手動での動作確認
- [ ] パフォーマンス測定
- [ ] ドキュメントの更新

## 🔗 参考資料

- Issue #1734: https://github.com/coderdojo-japan/coderdojo.jp/issues/1734
- PR #1726: `inactivated_at` カラムの追加
- PR #1732: 年次フィルタリング機能の実装
- Rails Guide: [Active Record マイグレーション](https://railsguides.jp/active_record_migrations.html)

## 💡 教訓と改善点

### 得られた洞察
1. **段階的移行の重要性**: sync処理による移行期間の設定は賢明だった
2. **タイムスタンプの価値**: ブール値より履歴情報を持てる
3. **命名の一貫性**: 最初から統一すべきだった

### 今後の改善提案
1. **監視の強化**: 非アクティブ化の自動検知
2. **履歴機能**: 非アクティブ期間の可視化
3. **通知機能**: 長期非アクティブ道場へのフォローアップ

---

**作成日**: 2025年8月14日  
**作成者**: Claude Code with Ultrathinking  
**レビュー状態**: 実装前レビュー待ち