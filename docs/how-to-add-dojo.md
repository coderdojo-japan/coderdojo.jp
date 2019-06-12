# 新規Dojoの追加方法

新規Dojoから申請が来た場合の手順書(2018/06/13現在)

## Dojo DB の追加手順

+ [CoderDojoJapanの申請フォーム](http://goo.gl/forms/UfY69hsA99) に来ている新規 Dojo を確認します
    + 申請結果には個人情報が含まれるため、一般公開されていません :secret:
+ `db/dojos.yaml` 以下に次のような template で追記します
    + 都道府県順になるよう追加するとベターです

```yaml
- created_at: '2016-12-19'
  name: 嘉手納 (沖縄)
  prefecture_id: 47
  logo: "/img/dojos/kadena.png"
  url: http://coderdojokadena.hatenablog.jp/
  description: 沖縄県中頭郡で毎月開催
  tags:
  - Scratch
  - LEGO Mindstorms
  - ラズベリーパイ
  is_active: true
  is_private: false
```

フォームとカラムの対応については以下の通りです。

| Dojoカラム | フォーム |
|:---|:---|
| `created_at` | タイムスタンプ |
| `order` (*1) | [全国地方公共団体コード](http://www.soumu.go.jp/denshijiti/code.html) |
| `name` | 正式名称 |
| `prefecture_id` | `db/seeds.rb` の該当番号 |
| `logo` | `public/` のDojo画像パス |
| `url` | イベントの管理ページ (個別イベントURLではない) |
| `description` | フォーム `Dojoの開催場所と開催頻度について教えてください` |
| `tags` | フォーム `Dojoで対応可能な技術を教えてください (最大5つまで)` |
| `is_active` | [省略可] アクティブ/非アクティブ (省略時、アクティブ) |
| `is_private` | [省略可] パブリック/プライベート (省略時、パブリック) |

`id`, `created_at`, `updated_at` は Rails がデフォルトで提供するカラムです。詳細は Railsガイドの[Active Recordの基礎](https://railsguides.jp/active_record_basics.html#%E3%82%B9%E3%82%AD%E3%83%BC%E3%83%9E%E3%81%AE%E3%83%AB%E3%83%BC%E3%83%AB)をご参照ください。

### (*1) `order` の値について

- `order` には総務省が定める[全国地方公共団体コード](http://www.soumu.go.jp/denshijiti/code.html)を値を入力します
- `order` の値は、Dojo の名称が公共団体名になっている場合に省略可能です ([#228](https://github.com/coderdojo-japan/coderdojo.jp/issues/228))
- Dojo 名が市町村以外の名称になっている場合のみ入力する必要があります
    - 例: `CoderDojo 嘉手納` は `嘉手納` 市があるため、自動的に紐付けされます (省略可能)

yaml ファイルに各項目を追記したら、`$ bundle exec rails dojos:update_db_by_yaml` を実行して DB に新規 Dojo 情報を反映します。その後 `$ bundle exec rails dojos:migrate_adding_id_to_yaml` を実行します。

実行後、upsert される ID の値を確認します。ID は現在ある ID 群の中で『最大値+1以上』である必要があります。もし `id: 1` や `id: 3` という値がupsert されていた場合は、`rails console` 上で次のコマンドを実行して、[PostgreSQLの自動採番のシーケンスをリセット](https://github.com/coderdojo-japan/coderdojo.jp/commit/06dce309ac40df13b866d0d5809a652f224fdb7c#r33355507) します。

```ruby
ActiveRecord::Base.connection.execute("SELECT setval('dojos_id_seq', coalesce((SELECT MAX(id)+1 FROM dojos), 1), false)")
```

yaml ファイルに id および order が動的に更新されたことを確認できたら `Add CoderDojo [Dojo名]` でコミットします。

コミットおよび PR の例: https://github.com/coderdojo-japan/coderdojo.jp/pull/274

### 関連 Issue

- https://github.com/coderdojo-japan/coderdojo.jp/issues/219

## 集計対象の追加

現在 CoderDojo では開催日、及び参加人数などを集計しています。
集計は手作業でなく、イベントページのAPIを利用し自動化して行っています。
このため、新規 Dojo を追加した場合こちらの集計対象にも追加をお願いしています。

- 集計対象は `db/dojo_event_services.yaml` で管理していますので、ここに追記してください

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
  1. [lookup-id](https://lookup-id.com/#) へ
  2. 当該 Facebook ページの URL を入力すると `group_id` が確認できます
- connpass
  1. connpass のイベントページをブラウザで表示します (Ex. https://coderdojo-tobe.connpass.com/)
  2. イベントのページを表示します (どのイベントでもOK)
  3. url から event の ID を確認します (https://coderdojo-tobe.connpass.com/event/89808/ だと `89808`)
  4. 以下のコマンドで上記の event ID を指定すると `group_id` (Series ID) を得ることができます
  
  ```
  $ curl --silent -X GET https://connpass.com/api/v1/event/?event_id=89808 | jq '.events[0].series.id'
    5072
  ```
  
- Doorkeeper
  1. connpassと 同様に、Doorkeeper のイベントページの url から event ID を確認します (https://coderdojo-suita.doorkeeper.jp/events/90704 だと `90704`)
  2. 以下のコマンドで上記の event ID を指定すると `group_id` (group) を得ることができます
  
  ```
  $ curl --silent -X GET https://api.doorkeeper.jp/events/90704 | jq '.event.group'
    9690
  ```

## 本番環境への反映方法

dojos.yaml, dojo_event_services.yaml の更新を GitHub に push すると、次の手順で本番環境に反映されます。

1. GitHub の更新を Travis CI が検知する
1. Travis CI で各種テストが実行される
  - １つ以上のテストが失敗すると本番環境には反映されない
1. すべてのテストが成功すると、本番環境へのデプロイが始まります

したがって、Pull Request の時点で CI がパスしていれば、基本的にはマージ後に本番環境 (coderdojo.jp) に映されます。
