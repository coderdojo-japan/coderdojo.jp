# $ rails statistics:aggregation[from,to,provider,dojo_id]

## 概要

指定期間/プロバイダのイベント履歴を集計する

## 引数

|引数名|型|必須|説明|
|--|--|--|--|
|from|string|(省略可)|集計期間開始年/年月/年月日|
|to|string|(省略可)|集計期間終了年/年月/年月日|
|provider|string|(省略可)|集計対象プロバイダ|
|dojo_id|integer|(省略可)|集計対象 Dojo ID|

## 説明

from/to で指定された期間のイベント履歴を集計する。

provider が指定されたとき、指定プロバイダに対してのみ集計を行う。

dojo_id が指定されたとき、指定 Dojo に対してのみ集計を行う。

+ from, to を共に省略した場合、前週一週間分の履歴を集計する。
+ 全期間(2012年以降前日まで)を集計する場合、from/to 共に '-' を指定する。
```
rails statistics:aggregation[-,-,]
```
+ from/to に期間を指定する場合、それぞれ以下の形式で指定可能。
```
%Y%m%d, %Y/%m/%d, %Y-%m-%d, %Y%m, %Y/%m, %Y-%m, %Y
```
+ to は前日、前日の年月、もしくは前日の年を最大とする。これより未来を指定された場合でも、最大以降は集計対象外とする。

+ from, to いずれかを省略した場合、指定された他方の年/年月/年月日の履歴を集計する。

+ provider には、connpass, doorkeeper, facebook, static_yaml が指定可能。

## 使用例

追加した dojo のみ 2018 年 1 月分から connpass イベントを収集したいときは、期間と dojo_id (仮に xxx とします) を指定して以下のように実行する。
```
bundle exec rails statistics:aggregation[201801,201910,connpass,xxx]
```

それぞれ引数の省略が可能。
例) provider を絞らない場合
```
bundle exec rails statistics:aggregation[201801,201910,,xxx]
```

[`db/static_event_histories.yml`](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/db/static_event_histories.yml) にある YAML データを更新する

```
# 全ての期間を更新する (Zshの場合)
bundle exec rails statistics:aggregation\[-,-,static_yaml\]

# 特定の期間を更新する (Zshの場合)
bundle exec rails statistics:aggregation\[202301,202401,static_yaml\]
```

## 本番環境で実行しているコマンド

統計情報ページの更新: https://coderdojo.jp/stats
```
# Daily at 1:00 AM UTC（毎週１回）
$ [ $(date +%u) = 1 ] && bundle exec rails statistics:aggregation
```

本番で手動実行するときは、リポジトリ内のラッパーを使う。
タスク名と app 名が固定されているため、打ち間違いで別のタスクを本番で実行する余地がない。

```
bin/heroku-stats-aggregation                        # 前週（週次ジョブと同じ）
bin/heroku-stats-aggregation - - static_yaml        # static_yaml のみ全期間
bin/heroku-stats-aggregation 2026-08-17 2026-08-23  # 期間を指定
```

<br>

## ⚠️ 外部プロバイダの再集計は「消えたイベント」を復活させない

集計は「対象期間の履歴を削除してから、API で取り直す」という手順で動く。
そのため **API に今も存在するイベントだけが残り、API から消えたイベントは削除されたまま**になる。

閉鎖した道場が connpass のグループごとページを削除していると、そのイベントは
実際に開催されたのに API には存在しない。古い期間を再集計すると、この履歴が失われる。

このため、**開始日が 90 日より前なら、外部プロバイダの再集計は実行できない**。
実行しようとすると、DB にも API にも触れる前に中止される。

判定は開始日（from）だけを見る。終了日も、期間の長さも見ない。
7 日間の指定でも、開始日が古ければ同じだけ古い履歴を消すため。

- 🚫 `statistics:aggregation[-,-]` — 開始日が 2012-01-01 なので**実行できない**
- 🚫 `statistics:aggregation[2015,2016,connpass]` — 開始日が 2015-01-01 なので**実行できない**
- 🚫 `statistics:aggregation[2013-01-01,2013-01-07]` — 7 日間でも開始日が古いので**実行できない**
- ⭕ `statistics:aggregation[2026-08-17,2026-08-23]` — 開始日が 90 日以内なら実行できる
- ⭕ `statistics:aggregation[-,-,static_yaml]` — static_yaml は
  [`db/static_event_histories.yml`](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/db/static_event_histories.yml)
  が正史なので、何度実行しても同じ結果になる。制限の対象外

中止されると、次のように理由が表示される。

```
2012-01-01 からの再集計を中止しました（90 日より前のため）。

API から消えたイベントは再集計で復活せず、実際に開催された履歴が失われます。
欠損を直したいときは、該当する週だけを指定してください。
例: rails 'statistics:aggregation[2026-08-17,2026-08-23]'
```

制限を外す仕組みは用意していない。
どうしても古い期間を再集計する必要が出たときは、失われる履歴を把握したうえで
`Statistics::Aggregation::REAGGREGATION_LIMIT_DAYS` を変更する PR を出す。
履歴が消える操作には、レビューを挟む価値がある。

なお、この制限は 90 日以内の再集計までは守らない。
API がレート制限や一時的な障害で「エラーではなく空の応答」を返した場合、
削除だけが成立して再登録されない。例外ではないため、トランザクションでも巻き戻らない。
再集計したときは、実行前後で件数を比べて確認する。

```
# 実行前後で /stats.json の total_events を比較する
curl -s https://coderdojo.jp/stats.json | ruby -rjson -e 'puts JSON.parse(STDIN.read)["total_events"]'
```

<br>

## 開催日が変更されたときの挙動

道場がイベントページを作り直さずに開催日だけ変更することがある。
集計は「対象期間に開催されるイベント」しか API から取得しないため、変更の向きで結果が変わる。

|パターン|例|結果|
|--|--|--|
|期間外 → 期間内|6/14 のイベントを 8/23 に変更し、8/17〜23 を集計|**追随する**。既存の履歴が更新される|
|集計済みの週から未来へ|8/20 のイベントを 8/24 に延期|**追随する**。翌週の集計で更新される|
|未集計の週から遠い未来へ|8/20 のイベントを 12/25 に延期|**追随する**。12月の週で記録される|
|**過去へ変更**|8/20 のイベントを 7/10 に変更（7月は集計済み）|**記録されない**（下記）|

最後のパターンだけ、どの週の集計にも入らずにすり抜ける。
7月の集計時点では API 上 8/20 だったので返らず、8月の集計時点では API 上 7/10 なので返らない。
週次集計は前週しか見ないため、7月の週が再集計されることもない。

同じ理由で、次のケースも記録されない。

- **開催後にイベントページを作成した場合** — その週の集計は既に終わっている
- **道場を `db/dojo_event_services.yml` に登録する前のイベント** — 登録前は集計対象外

いずれも、気づいた時点で**該当する週だけ**を手動で再集計すれば復旧できる。
上記の警告のとおり、古い期間や全期間を巻き込んで再集計してはいけない。

```
# 該当する週だけを指定する
bin/heroku-stats-aggregation 2026-07-06 2026-07-12
```

なお、参加者数は**開催週の翌月曜に集計した時点のスナップショット**であり、
その後のキャンセルや実参加人数への修正は反映されない。
逆に、集計後にイベントページが削除された場合は履歴が残り続ける。
統計は「累計でおよそ何回開催され、何人が参加したか」を示すもので、1〜2件の誤差は許容している。

<br>

## 集計が途中で止まったときの復旧

集計が失敗すると Slack に通知が届き、週次ジョブ（GitHub Actions）が失敗する。
通知には期間を指定した再実行コマンドが添えられているので、原因を直してからそれを実行する。

**期間を指定せずに再実行してはいけない。** 引数なしの集計は「実行時点の前週」を対象とするため、
翌週以降に気づいて再実行しても、欠けた週は埋まらない。

過去に起きた障害と対処は [PR #1881](https://github.com/coderdojo-japan/coderdojo.jp/pull/1881) を参照。
イベントページの開催日が変更されたことで `event_id` が衝突し、例外が握り潰されて
「削除だけが確定した状態」で正常終了していた。

<br>

# $ rails upcoming_events:aggregation[provider]

## 概要

近日開催(2ヶ月分)のイベント情報を収集する

## 引数

|引数名|型|必須|説明|
|--|--|--|--|
|provider|string|(省略可)|集計対象プロバイダ|

## 説明

過去(昨日分まで)のイベント情報を削除し、本日から 2 ヶ月後までのイベント情報を収集する。

provider が指定されたとき、指定プロバイダに対してのみ集計を行う。

- provider には `connpass`, `doorkeeper`, `facebook`, `static_yaml` が指定可能。ただし現時点では `facebook` は収集対象外のため処理を skip する。
- `$ bundle exec rails upcoming_events:aggregation\[connpass\]`
- `$ bundle exec rails upcoming_events:aggregation\[doorkeeper\]`
- `$ bundle exec rails upcoming_events:aggregation\[facebook\] # NOT available provider for now due to API.`

## 本番環境で実行しているコマンド

近日開催ページの更新: https://coderdojo.jp/events
```
# Daily at 9:00 PM UTC（毎日１回）
$ bundle exec rails upcoming_events:aggregation
```
