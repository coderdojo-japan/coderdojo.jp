# Global Club ID Design

## 概要

このドキュメントは、Raspberry Pi Foundation が管理する国際的な Clubs API データベースと CoderDojo Japan のデータベースを連携させる機能の設計と実装について記載しています。

## 背景

### 現状の課題
- 新しい Dojo が追加されるたびに、DojoMap に表示させるために手動で CSV を更新する必要がある
- この手動作業は時間がかかり、エラーが発生しやすい

### 解決策
Global Clubs データベースの ID（`global_club_id`）を CoderDojo Japan の Dojo と紐付けることで、データの同期を自動化する。

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
- 認証: Bearer token (OAuth flow)
- レート制限: 60 req/min

### データモデル

#### Dojo モデルの拡張
```ruby
# マイグレーション
add_column :dojos, :global_club_id, :bigint
add_index :dojos, :global_club_id, unique: true, where: 'global_club_id IS NOT NULL'
```

#### 同期管理テーブル
```ruby
create_table :global_club_syncs do |t|
  t.bigint :global_club_id, null: false
  t.datetime :last_seen_at
  t.string :sync_status
  t.timestamps
end
```

### 同期戦略

#### 増分同期
- `updatedAt` フィールドを使用して、前回の同期以降に更新されたクラブのみを取得
- 全データを毎回取得するのではなく、効率的な差分更新を実現
- 冪等性を保証（同じ操作を複数回実行しても結果が同じ）

#### マッチングアルゴリズム
1. `global_club_id` で既存の Dojo を検索
2. 見つからない場合は、名前の類似度 + 地理的距離（1km 以内）で自動マッチング
3. 曖昧な場合は手動レビューキューに追加

## 実装計画

### フェーズ 1: 基盤整備
1. データベーススキーマの更新（`global_club_id` カラム追加）
2. YAML ファイルの構造更新
3. モデルのバリデーション追加

### フェーズ 2: API 統合
1. `GlobalClubs::Client` クラスの実装
2. GraphQL クエリの実装
3. 認証設定（Rails credentials）

### フェーズ 3: 同期機能
1. `GlobalClubs::SyncService` の実装
2. マッチングロジックの実装
3. エラーハンドリングとリトライ機構

### フェーズ 4: 運用
1. 定期実行ジョブの設定
2. 監視とアラートの実装
3. 手動レビュー機能（将来的に）

## セキュリティ考慮事項

- Bearer token は Rails credentials に保存
- API 通信は HTTPS のみ
- レート制限に対応（指数バックオフでリトライ）

## 運用上の注意点

### データの整合性
- ソフトデリート: Global Clubs API から削除されたクラブは `global_club_id = nil` に設定（Dojo レコードは削除しない）
- 重複チェック: ユニーク制約により、同じ `global_club_id` を持つ複数の Dojo は作成できない

### エラー処理
- ネットワークエラー: 自動リトライ（最大 3 回）
- API エラー: エラーログに記録し、次回の同期で再試行
- マッチング失敗: 手動レビューキューに追加

## 今後の拡張可能性

- DojoMap との直接連携
- リアルタイム同期（Webhook 対応）
- 他の組織のクラブとの連携

## 更新履歴

- 2025-01-20: 初版作成（設計決定まで確定、技術仕様以降は暫定版）
