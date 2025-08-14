# 超シンプル！`is_active` カラム削除計画

## 📋 一言で言うと

**スコープの内部実装だけを変更して、`is_active` カラムを安全に削除する**

## 🎯 たった1つの重要な洞察

```
既存コード: Dojo.active, dojo.active? を使っている
    ↓
気づき: スコープ名を変えなければ、既存コードは変更不要！
    ↓
解決策: 内部実装だけ is_active → inactivated_at に変更
```

**結果**: 99%のコードは触らずに済む！


## 📝 実装計画

### 🚀 KISS/YAGNI による究極のシンプル実装

#### Ultrathinking による洞察

**問題の本質**: `is_active` と `inactivated_at` の重複を解消したい

**解決策**: スコープの内部実装だけを変更すれば、99%のコードは変更不要！

### 必要な変更は「たった7箇所」だけ！

```ruby
# 1. Dojoモデル: スコープ内部実装（2行変更）
scope :active,   -> { where(inactivated_at: nil) }           # is_active: true → inactivated_at: nil
scope :inactive, -> { where.not(inactivated_at: nil) }       # is_active: false → inactivated_at NOT nil

# 2. Dojoモデル: active?メソッド（1行変更）
def active?
  inactivated_at.nil?  # is_active → inactivated_at.nil?
end

# 3. Dojoモデル: sync_active_status削除（削除のみ）
# before_save :sync_active_status を削除

# 4. Dojoモデル: reactivate!メソッド（1行削除）
update!(inactivated_at: nil)  # is_active: true を削除

# 5. コントローラー: ソート条件（1行変更）
.order(Arel.sql('CASE WHEN inactivated_at IS NULL THEN 0 ELSE 1 END'), order: :asc)

# 6. Rakeタスク: YAMLからの読み込み（1行削除）
# d.is_active = ... この行を削除

# 7. マイグレーション: カラム削除（最後に実行）
remove_column :dojos, :is_active
```

**変更不要なもの:**
- ✅ ビュー: 全て変更不要（`.active`スコープがそのまま動く）
- ✅ 大部分のテスト: 変更不要（インターフェースが同じ）
- ✅ CSSクラス名: 変更不要（`inactive-item`のままでOK）
- ✅ その他のコントローラー: 変更不要

### 実装時間: 30分で完了可能！

この戦略により、最小限の変更で最大の効果を実現します。

### 実装は3つのシンプルなステップで完了！

## Step 1: データ確認（5分）

```ruby
# Rails console で不整合データがないか確認
Dojo.where("(is_active = true AND inactivated_at IS NOT NULL) OR (is_active = false AND inactivated_at IS NULL)").count
# => 0 なら問題なし！
```

## Step 2: コード変更（10分）

7箇所の変更を実施：

```ruby
# 1. app/models/dojo.rb - スコープ（2行）
scope :active,   -> { where(inactivated_at: nil) }
scope :inactive, -> { where.not(inactivated_at: nil) }

# 2. app/models/dojo.rb - active?メソッド（既に実装済み！そのまま使える）
# def active?
#   inactivated_at.nil?  # これは既にPR #1726で実装済み！
# end

# 3. app/models/dojo.rb - sync_active_status削除
# before_save :sync_active_status と private メソッドを削除

# 4. app/models/dojo.rb - reactivate!メソッド
# is_active: true の行を削除

# 5. app/controllers/dojos_controller.rb - ソート
.order(Arel.sql('CASE WHEN inactivated_at IS NULL THEN 0 ELSE 1 END'), order: :asc)

# 6. lib/tasks/dojos.rake - is_active設定行を削除
# d.is_active = ... の行を削除
```

## Step 3: マイグレーションとテスト（15分）

```ruby
# マイグレーション作成
rails generate migration RemoveIsActiveFromDojos

# マイグレーション内容（シンプル版）
def change
  remove_column :dojos, :is_active, :boolean
end

# テスト実行
bundle exec rspec

# デプロイ
git push && rails db:migrate
```

**完了！** 🎉

## 🎯 なぜこのアプローチが優れているか

### KISS/YAGNI原則の実践
- **変更箇所**: わずか7箇所（実質6箇所、1つは既に実装済み）
- **実装時間**: 30分以内
- **リスク**: 最小限（インターフェースを変えないため）
- **ロールバック**: 簡単（スコープ内部を戻すだけ）

### Ultrathinking による洞察
```
表面的理解: is_activeカラムを削除したい
    ↓
深層的理解: でも既存コードを全部変更するのは大変
    ↓
本質的洞察: スコープ名を維持すれば変更は最小限
    ↓
究極の解決: 内部実装だけ変えれば99%のコードは触らなくて済む！
```

## 📝 実装チェックリスト

- [ ] Step 1: データ整合性確認（Rails console）
- [ ] Step 2: 7箇所のコード変更
  - [ ] Dojoモデル: スコープ内部実装（2行）
  - [ ] Dojoモデル: sync_active_status削除
  - [ ] Dojoモデル: reactivate!メソッド修正
  - [ ] コントローラー: ソート条件変更
  - [ ] Rakeタスク: is_active行削除
- [ ] Step 3: マイグレーション作成と実行
- [ ] テスト実行と確認

## 🔗 参考

- Issue #1734: リファクタリング要件
- PR #1726: `inactivated_at` カラムの追加（active?メソッド実装済み）
- PR #1732: 年次フィルタリング機能

---

**作成日**: 2025年8月14日  
**作成者**: Claude Code with Ultrathinking  
**レビュー状態**: 実装前レビュー待ち