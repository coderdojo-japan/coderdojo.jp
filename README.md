[![カバー画像](https://raw.githubusercontent.com/coderdojo-japan/coderdojo.jp/main/public/cover_rounded.png)](https://coderdojo.jp/)

# CoderDojo Japan

[![Build Status](https://github.com/coderdojo-japan/coderdojo.jp/actions/workflows/test.yml/badge.svg)](https://github.com/coderdojo-japan/coderdojo.jp/actions)

一般社団法人 CoderDojo Japan の公式サイトです。[Ruby on Rails](http://rubyonrails.org/) で実装されています。本ページでは、トップページに掲載されている Dojo 情報を更新する方法や、開発環境のセットアップ方法などをまとめています。

<br>

## :beginner: Dojo を掲載するには?

CoderDojo を立ち上げ、承認されたら、[CoderDojo Kata にある支援プログラム](https://coderdojo.jp/kata#support)をご利用することができます。[coderdojo.jp](https://coderdojo.jp) への掲載方法も載っていますので、詳細は [CoderDojo Kata](https://coderdojo.jp/kata#support) をご確認ください。

[![CoderDojo Kata - 支援](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/public/img/kata_support_ss.png?raw=true)](https://coderdojo.jp/kata#support)

<br>

## :wrench: 開発に参加するには?

coderdojo.jp の開発には以下のいずれかの方法で参加できます。Dojo 情報の修正やドキュメントの追加・執筆であれば、ブラウザだけで参加できます。

1. Dojo 情報を更新する場合 ([» 詳細を見る](#1-dojo-情報を更新する))
   - 必要なもの: ブラウザ + GitHub アカウント
2. [CoderDojo Kata](https://coderdojo.jp/kata) を更新する場合 ([» 詳細を見る](#2-kata-情報を更新する))
   - 必要なもの: ブラウザ + GitHub アカウント
3. 新機能の開発やデザインを改善する場合 ([» 詳細を見る](#3-新機能の開発やデザインを改善する))
   - 必要なもの: Ruby on Rails + PostgreSQL などの各種開発環境

**ちょっとした情報更新や文言修正であればブラウザだけで参加できる**のが特徴で、それぞれの手順は以下の通りです ✨📝💨 



<br>

## 1. Dojo 情報を更新する

Dojo 情報は次の手順で簡単に更新できます。

1. [db/dojos.yaml](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/db/dojos.yaml) を開く
2. 画面右にある ✎ アイコン (Fork this project and edit this file) をクリックする
3. 気になる箇所を修正し、修正内容にタイトルと説明文を付け、Propose file change をクリックする
4. 修正内容を確認し、問題なければ Create pull request をクリックする
   - :yin_yang: Dojo のロゴ画像を追加/変更したい場合は Pull Request のコメント欄に画像を添付して頂けると助かります :relieved: ([対応例1](https://github.com/coderdojo-japan/coderdojo.jp/pull/1537) / [対応例2](https://github.com/coderdojo-japan/coderdojo.jp/pull/1418) / [対応例3](https://github.com/coderdojo-japan/coderdojo.jp/pull/1417))

以上で完了です。提案された修正はメンテナーによってチェックされ、問題なければ提案された内容が反映されます。もし問題があってもメンテナー側で気付いて修正できるので、まずはお気軽に提案してみてください :wink:

https://coderdojo.jp/docs にあるドキュメントの編集方法も同様です。[db/docs](https://github.com/coderdojo-japan/coderdojo.jp/tree/main/db/docs)ディレクトリをブラウザで開き、修正したいファイルをクリックして、修正内容を提案してください。同ディレクトページの右上にある `Create new file` ボタンをクリックすると、新しいドキュメントの追記を提案することもできます。

<br>

## 2. Kata 情報を更新する

Kata 情報も、Dojo 情報と同様の方法で更新できます。

1. [kata.html.erb](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/app/views/docs/kata.html.erb) を開く
2. 画面右にある ✎ アイコン (Fork this project and edit this file) をクリックする
3. 気になる箇所を修正し、修正内容にタイトルと説明文を付け、Propose file change をクリックする
4. 修正内容を確認し、問題なければ Create pull request をクリックする ([対応例](https://github.com/coderdojo-japan/coderdojo.jp/pull/1384))

以上で完了です。提案された修正はメンテナーによってチェックされ、問題なければ提案された内容が反映されます。もし問題があってもメンテナー側で気付いて修正できるので、まずはお気軽に提案してみてください :wink:

<!--
[Kata](https://coderdojo.jp/kata) や [Sotechsha](https://coderdojo.jp/sotechsha2) などのいくつかのページは、[Scrivito](https://scrivito.com/) と呼ばれる CMS (コンテンツ管理サービス) で運営しています。

編集方法は下記の手順書をご参照してください。

:scroll: Kata の編集方法 - esa   
https://esa-pages.io/p/sharing/7542/posts/213/bc0e68f705b7298ae5e0.html

Kata の編集には CoderDojo Japan のアカウントが必要です。アカウントを発行したい場合は [@yasulab](https://twitter.com/yasulab) までご連絡ください。

CMS を利用している背景や技術仕様などについては次のスライド資料にまとめています。もし興味あればお気軽にご参照ください :wink:

:scroll: CoderDojo を支える Rails CMS の活用事例 - Speaker Deck   
https://speakerdeck.com/yasulab/case-study-rails-cms-for-coderdojo
-->

<br>

## 3. 新機能の開発やデザインを改善する

本サイトでは以下の技術が使われているので、それぞれのツールをセットアップします。

- [Ruby](https://www.ruby-lang.org/ja/)
- [Ruby on Rails](http://rubyonrails.org/)
- [PostgreSQL](https://www.postgresql.jp/)


セットアップ方法の方法は次の通りです。

1. 本リポジトリを fork 後、clone します
1. ターミナルから `$ bin/setup` を実行します
1. `$ rails server` でローカルサーバーを立ち上げます
1. ブラウザから [localhost:3000](http://localhost:3000) にアクセスします
1. [coderdojo.jp](https://coderdojo.jp/) と同様のサイトが表示できれば完了です


### :whale: Docker を利用したセットアップ方法

上記の他、Docker を使ったセットアップ方法もあります。[Docker](https://www.docker.com/community-edition) をインストールし、下記の手順でセットアップしてください 🛠💨

Doorkeeperのイベントを取得するために、[こちらでPublic API Access Tokenを生成](https://manage.doorkeeper.jp/user/oauth/applications)しておく必要があります。

1. 本リポジトリを fork 後、clone します
1. `.env.sample` をコピーして `.env` にリネームします
1. `.env`に、環境変数`DOORKEEPER_API_TOKEN=<生成したPublic API Access Token>` を追記します
1. ターミナルから `$ docker-compose up` を実行します
1. ターミナルから `$ docker-compose exec rails bin/setup` を実行します
1. ブラウザから [localhost:3000](http://localhost:3000) にアクセスします
1. [coderdojo.jp](https://coderdojo.jp/) と同様のサイトが表示できれば完了です


### :rocket: CI/Deploy 構成

[coderdojo.jp](https://coderdojo.jp/)  は現在、次の構成でテスト・デプロイされています。

- CI: [GitHub Actions](https://github.com/coderdojo-japan/coderdojo.jp/actions)
- Deploy: Heroku + [Release Phase](https://devcenter.heroku.com/ja/articles/release-phase)
- 関連PR: [:octocat: replace travis with github actions and heroku integration](https://github.com/coderdojo-japan/coderdojo.jp/pull/1315)

各コミットが push される度に CI が動きます。`main` ブランチに新しいコミットが追加され、CI が pass すると、Heroku 側でデプロイ前/デプロイ後の各種スクリプトが実行されます。

- テスト(CI): [.github/workflows/test.yml](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/.github/workflows/test.yml)
- デプロイ前: Bundle, Asset Precomiple, Heroku Buildpack など
- デプロイ後: [scripts/release.sh](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/scripts/release.sh), [Procfile](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/Procfile)

GitHub Actions に `deploy` workflow を入れることもできましたが、次の２つの目的から現在は分離しています。

1. CI フローと Deploy フローの責務を分離し、本番環境のログの機密性を高める
   - 例: デプロイ関連のログは [Heroku Activity Logs](https://dashboard.heroku.com/apps/coderdojo-japan/activity) に集約させ、誰でもアクセスできる状態にしない
2. [Heroku Release Phase](https://devcenter.heroku.com/ja/articles/release-phase) を使い、本番環境の安定性を高める
   - 例: Heroku デプロイ後に実行するスクリプトが失敗したとき、デプロイ自体がロールバックするようにし、本番環境が落ちる可能性を小さくする

### :gem: CI で実行される各種 Ruby スクリプト (Rake タスク)

最新版は [scripts/release.sh](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/scripts/release.sh) からご確認いただけます。

```
# データベースのマイグレーション
bundle exec rails db:migrate

# 開発用データの流し込み（seeding）
bundle exec rails db:seed

# db/dojos.yaml の内容をDBに反映するタスク
bundle exec rails dojos:update_db_by_yaml

# DBの内容を db/dojos.yaml に反映するタスク
bundle exec rails dojos:migrate_adding_id_to_yaml

# 近日開催の道場を更新するタスク
bundle exec rails dojo_event_services:upsert

# ポッドキャスト「DojoCast」のデータを反映するタスク
bundle exec rails podcasts:upsert
```


<!--
### :cloud: Development with Scrivito

(:warning: *NOTE: Scrivito チームと相談し、今後別の仕組みに置き換わる予定です*)

Some pages require [Scrivito](https://scrivito.com/), Professional Cloud-Based Rails CMS, such as:

- `/kata`
- ~~/news/*~~ (Outdated)
- `/sotechsha/*`

CMS enables wider people to contribute to editing contents, but on the other hand, this requires Scrivito API Keys for engineers to join developing Scrivito-used pages like above.

We use `SCRIVITO_TENANT` and `SCRIVITO_API_KEY` keys in production, but they are not required in development. If you find any problem that needs them report it to [GitHub Issues](https://github.com/coderdojo-japan/coderdojo.jp/issues).
-->

<br>

## 4. 他、開発に関する資料

開発に関する資料は [/docs](https://github.com/coderdojo-japan/coderdojo.jp/tree/main/docs) や下記サイトにまとめてあります (最新順)。必要に応じて適宜ご参照ください。

- [DojoCast を Jekyll から Rails に移行しました](https://yasslab.jp/ja/posts/migrate-dojocast-from-jekyll-to-rails)
- [新規 Dojo の追加方法 - GitHub](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/docs/how_to_add_dojo.md)
- [子どものためのプログラミング道場『CoderDojo』の Ruby/Rails 活用事例](https://speakerdeck.com/yasulab/case-study-of-how-coderdojo-japan-uses-ruby)
- [CoderDojo を支える Rails CMS の活用事例 - Speaker Deck](https://speakerdeck.com/yasulab/case-study-rails-cms-for-coderdojo)
- [2020年 coderdojo.jp 開発ふりかえり](https://note.com/yasslab/n/nb42fb058d4a0?magazine_key=m7ed183f728c3)
- [2019年 coderdojo.jp 開発ハイライト](https://note.com/yasslab/n/n572a17f68842?magazine_key=m7ed183f728c3)
- [2018年 運用目線で見る coderdojo.jp 開発](https://yasslab.jp/ja/news/coderdojo-japan-2018)
- [CoderDojo Japan の各種機能と実装について【2017年版】 - Qiita](https://qiita.com/yasulab/items/1d12e6b295c0a9e577f1)
- [CoderDojo Japan のバックエンドを刷新しました【2016年】](https://coderdojo.jp/docs/post-backend-update-history)

### 🤝 API

現在提供中の API の一覧です。利用例のある API は互換性を意識して開発されるため、比較的使いやすいです。ただし予告なく破壊的な変更が行われる可能性もあるため、あらかじめご了承いただけると幸いです 🚧

- **Podcast API: https://coderdojo.jp/podcasts.rss**
  - 利用例: [📻 Apple Podcasts - DojoCast](https://podcasts.apple.com/us/podcast/dojocast/id1458122473) (関連PR: [coderdojo.jp#387](https://github.com/coderdojo-japan/coderdojo.jp/pull/387))
- **Dojo API: https://coderdojo.jp/dojos.json**
  - 利用例: [📰 DojoNews - GitHub](https://news.coderdojo.jp/category/news/) (関連PR: [coderdojo.jp#1433](https://github.com/coderdojo-japan/coderdojo.jp/pull/1433))
- **Event API: https://coderdojo.jp/events.json**
  - 利用例: [🗾 DojoMap - GitHub](https://github.com/coderdojo-japan/map.coderdojo.jp#readme) (関連PR: [map.coderdojo.jp#10](https://github.com/coderdojo-japan/map.coderdojo.jp/pull/10))
  - 利用例: [📅 CoderDojo カレンダーを作ってみた](https://qiita.com/takatama/items/60276143e441c1c4f078) (関連PR: [coderdojo.jp#1547](https://github.com/coderdojo-japan/coderdojo.jp/pull/1547))

なお本サイト内 DB の各テーブルおよびそのデータ（一般公開部分のみ）は、以下のファイルからご確認いただけます。

- DB テーブル: [`db/schema.rb`](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/db/schema.rb)
- Dojo データ: [`db/dojos.yaml`](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/db/dojo_event_services.yaml)
- Event データ (の情報取得元): [`db/dojo_event_services.yaml`](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/db/dojo_event_services.yaml)
  - :memo: １つの Dojo が複数のイベント管理サービスを使う事例もあるため [`Dojo has_many DojoEventServices`](https://github.com/coderdojo-japan/coderdojo.jp/blob/main/app/models/dojo.rb) となっています。

### :scroll: Development History & Contributors

- **2012:** CoderDojo Japan started in [Facebook Group](https://www.facebook.com/groups/coderdojo.jp/about/)
- **2014:** coderdojo.jp was launched as ['coderdojo-japan.github.io'](https://github.com/coderdojo-japan/coderdojo-japan.github.io/graphs/contributors)
- **2015:** coderdojo.jp was migrated to Parse as ['web'](https://github.com/coderdojo-japan/web/graphs/contributors)
- **2016:** [Parse shutdown](https://speakerdeck.com/yasulab/case-study-rails-cms-for-coderdojo?slide=26). [@yasulab](https://github.com/yasulab) migrated ['coderdojo.jp'](https://github.com/coderdojo-japan/coderdojo.jp/graphs/contributors) from Parse to Ruby on Rails
  - Thanks [@cognitom](https://github.com/cognitom) for helps in design.
  - Thanks [@YassLab](https://github.com/YassLab) team for helps in development.
  - cf. [Contributors - coderdojo-japan/coderdojo.jp - GitHub](https://github.com/coderdojo-japan/coderdojo.jp/graphs/contributors)
- **2016-now:** [coderdojo.jp](https://coderdojo.jp/) is sustainably maintained and developed by [YassLab Inc.](https://yasslab.jp/)
  - CoderDojo Japan has been incorporated and approved [@YassLab](https://github.com/YassLab) team as one of official partners for [tons of works](https://github.com/coderdojo-japan/coderdojo.jp/graphs/contributors).
  - From then on, [YassLab Inc.](https://yasslab.jp/) maintains and develops [coderdojo.jp](https://coderdojo.jp/) with official approval from CDJ board members. See [#References](#他開発に関する資料) and contributions (['coderdojo-japan.github.io'](https://github.com/coderdojo-japan/coderdojo-japan.github.io/graphs/contributors), ['web'](https://github.com/coderdojo-japan/web/graphs/contributors), and ['coderdojo.jp'](https://github.com/coderdojo-japan/coderdojo.jp/graphs/contributors)) for their continuous efforts on development.
  [![YassLab Logo](https://yasslab.jp/img/logos/800x200.png)](https://yasslab.jp/)

<br>

## 5. License

<details>
  <summary><strong>Check out each license</strong></summary>

This web application is developed with many other brilliant works!   
Check out the followings if you are interested in. :wink:

<h3>🎨 Libraries & Icons</h3>

The libraries like [RubyGems](https://rubygems.org/) used in this web application have their own licenses. Say, this website uses [Bootstrap](https://getbootstrap.jp/), created by Twitter licensed under the [MIT License](http://opensource.org/licenses/MIT).

Also this website uses icons created by [Font Awesome](http://fontawesome.io/), licensed under SIL OFL 1.1, and [Twemoji](https://github.com/twitter/twemoji), created by Twitter, licensed under the [MIT License](http://opensource.org/licenses/MIT).

Thanks for their great works to make this app published! :sparkling_heart: 

<h3>📝 Texts in Kata</h3>

The texts in [Kata page](http://coderdojo.jp/kata) are published under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed) license. But the texts do NOT include images, slides, and external websites. Please make sure to check their licenses and/or contact its owner before using them.

<h3>☯️ Logos & Photos</h3>

The images, such as logos and photos of [each dojo](http://coderdojo.jp/#dojos), are NOT published under the following License. Contact its owner, like the maintainer of linked external website, before using them. :relieved: 

<h3>💎 Codes, Scrivito gem, and Others</h3>

The source codes, such as HTML/CSS/JavaScript and Ruby codes not declared before, are published under **[The MIT License](https://opensource.org/licenses/MIT)**. Feel free to refer, copy, or share them. And contact `info@coderdojo.jp` if you find something unclear.

Also [Scrivito gem](https://rubygems.org/gems/scrivito) is publishd under LGPL-3.0, but the author allows us to put MIT license. 😆✨

> Sorry for the late reply, I wanted to confer with our team.   
> There is no conflict in the licenses and you are welcome to use the MIT license.  

So, this application's code can be simply forked, copied, and modified under the MIT License below! 🆗

<hr>

<a href='https://github.com/coderdojo-japan/coderdojo.jp/blob/main/LICENSE.md'>The MIT License</a>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

</details>

Copyright &copy; [一般社団法人 CoderDojo Japan](https://coderdojo.jp/about-coderdojo-japan)
