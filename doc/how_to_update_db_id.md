# PostgreSQL の Auto Incremental ID を初期化する方法

CoderDojo で新しく Dojo を掲載するとき、次のコマンド Dojo ID 作成し、作成した ID を yaml に追記する作業があります。

```bash
# 1. ID 以外のデータを DB に反映させ、IDを自動発行
$ bundle exec rails dojos:update_db_by_yaml

# 2. 自動発行された ID を yaml に反映させる
$ bundle exec rails dojos:migrate_adding_id_to_yaml
```
 
このとき、環境構築したばかりや、他の開発者が ID を追加すると、手元の PostgreSQL DB の `dojos_id_seq` の値と異なってしまい、次のようなエラーが発生します。

```
╭─○ yasulab ‹2.6.2› ~/coderdojo.jp
╰─○ be rails dojos:update_db_by_yaml

rails aborted!
ActiveRecord::RecordNotUnique: PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint "dojos_pkey"
DETAIL:  Key (id)=(4) already exists.
: INSERT INTO "dojos" ("name", "email", "order", "description", "logo", "url", "tags", "created_at", "updated_at", "prefecture_id") VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING "id"
/Users/yasulab/coderdojo.jp/lib/tasks/dojos.rake:44:in `block (3 levels) in <top (required)>'
/Users/yasulab/coderdojo.jp/lib/tasks/dojos.rake:29:in `each'
/Users/yasulab/coderdojo.jp/lib/tasks/dojos.rake:29:in `block (2 levels) in <top (required)>'
bin/rails:4:in `require'
bin/rails:4:in `<main>'
```

上記のようなエラーが発生したときは、手元の Postgre SQL にログインし、ID を自動発行される際に参照される値 `dojos_id_seq` を既存のID値の最大値にセットしておくと解決します 😉

```bash
╭─○ yasulab ‹2.6.2› ~/coderdojo.jp
╰─○ psql -U yasulab coderdojo_jp_development

psql (11.1)
Type "help" for help.

coderdojo_jp_development=# 
SELECT setval('dojos_id_seq',(SELECT max(id) FROM dojos));

 setval
--------
    214
(1 row)

coderdojo_jp_development=#
exit

╭─○ yasulab ‹2.6.2› ~/coderdojo.jp
╰─○
```

:octocat: コミット例: [75d4e48](https://github.com/coderdojo-japan/coderdojo.jp/commit/75d4e48e44010ec8da6c8c092fa9554913d0f849) :new: Add CoderDojo 大石田@PCチャレンジ倶楽部

DB の Incremental ID の値を初期化する際のご参考になれば...!! (＞人＜ )✨

🤔.oO(Rakeタスク内で、冪等性を担保したまま、上記の処理を入れるともっと簡単になったりしないかな...?)

cf. [dojos:update_db_by_yaml タスク内で、既存の dojos_id_seq の最大値を取得する処理を入れたい #484](https://github.com/coderdojo-japan/coderdojo.jp/issues/484)
