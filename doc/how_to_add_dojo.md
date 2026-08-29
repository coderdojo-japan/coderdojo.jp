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
9. 本番環境への反映を確認し、下記「[掲載完了メールの送り方](#掲載完了メールの送り方)」で申請者に伝える

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
| `created_at` | **入力しない。** タスク実行時に自動で追加されます  (詳細は後述) |
| `order` | [全国地方公共団体コード](http://www.soumu.go.jp/denshijiti/code.html) (詳細は後述) |
| `name` | Dojo名 |
| `counter` | 省略化。[連名道場](https://github.com/coderdojo-japan/coderdojo.jp/issues/610)を登録する際に使います |
| `prefecture_id` | [db/seeds.rb](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/db/seeds.rb) の県番号 |
| `logo` | 省略可。[public/img/dojos](https://github.com/coderdojo-japan/coderdojo.jp/tree/main/public/img/dojos) にあるDojoロゴ画像パス |
| `url` | 公式Webサイト (イベント管理ページも可) |
| `description` | 既存のパターンに沿って記載。`prefecture_id`があるので都道府県情報は省略。例: `xx市で毎月開催` |
| `tags` | 周知したい技術タグを掲載 (最大5つ)。**申請文の表記をそのまま写さず、既存の表記に揃えます** (詳細は後述) |
| `global_club_id` | 掲載申請の「承認確認」URL に含まれる UUID (詳細は後述) |
| `inactivated_at` | 省略可。休止・閉鎖したら、その日付を入れる (例: `'2026-08-29'`) |
| `is_private` | 省略可。**Clubs で Private Dojo として承認されている**場合のみ true にします (詳細は後述) |


- `id` は後述するコマンドで自動的に作成・書き出しされるため、省略してください。
- `created_at` も同様に省略してください。後述のコマンドが**掲載日**（コマンドを実行した日）を自動で入れます。
  - 入るのは申請の受付日ではなく掲載日です。`/dojos` の日付表示と
    「その年に新規掲載された道場数」の統計に使われます。
    経緯は [PR #1861](https://github.com/coderdojo-japan/coderdojo.jp/pull/1861) を参照してください。
- `order` には総務省が定める[全国地方公共団体コード](http://www.soumu.go.jp/denshijiti/code.html)の値を入力します。（db/city_code.csv も参照できます。）
- `logo` にはロゴ画像へのパスを入力してください。
  - ロゴ画像が省略されていた場合は `default.webp` を入力してください。
  - ロゴ画像があれば `.png` と `.webp` に変換し、[TinyPNG](https://tinypng.com/) で圧縮し、`public/img/dojos` に**２つとも** 置いてください。
  - ロゴ画像が正方形ではない場合、表示が崩れることがあるため、[Macのプレビューで画像に余白を追加](https://www.google.com/search?q=Mac+プレビュー+画像+余白)し、正方形にしてください。
  - 元画像が JPEG の場合は、**先に減色してノイズを除いてから**圧縮してください。
    JPEG を直接通すと圧縮ノイズを「色」として保持し、PNG がかえって肥大化します。

    ```bash
    $ magick in.jpg -colors 32 -strip PNG8:clean.png
    ```

    実測（フラットな色のロゴ / 400x400）は、直接通すと PNG 19.9 KB、
    先にノイズを除くと PNG 4.2 KB でした。写真素材ならこの前処理は不要です。

- `tags` は**既存の表記に揃えてください**。申請文の表記をそのまま写すと、
  日本語のページで同じ技術が別々の表記に分かれてしまいます。
  - 例: 申請に `Raspberry Pi` とあっても、`db/dojos.yml` での表記は `ラズベリーパイ` です。
  - 日本語で書いて問題ありません。英語版の統計ページでは
    [`translate_dojo_tag`](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/app/helpers/application_helper.rb)
    が自動で英訳します。
  - 迷ったら既存の件数を数えてください。0 件なら新しい語彙なので、似た表記を探し直します。

    ```bash
    $ grep -c '^  - ラズベリーパイ$' db/dojos.yml
    ```

- `global_club_id` には掲載申請の「承認確認」URL に含まれる UUID を入力します。
  - 例: `https://codeclub.org/ja/clubs/69fb131d-9c46-40ff-9b70-f79b9302e92b`
    のとき `global_club_id: 69fb131d-9c46-40ff-9b70-f79b9302e92b` となります。
  - **休止・閉鎖していない Dojo では省略できません。** 未設定だと spec が落ちます。
  - 申請に「承認確認」URL が無い場合は、DojoMap が保存している Clubs API のキャッシュから探します。

    ```bash
    curl -s https://raw.githubusercontent.com/coderdojo-japan/map.coderdojo.jp/main/_data/dojos_earth.json |
      ruby -rjson -e 'JSON.parse(STDIN.read).select { |c| c["countryCode"] == "JP" }
                          .each { |c| puts "#{c["id"]}  #{c["name"]}" }' | grep -i naha
    ```

    **Clubs 上の登録名は掲載名と大きく異なることがあります。** ローマ字のもの
    （`那覇` に対して `Naha`、`赤羽` に対して `Akabane, Tokyo`）だけでなく、
    日本語でも別の名前のもの（`播磨科学公園都市` に対して `テクノ@光都`）があります。
    掲載名で grep すると空振りするので、ローマ字・地名・会場名で探してください。
  - それでも見つからない場合、Clubs 側にまだクラブが無い可能性があります。
    申請者に [codeclub.org](https://codeclub.org/) での登録状況を確認してください。
  - DB 側にユニーク制約があります。後述の DojoMap はこの値で突合します。

- `is_private` は **Clubs（旧 Zen）で Private Dojo として承認されている** Dojo にのみ
  true にします。省略した場合は公開扱いです。
  - イベント 1 回の参加制限とは別物です。「今回は◯◯中学校の生徒限定です」という告知は
    その回が限定なだけで、Dojo そのものが非公開とは限りません。
  - **掲載時に判断できなくても構いません。** 開催告知が継続して参加を限定していたら、
    代表者に確認したうえで `true` にしてください（告知は見直すきっかけであって、
    判断の根拠は Clubs 側の登録状況です）。
  - 詳細は [プライベート道場とは？](https://coderdojo.jp/docs/private-dojo) を参照してください。

yaml ファイルに各項目を追記したら次のコマンドを実行し、DB に新規 Dojo 情報を反映させます。

```bash
$ bundle exec rails dojos:update_db_by_yaml
```

その後、DB に反映された `id` や `created_at` を YAML ファイルに書き出すため、次のコマンドを実行します。

```bash
$ bundle exec rails dojos:migrate_adding_id_to_yaml
```

実行後、upsert される ID が現在ある ID 群の中で『最大値+1以上』であることを確認してください。

もし `id: 1` や `id: 3` という値がupsert されていた場合は、`rails console` 上で次のコマンドを実行して、[PostgreSQLの自動採番のシーケンスをリセット](https://github.com/coderdojo-japan/coderdojo.jp/commit/06dce309ac40df13b866d0d5809a652f224fdb7c#r33355507)してください。

```ruby
ActiveRecord::Base.connection.execute("SELECT setval('dojos_id_seq', coalesce((SELECT MAX(id)+1 FROM dojos), 1), false)")
```

YAML ファイルに `id` および `created_at` が追加されたことを確認できたら `:new: Add CoderDojo 那覇 in 沖縄県` といったコミットをし、Pull Request を送ります。

Pull Request 例: https://github.com/coderdojo-japan/coderdojo.jp/pull/274

もしこの時点で「どのイベント管理サービスを使っているか」が分かっていれば、
続けて、後述する統計システムへの追加も行なってください。

<br>

## DojoMap への反映

[DojoMap](https://map.coderdojo.jp) は `db/dojos.yml` の `global_club_id` で
[Clubs API](https://clubs-api.raspberrypi.org/) 上のクラブと突合します。
**この値が入っていれば、地図側での作業は要りません。**

デプロイの翌朝 5:59 (JST) に DojoMap の日次 Actions がデータを取得し、地図を再生成してデプロイします。
すぐ反映したい場合は [Daily Update](https://github.com/coderdojo-japan/map.coderdojo.jp/actions/workflows/scheduler_daily.yml) を手動実行してください。

地図に載ったかは https://map.coderdojo.jp/dojos.json で確認できます。

```bash
curl -s https://map.coderdojo.jp/dojos.json | ruby -rjson -e 'pp JSON.parse(STDIN.read).find { |x| x["name_japan"] == "南城" }'
#=> {"global_club_id" => "b115e722-...", "name_japan" => "南城", "name_earth" => "CoderDojo南城", ...}
```

出てこない場合は次のいずれかです。いずれも DojoMap 側では直せません。

| 状態 | 対応 | 気づき方 |
|---|---|---|
| `global_club_id` が Clubs 上のクラブと一致しない | `db/dojos.yml` の値を現在のものに更新する | **Slack に通知が飛ぶ** |
| Clubs 上に座標が無い、または準備中・活動中のどちらでもない | Clubs の管理画面で登録内容を直してもらう | [日次 Actions のログ](https://github.com/coderdojo-japan/map.coderdojo.jp/actions/workflows/scheduler_daily.yml)にのみ出る |

経緯は [map#42](https://github.com/coderdojo-japan/map.coderdojo.jp/pull/42) を参照してください。
以前は `dojo2dojo.csv` でクラブ名を突合しており、新しい Dojo を追加するたび
地図側に 1 行足す作業が必要でした。

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

### 取得した `group_id` が正しいか確かめる

`bin/c-search` と `bin/d-search` はグループ ID を返しますが、**それが目的のグループかどうかは検証しません**。
実際にイベントを取得できるか確かめてください。`.env` に `CONNPASS_API_KEY` と
`DOORKEEPER_API_TOKEN` が必要です。

`connpass` は期間を指定しなければ全期間を取得します。

```bash
$ bundle exec rails runner '
provider = EventService::Providers::Connpass.new
provider.fetch_events(group_id: 18059).each { |e| puts "#{e["started_at"]}  #{e["title"]}" }'
#=> 2026-10-04T13:00:00+09:00  第1回 CoderDojo鞍手
```

`doorkeeper` は**既定では昨日までしか取得しません**（`fetch_events` の `until_at` の
既定値が `Time.zone.yesterday.end_of_day` のため）。これから開催する回を見たいので、
期間を明示します。キーはシンボルで、日時は `starts_at` です。

```bash
$ bundle exec rails runner '
provider = EventService::Providers::Doorkeeper.new
provider.fetch_events(group_id: 5238, since_at: Time.zone.now, until_at: 1.year.from_now)
        .each { |e| puts "#{e[:starts_at]}  #{e[:title]}" }'
```

0 件のときは、まだイベントが立っていないだけのこともあります。
グループページに開催予定があるのに 0 件なら `group_id` を疑ってください。

<br>

## 本番環境への反映方法

dojos.yml, dojo_event_services.yml の更新を GitHub に push すると、次の手順で本番環境に反映されます。

1. GitHub の更新を [GitHub Actions](https://github.com/coderdojo-japan/coderdojo.jp/actions) が検知します
1. [GitHub Actions](https://github.com/coderdojo-japan/coderdojo.jp/actions) で各種テストが実行されます
   - １つ以上のテストが失敗すると本番環境には反映されません
1. すべてのテストが成功すると、本番環境へのデプロイが始まります

したがって、Pull Request 時点で CI がパスしていれば、基本的にはマージ後に本番環境 (coderdojo.jp) に反映されます。

<br>

## 掲載完了メールの送り方

本番環境への反映を確認したら、掲載申請の連絡先に完了を伝えます。

> ⚠️ 代表者名と連絡先メールアドレスは個人情報です。
> **コミットメッセージ・Pull Request・Issue には書かないでください。**
> このリポジトリは公開されており、あとから編集しても履歴には残ります。

`<>` の箇所を書き換えて使ってください。

```
CoderDojo<Dojo名> <代表者名>さん,

coderdojo.jp への掲載申請ありがとうございます!
CoderDojo Japan の<担当者名>です。

いただいた申請内容をベースに、以下の通り掲載が完了いたしました！

https://coderdojo.jp/
<掲載されたカードのスクリーンショット>

CoderDojo 運営者向けの資料や、
CoderDojo 運営者向けのパートナー法人からのサポートなどは
以下のページにまとめてありますので、コチラもご参考になれば幸いです。
https://coderdojo.jp/kata#support

上記の他、何か気になる点などありましたら
お気軽にご返信いただけると幸いです！

引き続きよろしくお願いいたします。

<担当者名>
```

申請内容だけでは判断できなかったことがあれば、この返信で併せて聞くと確実です。
（例: 参加者を限定して運営しているか = 前述の `is_private` の判断）
