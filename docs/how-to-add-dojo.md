# 新規Dojoの追加方法

新規Dojoから申請が来た場合の手順書( 2018/02/28現在)

## Dojo DBの追加手順

+ [CoderDojoJapanの申請フォーム](http://goo.gl/forms/UfY69hsA99) に来ている新規Dojoを確認する
    + 申請結果には個人情報が含まれるため、一般公開されていません :secret: 
+ `db/dojos.yaml` 以下に次のようなtemplateで追記する
    + 追記場所は都道府県で順で追加することが好ましい

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
```

フォームとカラムの対応については以下の通りです

| Dojoカラム      |    フォーム    |
|:-----------------|:------------------:|
| `created_at` |  タイムスタンプ  |
|  `order` (*1) | [全国地方公共団体コード](http://www.soumu.go.jp/denshijiti/code.html) |
|`name` | 正式名称 |
| `prefecture_id` | `db/seeds.rb` の該当番号 |
|`logo`  | `public/` のDojo画像パス |
| `url`  |  イベントの管理ページ (個別イベントURLではない) |
| `description`  |フォーム `Dojoの開催場所と開催頻度について教えてください` |
|`tags`  | フォーム `Dojo で対応可能な技術を教えてください (最大5つまで)`|

`id`, `created_at`, `updated_at` はRailsがデフォルトで提供するカラムです。詳細はRailsガイドの[Active Recordの基礎](https://railsguides.jp/active_record_basics.html#%E3%82%B9%E3%82%AD%E3%83%BC%E3%83%9E%E3%81%AE%E3%83%AB%E3%83%BC%E3%83%AB)をご参照ください。

### (*1) `order` の値について

- `order` には総務省が定める[全国地方公共団体コード](http://www.soumu.go.jp/denshijiti/code.html)を値を入力します
- `order` の値は、Dojoの名称が公共団体名になっている場合に省略可能です ([#228](https://github.com/coderdojo-japan/coderdojo.jp/issues/228))
- Dojo名が市町村以外の名称になっている場合のみ入力をする必要があります
    - 例: `CoderDojo 嘉手納` は `嘉手納` 市がある為、自動的に紐付けできます (省略可能)

yaml ファイルに各項目を追記したら、`$ bundle exec rails dojos:update_db_by_yaml` を実行してDBに新規Dojo情報を反映します。その後 `$ bundle exec rails dojos:migrate_adding_id_to_yaml` を実行します。

yamlファイルにidおよびorderが動的に更新されたことを確認できたら `Add CoderDojo [Dojo名]` でコミットをします。

コミットおよびPRの例: https://github.com/coderdojo-japan/coderdojo.jp/pull/274

### 関連Issue

- https://github.com/coderdojo-japan/coderdojo.jp/issues/219

## 集計対象の追加

現在CoderDojoでは開催日、及び参加人数などを集計しています。
集計は手作業でなく、イベントページのAPIを利用し自動化して行っております。
その為、新規Dojoを追加した場合こちらの集計対象にも追加をお願いしています

- 集計対象は `db/dojo_event_services.yaml` で管理をしている為ここに追記をお願いします

```yaml
- dojo_id: 131
  name: facebook
  group_id: 209274086317393
  url: https://www.facebook.com/CoderDojoTottori/
```


| yaml      |    内容    |
|:-----------------|:------------------:|
| `dojo_id` | 該当するDojoのid |
| `name` | 設定するイベント管理サービスの名前 (connpass, facebook, doorkeeper) |
| `group_id` | イベント管理ページのid | 
| `url` | イベント管理ページのURL |

### `group_id` の各種イベントページサービスの取得方法

- Facebook
    1. [lookup-id](https://lookup-id.com/#) にいきます
	2. 当該 Facebook ページのURLを入力すると `group_id` が確認できます
- connpass
	1. connpass のイベントページをブラウザで表示 (Ex. https://coderdojo-tobe.connpass.com/)
	2. イベントのページを表示 (どのイベントでもいいです)
	3. url を見て event のIDを確認 (https://coderdojo-tobe.connpass.com/event/89808/ だと `89808`)
	4. 以下のコマンドで上記の event ID を指定すると `group_id` (Series ID) が得られる
	
	```
	$ curl --silent -X GET https://connpass.com/api/v1/event/?event_id=89808 | jq '.events[0].series.id'
	  5072
	```

## 本番環境への反映方法

dojos.yaml の更新をGitHubにpushすると、次の手順で本番環境に反映される。

1. GitHub の更新を Travis CI が検知する
1. Travis CI で各種テストが実行される
   - １つ以上のテストが失敗すると本番環境には反映されない
1. すべてのテストが成功すると、本番環境へのデプロイが始まります

したがって、Pull Request の時点でCIがパスしていれば、基本的にはマージ後に本番環境 (coderdojo.jp) へ反映されるようになります。

