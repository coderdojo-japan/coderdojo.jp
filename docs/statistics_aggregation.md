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
