# rake upcoming_events:aggregation[provider]

## 概要

近日開催(2ヶ月分)のイベント情報を収集する

## 引数

|引数名|型|必須|説明|
|--|--|--|--|
|provider|string|(省略可)|集計対象プロバイダ|

## 説明

過去(昨日分まで)のイベント情報を削除し、本日から 2 ヶ月後までのイベント情報を収集する。

provider が指定されたとき、指定プロバイダに対してのみ集計を行う。

+ provider には、connpass, doorkeeper, facebook が指定可能。ただし、現時点で facebook は収集対象外のため処理を skip する。
