# はじめに

**「一時休止したい」** や **「廃止したい」** という要望が出てきた。
もともと休止などの情報は zen.coderdojo.com 側に持っているので coderdojo.jp の情報と連携させたい。という事になった。

 _以降、 zen.coderdojo.com を zen, coderdojo.jp を jp と記します。_ 

zen では WebAPI を公開しているので、その調査内容と連携の考察について記します。

## 関連リンク
- [非アクティブな Dojo を非表示にする仕組みが欲しい
](https://github.com/coderdojo-japan/coderdojo.jp/issues/310
)
- [CoderDojo 西成を非表示にしたい](https://github.com/coderdojo-japan/coderdojo.jp/issues/314)
- [zen.coderdojo.com とその API の調査](https://github.com/coderdojo-japan/coderdojo.jp/issues/330)


# できること

https://zen.coderdojo.com/documentation がAPIのドキュメントなので、ここにあることはできる。

## API の実際のアクセス例

https://zen.coderdojo.com/documentation#!/api/postApi20Dojos を使って宜野湾道場の情報を検索

```
[naopontan@naopontan-MBP coderdojo.jp]$ curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
>   "query": {
>     "countryName": "Japan",
>     "name": "Ginowan, Okinawa@ Okigin S.P.O"
>   }
> }' 'https://zen.coderdojo.com/api/2.0/dojos' | ruby -r json -ne 'jj JSON.parse $_'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  2989  100  2896  100    93   1676     53  0:00:01  0:00:01 --:--:--  1676
[
  {
    "entity$": "-/cd/dojos",
    "id": "901f6e5c-f3de-4bb6-9279-825505872b41",
    "mysqlDojoId": null,
    "dojoLeadId": "fff55e7e-6c5a-42a7-85ed-d4335fb19841",
    "name": "Ginowan, Okinawa@ Okigin S.P.O",
    "creator": "8ffd8c09-f254-4635-b0ce-9db02f64479a",
    "created": "2017-09-20T17:01:33.159Z",
    "verifiedAt": "2017-09-20T17:01:44.091Z",
    "verifiedBy": "d22d7ac3-acaf-4ba3-a467-cdf337ef4bc1",
    "verified": 1,
    "needMentors": 0,
    "stage": 1,
    "mailingList": 0,
    "alternativeFrequency": null,
    "country": {
      "countryName": "Japan",
      "continent": "AS",
      "alpha2": "JP",
      "alpha3": "JPN",
      "countryNumber": "392"
    },
    "county": null,
    "state": null,
    "city": null,
    "place": {
      "nameWithHierarchy": "日本沖縄県宜野湾市"
    },
    "coordinates": "{\"26.2695532\",\"127.73904620000008\"}",
    "geoPoint": {
      "lat": 26.269556,
      "lon": 127.73904100000004
    },
    "notes": "<ul>\n\t<li>場所：沖縄県宜野湾市真志喜１丁目１３−１６（株式会社おきぎんエス・ピー・オー2階会議室）</li>\n\t<li>費用：無料</li>\n\t<li>資格：7歳から17歳</li>\n\t<li>定員：10名</li>\n\t<li>持物：自分のパソコンがあれば持参して下さい。無い場合は道場のパソコンを利用することも可能ですが台数に限りが有るため、全員に行き渡らない可能性があります。<br />\n\t※作ったプログラムや作品を継続して保存したい場合、自宅でも学習したい場合はパソコンを持参することをオススメします。</li>\n\t<li>通常の日程：\n\t<ul>\n\t\t<li>9:00 - 9:30：初めての方向けDojoの説明</li>\n\t\t<li>9:30 - 11:30：プログラミング</li>\n\t\t<li>11:30 - 12:00：発表</li>\n\t\t<li>12:00 - 12:30：Dojo日記の記入と片付け</li>\n\t</ul>\n\t</li>\n\t<li>内容：\n\t<ul>\n\t\t<li>初心者向け：Scratch（スクラッチ）プログラミング</li>\n\t\t<li>中級者向け：ロボット初級プログラミング<br />\n\t\t※上級者向けメニューは準備中です。もう少々お待ち下さい。</li>\n\t</ul>\n\t</li>\n</ul>\n",
    "email": "coderdojo.ginowan@gmail.com",
    "website": "http://www.coderdojo-ginowan.com/",
    "twitter": "coderdojogwan",
    "googleGroup": null,
    "supporterImage": null,
    "deleted": 0,
    "deletedBy": null,
    "deletedAt": null,
    "private": 0,
    "urlSlug": "jp/ri4-ben3-chong1-sheng2-xian4-yi2-ye3-wan1-shi4/ginowan-okinawa-okigin-s-p-o",
    "continent": "AS",
    "alpha2": "JP",
    "alpha3": "JPN",
    "address1": "真志喜1-13-16（株式会社おきぎんエス・ピー・オー2階会議室）",
    "address2": null,
    "countryNumber": 392,
    "countryName": "Japan",
    "admin1Code": null,
    "admin1Name": null,
    "admin2Code": null,
    "admin2Name": null,
    "admin3Code": null,
    "admin3Name": null,
    "admin4Code": null,
    "admin4Name": null,
    "placeGeonameId": null,
    "placeName": "日本沖縄県宜野湾市",
    "userInvites": [

    ],
    "creatorEmail": "yama555net@gmail.com",
    "taoVerified": 0,
    "expectedAttendees": 10,
    "facebook": "coderdojo.ginowan",
    "day": 6,
    "startTime": "09:30:00",
    "endTime": "12:30:00",
    "frequency": "1/w"
  }
]
[naopontan@naopontan-MBP coderdojo.jp]$
```
上記では query パラメータに

- "countryName": "Japan",
- "name": "Ginowan, Okinawa@ Okigin S.P.O"

の2つを指定しているが、例えば `"countryName": "Japan"` だけだと、日本の道場一覧が取得できる。

# 業務フローとデータの流れ

## 道場を立ち上げる

https://coderdojo.jp/kata に記載されている。
要約すると

1. zen への登録
    1. [アカウントを登録](https://zen.coderdojo.com/register)する _(ここから [参加者/メンター/チャンピオン] のいづれにもなれる)_ 
    1. ログイン
    1. [チャンピオン登録フォーム](https://zen.coderdojo.com/dashboard/start-dojo)から必要な情報を入力し、申請する
    1. （しばらくすると承認される）
1. jp への登録
    1. [掲載申請フォーム](http://goo.gl/forms/UfY69hsA99)に入力する
    1. フォームから dojos.yaml 経由で jp サイトに掲載

ポイントは zen と jp で道場に関する情報を各々に入力している。ということです。

## 道場を運営する

- 名称や住所など、文字データの修正
- 「休止」など状態の変更
- ??? チャンピオンの変更/追加/削除 ???
- ??? メンターの変更/追加/削除 ???
- etc...

## 道場を廃止する

疑問: フローは決まっているのか？ zen では deleted フィールドあり。

# 連携する。ということ

まずは zen と jp の各々の道場情報を 1:1 で紐付ける必要がある。
jp への登録申請フォームで以下の入力項目があるが論理的な紐付けにとどまっている

> 承認された CoderDojo Zen の URL を教えてください *
例: https://zen.coderdojo.com/dojo/jp/shimokitazawa-oss-cafe/tokyo



また、以下が判明している。

- zen 側にしか存在しない情報
- jp 側にしか存在しない情報
- 両方に存在する情報
- フィールド名が同じだけど中身が違う情報（ `name` は zen だと英語、 jp だと日本語で入ってたりする）

上記を仕様上どう扱うか？ を考える必要があるが、APIとしてはやり取り可能なことが判明した。

