# 新規Dojoの追加方法

新規Dojoから申請が来た場合の手順書をまとめています。

[<img width="338" height="354" alt="image" src="https://github.com/user-attachments/assets/95fd7b3e-8a49-4631-9a87-a486d69c8d4e" />](https://github.com/coderdojo-japan/coderdojo.jp/pulls?q=is:pr+"Add+CoderDojo")

<br>

## 追加の手順とデータの読み方

[coderdojo.jp への掲載申請](https://coderdojo.jp/signup)が来たとき、
まずは申請された Dojo 情報を確認します。

### TL;DR（忙しい人向け）

1. 掲載依頼の申請内容を確認する
2. 総務省の[全国地方公共団体コード](https://www.soumu.go.jp/denshijiti/code.html)ページに行く
3. 最新版の PDF にアクセスし、申請内容と一致する全国地方公共団体コードを確認する
4. `db/dojos.yml` ファイルを開き、全国地方公共団体コードの近い値（隣接する Dojo）のデータを見つける
5. 同じ全国地方公共団体コードがあれば同コードの直後に、初のコードであれば `order` の昇順で適した場所を探す
6. 下記「[データの読み方](#データの読み方申請内容と対応例)」を参考に、申請内容から新しい Dojo データを [`db/dojos.yml`](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/db/dojos.yml) に追加する
7. 下記「[統計システムへの追加](#統計システムへの追加)」を参考に、イベント管理サービスを [`db/dojo_event_services.yml`](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/db/dojo_event_services.yml) に追加する
8. 上記の作業結果をコミットし、Pull Request (PR) を送る

[&raquo; これまでの対応例 (PR) を見る](https://github.com/coderdojo-japan/coderdojo.jp/pulls?q=is:pr+"Add+CoderDojo")

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

上記のような申請を受け取ったら `db/dojos.yml` に次のように追記します。   
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
- `logo` にはロゴ画像へのパスを入力してください。
  - ロゴ画像が省略されていた場合は `default.webp` を入力してください。
  - ロゴ画像があれば `.png` と `.webp` に変換し、[TinyPNG](https://tinypng.com/) で圧縮し、`public/img/dojos` に**２つとも** 置いてください。
  - ロゴ画像が正方形ではない場合、表示が崩れることがあるため、[Macのプレビューで画像に余白を追加](https://www.google.com/search?q=Mac+プレビュー+画像+余白)し、正方形にしてください。

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

集計対象は [`db/dojo_event_services.yml`](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/db/dojo_event_services.yml) で管理しています。以下のように追記してください。

```yaml
# 田町@VMware
- dojo_id: 295
  name: connpass
  group_id: 13115
  url: https://coderdojo-tamachi-vmware.connpass.com/
```

|yaml|内容|
|:---|:---|
| `dojo_id` | 該当する Dojo の id |
| `name` | 設定するイベント管理サービスの名前 (connpass, doorkeeper) |
| `group_id` | イベント管理ページの id |
| `url` | イベント管理ページの URL |

### 各イベント管理サービスの `group_id` の取得方法

- `connpass` の場合は [Connpass API](https://connpass.com/about/api/) から取得します
  1. connpass のグループまたはイベントページをブラウザで表示します。例: https://coderdojo-tobe.connpass.com/
  2. URL をコピーします
  3. 以下のコマンドで上記のコピーした URL を指定すると `group_id` が得られます
  
  ```
  $ bundle exec bin/c-search https://coderdojo-tobe.connpass.com/
    => 5072
  ```

  `jq`コマンドが使えない場合はインストールしてください。

  ```
  $ brew install jq
  ```
  
- `doorkeeper` の場合は [Doorkeeper API](https://www.doorkeeper.jp/developer/api?locale=en) から取得します
  1. Doorkeeper のイベントページをブラウザで表示します。例: https://coderdojo-suita.doorkeeper.jp/events/90704
  2. URL をコピーします
  3. 以下のコマンドで上記のコピーした URL を指定すると `group_id` が得られます
  
  ```
  $ bundle exec bin/d-search https://coderdojo-minamiaizu.doorkeeper.jp/events/193082
    98760
  ```

  `jq`コマンドが使えない場合はインストールしてください。

  ```
  $ brew install jq
  ```

<br>

## 本番環境への反映方法

dojos.yml, dojo_event_services.yml の更新を GitHub に push すると、次の手順で本番環境に反映されます。

1. GitHub の更新を [GitHub Actions](https://github.com/coderdojo-japan/coderdojo.jp/actions) が検知します
1. [GitHub Actions](https://github.com/coderdojo-japan/coderdojo.jp/actions) で各種テストが実行されます
   - １つ以上のテストが失敗すると本番環境には反映されません
1. すべてのテストが成功すると、本番環境へのデプロイが始まります

したがって、Pull Request 時点で CI がパスしていれば、基本的にはマージ後に本番環境 (coderdojo.jp) に反映されます。
