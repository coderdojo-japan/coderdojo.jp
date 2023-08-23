# 新規Dojoの追加方法

新規Dojoから申請が来た場合の手順書をまとめています。

<br>

## 追加の手順とデータの読み方

[coderdojo.jp への掲載申請](https://coderdojo.jp/signup)が来たとき、
まずは申請された Dojo 情報を確認します。

### TL;DR（忙しい人向け）

1. 掲載依頼の申請内容を確認する
2. 総務省の[全国地方公共団体コード](https://www.soumu.go.jp/denshijiti/code.html)ページに行く
3. 最新版の PDF にアクセスし、申請内容と一致する全国地方公共団体コードを確認する
4. `db/dojos.yaml` ファイルを開き、全国地方公共団体コードの近い値（隣接する Dojo）のデータを見つける
5. 同じ全国地方公共団体コードがあれば同コードの直後に、初のコードであれば `order` の昇順で適した場所を探す
6. 下記「[データの読み方](#%E3%83%87%E3%83%BC%E3%82%BF%E3%81%AE%E8%AA%AD%E3%81%BF%E6%96%B9%E7%94%B3%E8%AB%8B%E5%86%85%E5%AE%B9%E3%81%A8%E5%AF%BE%E5%BF%9C%E4%BE%8B)」を参考に、申請内容から新しい Dojo データを [`db/dojos.yaml`](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/db/dojos.yaml) に追加する
7. 下記「[統計システムへの追加](#%E7%B5%B1%E8%A8%88%E3%82%B7%E3%82%B9%E3%83%86%E3%83%A0%E3%81%B8%E3%81%AE%E8%BF%BD%E5%8A%A0)」を参考に、イベント管理サービスを [`db/dojo_event_services.yaml`](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/db/dojo_event_services.yaml) に追加する
8. 上記の作業結果をコミットし、Pull Request (PR) を送る

参考 PR: [coderdojo-japan/coderdojo.jp#1449](https://github.com/coderdojo-japan/coderdojo.jp/pull/1449)

<br>

### データの読み方（申請内容と対応例）

次のような掲載申請が来たときを例にとって説明します。

```
Dojo名: CoderDojo 那覇
Dojoタグ: Scratch, Webサイト, Ruby
説明文: 那覇市で毎月開催
ロゴ (任意): 
Web: https://coderdojo-naha.doorkeeper.jp/
代表者: *** (個人情報のため非表示)
連絡先: *** (個人情報のため非表示)
受付日: 2019/06/15 9:42:10
Zen: https://zen.coderdojo.com/dojos/jp/okinawa-ken/okinawa-okinawa-prefecture/naha
```

上記のような申請を受け取ったら `db/dojos.yaml` に次のように追記します。   
(order 順に追加すると見やすくてベターです)


```yaml
- order: '472018'
  created_at: '2019-06-15'
  name: 那覇
  counter: 1                       # 省略化。連名道場のときに使います (後述)
  prefecture_id: 47
  logo: "/img/dojos/default.webp"  #  ロゴがあれば naha.webp として追加
  url: https://coderdojo-naha.doorkeeper.jp/
  description: 那覇市で毎月開催    # 県名や開催頻度などの用語を適宜統一
  tags:
  - Scratch
  - Webサイト
  - Ruby
```

各項目と内容については次の通りです。

| 項目名 | 内容 |
|:---|:---|
| `id` | **入力しない。** タスク実行時に自動で追加されます (詳細は後述) |
| `created_at` | 掲載申請日の年月日 |
| `order` | [全国地方公共団体コード](http://www.soumu.go.jp/denshijiti/code.html) (詳細は後述) |
| `name` | Dojo名 |
| `counter` | 省略化。[連名道場](https://github.com/coderdojo-japan/coderdojo.jp/issues/610)を登録する際に使います |
| `prefecture_id` | [db/seeds.rb](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/db/seeds.rb) の県番号 |
| `logo` | 省略可。[public/img/dojos](https://github.com/coderdojo-japan/coderdojo.jp/tree/main/public/img/dojos) にあるDojoロゴ画像パス |
| `url` | 公式Webサイト (イベント管理ページも可) |
| `description` | 既存のパターンに沿って記載。`prefecture_id`があるので都道府県情報は省略。例: `xx市で毎月開催` |
| `tags` | 周知したい技術タグを掲載 (最大5つ) |
| `is_active` | 省略可。非アクティブになったらfalseにする |
| `is_private` | 省略可。プライベートならtrueにする |


- `id` は後述するコマンドで自動的に作成・書き出しされるため、省略してください。
- `order` には総務省が定める[全国地方公共団体コード](http://www.soumu.go.jp/denshijiti/code.html)の値を入力します。（db/city_code.csv も参照できます。）
- `logo` のロゴ画像は [TinyPNG](https://tinypng.com/) で圧縮してから `public/img/dojos` に置いてください。
  - サイズが正方形以外の場合、表示が崩れる場合があるので、[Macのプレビューで画像に余白を付け足す方法](http://teapipin.blog10.fc2.com/blog-entry-913.html)を参考に正方形にすると良さそうです。

yaml ファイルに各項目を追記したら次のコマンドを実行し、DB に新規 Dojo 情報を反映させます。

```bash
$ bundle exec rails dojos:update_db_by_yaml
```

その後、DB に反映された id を yaml に書き出すため、次のコマンドを実行します。

```bash
$ bundle exec rails dojos:migrate_adding_id_to_yaml
```

実行後、upsert される ID が現在ある ID 群の中で『最大値+1以上』であることを確認してください。

もし `id: 1` や `id: 3` という値がupsert されていた場合は、`rails console` 上で次のコマンドを実行して、[PostgreSQLの自動採番のシーケンスをリセット](https://github.com/coderdojo-japan/coderdojo.jp/commit/06dce309ac40df13b866d0d5809a652f224fdb7c#r33355507)してください。

```ruby
ActiveRecord::Base.connection.execute("SELECT setval('dojos_id_seq', coalesce((SELECT MAX(id)+1 FROM dojos), 1), false)")
```

yaml ファイルに id および order が動的に更新されたことを確認できたら `:new: Add CoderDojo 那覇 in 沖縄県` といったコミットをし、Pull Request を送ります。

Pull Request 例: https://github.com/coderdojo-japan/coderdojo.jp/pull/274

もしこの時点で「どのイベント管理サービスを使っているか」が分かっていれば、
続けて、後述する統計システムへの追加も行なってください。

<br>

## 統計システムへの追加

coderdojo.jp では開催日、及び参加人数などを集計し、統計ページから公開しています。

統計情報 - CoderDojo Japan
https://coderdojo.jp/stats

集計は手作業でなく、イベントページのAPIを利用し自動化して行っています。   
このため、新規 Dojo を追加する際は、集計対象にも追加をお願いします。

集計対象は `db/dojo_event_services.yaml` で管理していますので、ここに追記してください

```yaml
- dojo_id: 131
  name: facebook
  group_id: 209274086317393
  url: https://www.facebook.com/CoderDojoTottori/
```

|yaml|内容|
|:---|:---|
| `dojo_id` | 該当する Dojo の id |
| `name` | 設定するイベント管理サービスの名前 (connpass, facebook, doorkeeper) |
| `group_id` | イベント管理ページの id |
| `url` | イベント管理ページの URL |

### イベントページサービスごとの `group_id` の取得方法

- Facebook
  1. [lookup-id](https://lookup-id.com/#)、または [findmyfbid](https://findmyfbid.com/) へ
  2. 当該 Facebook ページの URL を入力すると `group_id` が確認できます
- connpass
  1. connpass のイベントページをブラウザで表示します (Ex. https://coderdojo-tobe.connpass.com/)
  2. イベントのページを表示します (どのイベントでもOK)
  3. イベントページの URL をコピーします
  4. 以下のコマンドで上記のコピーした URL を指定すると `group_id` (Series ID) が得えられます
  
  ```
  $ bin/c-search https://coderdojo-tobe.connpass.com/event/89808/
    => 5072
  ```
  `jq`コマンドが使えない場合はインストールしてください。

  ```
  $ brew install jq
  ```
  
- Doorkeeper
  1. connpassと 同様に、Doorkeeper のイベントページの url から event ID を確認します (https://coderdojo-suita.doorkeeper.jp/events/90704 だと `90704`)
  2. 以下のコマンドで上記の event ID を指定すると `group_id` (group) を得ることができます
  
  ```
  $ curl --silent -X GET https://api.doorkeeper.jp/events/90704 | jq '.event.group'
    9690
  ```

<br>

## 本番環境への反映方法

dojos.yaml, dojo_event_services.yaml の更新を GitHub に push すると、次の手順で本番環境に反映されます。

1. GitHub の更新を [GitHub Actions](https://github.com/coderdojo-japan/coderdojo.jp/actions) が検知します
1. [GitHub Actions](https://github.com/coderdojo-japan/coderdojo.jp/actions) で各種テストが実行されます
   - １つ以上のテストが失敗すると本番環境には反映されません
1. すべてのテストが成功すると、本番環境へのデプロイが始まります

したがって、Pull Request 時点で CI がパスしていれば、基本的にはマージ後に本番環境 (coderdojo.jp) に反映されます。
