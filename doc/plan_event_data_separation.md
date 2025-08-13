# イベントデータアーキテクチャ設計

## 概要

CoderDojo.jp では、イベントデータを **UpcomingEvents（未来のイベント）** と **EventHistory（過去のイベント）** の2つのテーブルに分離して管理しています。この設計により、パフォーマンスの最適化と統計の正確性を両立しています。

## 🏗️ アーキテクチャ

### データベース構造

```
upcoming_events テーブル     event_histories テーブル
      （未来）                    （過去）
         │                          │
         │  時間の経過により移行     │
         └────────────→─────────────┘
```

### 2つのテーブルの役割

| 項目 | UpcomingEvents | EventHistory |
|------|---------------|--------------|
| **テーブル名** | `upcoming_events` | `event_histories` |
| **対象期間** | 未来のイベント | 過去のイベント |
| **主な用途** | Webサイトの「近日開催」表示 | 統計グラフ・履歴分析 |
| **更新コマンド** | `rails upcoming_events:aggregation` | `rails statistics:aggregation` |
| **更新頻度** | 毎日 21:00 UTC | 毎週月曜 01:00 UTC |
| **データの特性** | 頻繁に変更（キャンセル等） | 確定データ（変更なし） |
| **レコード数** | 少ない（未来のみ） | 多い（全履歴） |

## 🔄 データフロー

### データ収集範囲とタイミング

```ruby
# UpcomingEvents: 1ヶ月前 〜 2ヶ月後
# 例：1月8日実行時
UpcomingEvents収集範囲: 2024/12/09 〜 2025/03/08
削除対象: 2024/12/08以前に終了したイベント

# EventHistory: 指定期間（通常は前週）
# 例：月曜日実行時
EventHistory収集範囲: 前週の月曜 〜 日曜（7日間）
```

### イベントのライフサイクル

```ruby
# 例：1月15日に開催予定のイベント

# 1月1日時点（未来）
UpcomingEvent.create!(
  event_id: 12345,
  event_name: "CoderDojo札幌",
  event_date: "2025-01-15",
  participants_limit: 20
)

# 1月16日（イベント終了後）
# UpcomingEventから削除され、EventHistoryに記録
EventHistory.create!(
  event_id: 12345,
  dojo_name: "CoderDojo札幌",
  evented_at: "2025-01-15",
  participants: 15  # 実際の参加者数
)
```

### キャンセルされたイベントの扱い

```ruby
# 重要：キャンセルされたイベントは統計に含まれない

# 1月10日：大雪で1月15日のイベントがキャンセル
UpcomingEvent.find_by(event_id: 12345).destroy

# 結果：
# - UpcomingEventから削除 ✓
# - EventHistoryには記録されない ✓
# - 統計（/stats）には反映されない ✓
```

## 💡 設計の利点

### 1. 統計の正確性

実際に開催されたイベントのみが `EventHistory` に記録されるため、統計データが正確です。

```ruby
# 統計ページ（/stats）の集計
EventHistory.where(dojo_name: "CoderDojo札幌").count
# => 実際に開催されたイベント数のみ
```

### 2. パフォーマンスの最適化

```ruby
# UpcomingEvents：小さいテーブル
UpcomingEvent.all  # 高速（未来のイベントのみ）

# EventHistory：大きいが変更が少ない
EventHistory.where(year: 2024)  # インデックスで高速化
```

### 3. データの整合性

時間軸で自然に分離されるため、同じイベントが両方のテーブルに存在することがありません。

```ruby
# 重複チェック（常にfalse）
upcoming_ids = UpcomingEvent.pluck(:event_id)
history_ids = EventHistory.pluck(:event_id)
(upcoming_ids & history_ids).any?  # => false
```

### 4. 運用の柔軟性

```ruby
# UpcomingEventsは頻繁に更新可能
rake upcoming_events:aggregation  # 毎日実行してもOK

# EventHistoryは保護されたデータ
rake statistics:aggregation  # 週1回で十分
```

## 🛠️ 実装詳細

### UpcomingEvents の更新処理（実際のコード）

```ruby
# lib/upcoming_events/aggregation.rb
class UpcomingEvents::Aggregation
  def initialize(args)
    # NOTE: 1ヶ月前 〜 2ヶ月後のイベント情報を対象に収集
    today = Time.zone.today
    @from = today - 1.months + 1.day  # 1ヶ月前から
    @to   = today + 2.months          # 2ヶ月後まで
    @provider = args[:provider]
  end

  def run
    puts "UpcomingEvents aggregate"
    with_notifying do
      delete_upcoming_events  # 古いイベントを削除
      execute                 # 新しいイベントを取得
    end
  end

  private

  def delete_upcoming_events
    # 1ヶ月より前に終了したイベントを削除
    UpcomingEvent.until(@from).delete_all
  end
end

# app/models/upcoming_event.rb
class UpcomingEvent < ApplicationRecord
  # untilスコープ: 指定日より前に終了したイベント
  scope :until, ->(date) { where('event_end_at < ?', date.beginning_of_day) }
end
```

#### 削除メカニズムの詳細

1. **1ヶ月分のバッファー期間**
   - 即座に削除せず、1ヶ月前まで保持
   - 例：1月8日実行時、12月8日より前のイベントを削除

2. **event_end_at ベースの判定**
   - イベント終了時刻を基準に削除判定
   - 開始時刻ではない点が重要

3. **delete_all による一括削除**
   - コールバックを実行しない高速削除
   - トランザクション内で安全に実行

### EventHistory の集計処理（実際のコード）

```ruby
# lib/statistics/aggregation.rb
class Statistics::Aggregation
  def initialize(args)
    @from, @to = aggregation_period(args[:from], args[:to])
    @provider  = args[:provider]
    @dojo_id   = args[:dojo_id].to_i if args[:dojo_id].present?
  end

  def run
    puts "Aggregate for #{@from}~#{@to}"
    with_notifying do
      delete_event_histories  # 期間内の既存データを削除
      execute                 # 新しいデータを取得・保存
    end
  end

  private

  def delete_event_histories
    target_period = @from.beginning_of_day..@to.end_of_day
    # 各プロバイダごとに削除処理
    (@externals.keys + @internals.keys).each do |kind|
      "Statistics::Tasks::#{kind.to_s.camelize}".constantize
        .delete_event_histories(target_period, @dojo_id)
    end
  end
end

# lib/statistics/tasks/doorkeeper.rb
class Statistics::Tasks::Doorkeeper
  def run
    @dojos.each do |dojo|
      dojo.dojo_event_services.for(:doorkeeper).each do |service|
        events = @client.fetch_events(group_id: service.group_id)
        
        events.each do |e|
          # 実際に開催されたイベントのみ保存
          next unless e[:group].to_s == service.group_id
          
          EventHistory.create!(
            dojo_id:       dojo.id,
            dojo_name:     dojo.name,
            event_id:      e[:id],
            event_url:     e[:public_url],
            participants:  e[:participants],  # 実際の参加者数
            evented_at:    Time.zone.parse(e[:starts_at])
          )
        end
      end
    end
  end
end
```

## 🔍 トラブルシューティング

### Q: 過去のイベントが統計に表示されない

A: `EventHistory` にデータが存在するか確認：

```bash
# 特定期間のデータを再取得
rails statistics:aggregation[202501,202501,doorkeeper]
```

### Q: 近日開催に表示されるべきイベントが出ない

A: `UpcomingEvents` の更新を確認：

```bash
# 手動で更新
rails upcoming_events:aggregation
```

### Q: 同じイベントが重複して表示される

A: 通常は起こりませんが、確認方法：

```ruby
# Rails console で確認
event_id = 12345
UpcomingEvent.where(event_id: event_id).count  # 0 or 1
EventHistory.where(event_id: event_id).count    # 0 or 1
```

## 📊 実例：2025年1月のDoorkeeper問題

### 問題の発見

```ruby
# SymbolとStringのキー不一致により、Doorkeeperイベントが保存されていなかった
# lib/statistics/tasks/doorkeeper.rb
e['id']  # nil（実際はe[:id]）
```

### 影響範囲の調査

```sql
-- 3ヶ月分のデータが欠損
SELECT COUNT(*) FROM event_histories 
WHERE service_name = 'doorkeeper' 
AND evented_at BETWEEN '2025-05-01' AND '2025-07-31';
-- => 0（本来は71イベント）
```

### 復旧作業

```bash
# 月ごとに慎重に復旧
rails statistics:aggregation[202505,202505,doorkeeper]  # 24イベント復旧
rails statistics:aggregation[202506,202506,doorkeeper]  # 26イベント復旧
rails statistics:aggregation[202507,202507,doorkeeper]  # 21イベント復旧
```

### 重要な発見

- `UpcomingEvents` は影響なし（別の処理系統）
- `EventHistory` のみ影響（統計データ）
- この分離設計により、影響範囲が限定的だった

## 🎯 まとめ

この2テーブル設計により：

1. **正確な統計** - 実際に開催されたイベントのみカウント
2. **高いパフォーマンス** - 用途に応じた最適化
3. **データの一貫性** - 時間軸での自然な分離
4. **保守性** - 明確な責任分離

という利点を実現しています。