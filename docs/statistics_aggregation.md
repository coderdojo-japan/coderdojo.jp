# rake statistics:aggregation[from,to,provider,dojo_id]

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
rake statistics:aggregation[-,-,]
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

## 本番環境で実行しているコマンド

統計情報ページの更新: https://coderdojo.jp/stats
```
# Daily at 1:00 AM UTC（毎週１回）
$ [ $(date +%u) = 1 ] && bundle exec rails statistics:aggregation
```

近日開催ページの更新: https://coderdojo.jp/events
```
# Daily at 9:00 PM UTC（毎日１回）
$ bundle exec rails upcoming_events:aggregation
```
