# Global Club ID Design

## 概要

このドキュメントは、Raspberry Pi Foundation が管理する国際的な Clubs DB と CoderDojo Japan の Japan DB を連携させる機能の設計と実装について記載しています。

## 背景

### 現状

- Clubs DB（Global Clubs）と Japan DB（CoderDojo Japan）が独立している
- 両者を紐付ける ID がない

### 解決策
Clubs DB の ID（`global_club_id`）を Japan DB の Dojo と紐付ける。

## 設計決定

### 1. 命名規則

#### `global_club_id` を選択した理由
- `club_id` では `dojo_id` との違いが不明瞭
- `global_` プレフィックスにより、外部システムの ID であることが明確
- 将来的に状況が変わっても、名前を変更する必要がない
  - 想定ケース: CoderDojo Foundation (Zen API) -> Raspberry Pi Foundation (Clubs API) -> ??? (FooBar API)

#### `GlobalClubs` モジュール名を選択した理由
- 現在は Raspberry Pi Foundation が管理しているが、過去には CoderDojo Foundation (Zen) が管理していた
- 将来的に同じような変更が行われる可能性を考慮 (想定例: GraphQL の廃止、REST API への回帰、など)
- 実装は現在の API（Raspberry Pi）に直接接続するが、命名は抽象的に保つ

### 2. 実装方針

#### YAGNI 原則の適用
当初はアダプターパターンを検討したが、以下の理由でシンプルな実装を選択：
- API プロバイダーの変更は頻繁には起こらない（もしくは永遠に起こらない）
- 過度な抽象化は開発速度を低下させる
- 必要になったときにリファクタリングすればよい

#### API メソッドの命名
```ruby
def fetch_global_clubs(organization_slug: 'coderdojo', after: nil)
```
- `fetch_coderdojo_clubs` ではなく `fetch_global_clubs` を選択
- API は CoderDojo 以外の組織のクラブも返すため、より正確な命名
- `organization_slug` パラメータでフィルタリング可能

## 技術仕様

> **⚠️ 注意**: この節以降の内容は実装過程で変更される可能性があります。実際の実装とレビューを経て確定します。（2025-01-20時点）

### API エンドポイント
- GraphQL: `https://clubs-api.raspberrypi.org/graphql`
- 認証: 不要（読み取り専用）
- レート制限: 60 req/min

### データモデル

#### Dojo モデルの拡張
```ruby
# マイグレーション（必要なのはこれだけ！）
# UUID 文字列（例: "18704b53-1042-4464-9d49-8820c6ff8c97"）
add_column :dojos, :global_club_id, :string, null: false
add_index :dojos, :global_club_id, unique: true
```

### マッピング戦略

#### 初期マッピング（一度だけ実行）
1. Clubs DB から全 CoderDojo を取得
2. 既存の Dojo と手動で照合：
   - 名前は異なることが前提（Clubs DB は英語、Japan DB は日本語）
   - Japan DB には位置情報がないため、地理的照合は不可
3. 人間が判断して `global_club_id` を設定

**重要な仕様理解**:
- **名前の違いは正常**: Clubs DB（英語話者向け）と Japan DB（日本語話者向け）で名前が異なるのは仕様
- **位置情報**: Japan DB にはなく、Clubs DB のみに存在
- **用途例**: DojoMap アプリで global_club_id を使って英語名→日本語名の変換を行う

## 実装タスク（Issue #1616 より）

1. **Dojo モデルに `global_club_id` カラムを追加**
   ```ruby
   class AddGlobalClubIdToDojos < ActiveRecord::Migration[8.0]
     def change
       # UUID 文字列（例: "18704b53-1042-4464-9d49-8820c6ff8c97"）
       add_column :dojos, :global_club_id, :string, null: false
       add_index :dojos, :global_club_id, unique: true
     end
   end
   ```

2. **db/dojos.yml の全 Dojo に `global_club_id` を追加**

3. **Clubs DB と Dojo ID を紐付ける仕組みを作成**





## セキュリティ考慮事項

- HTTPS 通信（読み取り専用 API）

## 運用上の注意点

### データの整合性
- **ユニーク制約**: 同じ `global_club_id` を持つ複数の Dojo は作成できない
- **NOT NULL 制約**: すべての Dojo に `global_club_id` が必須
- **修正方法**: db/dojos.yml を編集して DB に反映（通常の運用通り）


## 成功指標

1. **global_club_id カラムの追加完了**
2. **既存 Dojo への ID 設定完了**
3. **DojoMap への自動反映の実現**（Issue #1616 の目的）

## シンプルなワークフロー

### 新規 Dojo 追加時（申請フォームで対応）

```
1. 申請時に Clubs DB での登録状況を確認してもらう
2. global_club_id を申請フォームに記入（必須）
3. db/dojos.yml に global_club_id 付きで追加
```

### 初期マッピング（一度だけ実行するスクリプト）

```ruby
# scripts/map_global_clubs.rb
# 既存の全 Dojo に global_club_id を設定

clubs = GlobalClubs.fetch_all_coderdojo_clubs  # 読み取り専用 API
dojos = Dojo.active

puts "Clubs DB: #{clubs.count} clubs"
puts "Japan DB: #{dojos.count} dojos"
puts ""
puts "Manual mapping needed:"
puts "Clubs DB (English)         | Japan DB (Japanese)"
puts "---------------------------|--------------------"

clubs.each do |club|
  # club.id は UUID 文字列（例: "18704b53-1042-4464-9d49-8820c6ff8c97"）
  puts "#{club.name.ljust(26)} | ???"
end

# 手動で db/dojos.yml に global_club_id を追加
# 例: global_club_id: "18704b53-1042-4464-9d49-8820c6ff8c97"
```



## 更新履歴

- 2025-01-20: 初版作成（設計決定まで確定、技術仕様以降は暫定版）
- 2025-08-18: YAGNI原則に基づく大幅簡素化
  - 不要なカラム削除（confidence, last_sync）
  - 継続的同期を削除（一度きりのマッピングに変更）
  - 複雑な監視・測定機能を削除
  - シンプルなワークフローに変更
  - CoderDojo運用の実態に合わせた現実的な設計に修正

## 実装チェックリスト

### 必要最小限の実装
- [ ] `global_club_id` カラムの追加（string型、NOT NULL、UUID）
- [ ] 読み取り専用の Clubs API クライアント実装
- [ ] 既存 Dojo への一括マッピングスクリプト
- [ ] 申請フォームに global_club_id 入力欄追加（必須）

### やらないこと（YAGNI）
- ❌ APIトークン管理（読み取り専用なので不要）
- ❌ 継続的な同期処理
- ❌ null を許可（全 Dojo に必須）
- ❌ 複雑な監視ダッシュボード
- ❌ 自動マッチング（手動で確実に設定）
