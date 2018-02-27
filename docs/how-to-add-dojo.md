# 新規Dojoの追加方法

新規Dojoから申請が来た場合の手順書( 2018/02/26現在)

## Dojo DBの追加手順

+ [CoderDojoJapanの申請フォーム](http://goo.gl/forms/UfY69hsA99) に来ている新規Dojoを確認する
    + 申請結果には個人情報が含まれるため、一般公開されていません :secret: 
+ `db/dojos.yaml` 以下に次のようなtemplateで追記する
    + 追記場所は都道府県で順で追加することが好ましい

```yaml
- created_at: '2016-12-19'
  order: '473251'
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
|  `order`  | [全国地方公共団体コード] (https://docs.google.com/spreadsheets/d/1b2XZxifpP8GSASvP9sPq1BYwsCH6Y_FHSkol_nfaGxw/edit#gid=1813423171) |
|`name` | 正式名称 |
| `prefecture_id` | `db/seeds.rb` の該当番号 |
|`logo`  | `public/` のDojo画像パス |
| `url`  |  イベントの管理ページ (個別イベントURLではない) |
| `description`  |フォーム `Dojoの開催場所と開催頻度について教えてください` |
|`tags`  | フォーム `Dojo で対応可能な技術を教えてください (最大5つまで)`|


- ここまで記述した後に `be rails dojos:update_db_by_yaml` を実行しdbに新規Dojoを反映する
- その後　`be rails dojos:migrate_adding_id_to_yaml` 　を実行し、yamlにidが動的に付けられた事を確認する

### 関連Issue

- https://github.com/coderdojo-japan/coderdojo.jp/issues/219

## 集計対象の追加

- 集計対象は `db/dojo_event_services.yaml` で管理をしている為ここに追記をする

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

- `group_id` についてはFacebookの場合 [lookup-id](https://lookup-id.com/#) で確認できる

## 本番環境への反映方法

dojos.yaml の更新をGitHubにpushすると、次の手順で本番環境に反映される。

1. GitHub の更新を Travis CI が検知する
1. Travis CI で各種テストが実行される
   - １つ以上のテストが失敗すると本番環境には反映されない
1. すべてのテストが成功すると、本番環境へのデプロイが始まります

したがって、Pull Request の時点でCIがパスしていれば、基本的にはマージ後に本番環境 (coderdojo.jp) へ反映されるようになります。
