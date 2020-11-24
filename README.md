[![カバー画像](https://raw.githubusercontent.com/coderdojo-japan/coderdojo.jp/master/public/cover_rounded.png)](https://coderdojo.jp/)

# CoderDojo Japan

[![Build Status](https://travis-ci.org/coderdojo-japan/coderdojo.jp.svg?branch=master)](https://travis-ci.org/coderdojo-japan/coderdojo.jp)

一般社団法人 CoderDojo Japan の公式サイトです。[Ruby on Rails](http://rubyonrails.org/) で実装されています。

## 開発に参加するには?

coderdojo.jp の開発には以下のいずれかの方法で参加できます。Dojo 情報の修正やドキュメントの追加・執筆であれば、ブラウザだけで参加できます。

1. Dojo 情報やドキュメントなどの修正 ([» 詳細](#1-dojo-情報の更新))
   - 必要なもの: ブラウザ + GitHub アカウント
2. [CoderDojo Kata](https://coderdojo.jp/kata) の執筆・編集 ([» 詳細](#2-coderdojo-kata-の執筆編集))
   - 必要なもの: ブラウザ + coderdojo.jp アカウント 
3. 新機能の開発やデザインの改善 ([» 詳細](#3-新機能の開発やデザインの改善))
   - 必要なもの: 各種開発環境のセットアップ (開発者向け)

新機能の開発やデザインの改善には開発環境が必要ですが、ちょっとした文言の追記・修正であればブラウザだけで参加できるようになっているのが特徴です ✨📝💨 

それぞれの参加方法は次のとおりです。

## 1. Dojo 情報の更新

Dojo 情報は次の手順で簡単に更新できます。

1. [db/dojos.yaml](https://github.com/coderdojo-japan/coderdojo.jp/blob/master/db/dojos.yaml) を開く
2. 画面右にある ✎ アイコン (Fork this project and edit this file) をクリックする
3. 気になる箇所を修正し、修正内容にタイトルと説明文を付け、Propose file change をクリックする
4. 修正内容を確認し、問題なければ Create pull request をクリックする
   - 画像を追加したい場合は Pull Request のコメント欄に添付して頂けると助かります :relieved: ([対応例](https://github.com/coderdojo-japan/coderdojo.jp/pull/763))

以上で完了です。提案された修正はメンテナーによってチェックされ、問題なければ提案された内容が反映されます。もし問題があってもメンテナー側で気付いて修正できるので、まずはお気軽に提案してみてください ;)

https://coderdojo.jp/docs にあるドキュメントの編集方法も同様です。[db/docs](https://github.com/coderdojo-japan/coderdojo.jp/tree/master/db/docs)ディレクトリをブラウザで開き、修正したいファイルをクリックして、修正内容を提案してください。同ディレクトページの右上にある `Create new file` ボタンをクリックすると、新しいドキュメントの追記を提案することもできます。

## 2. CoderDojo Kata の執筆・編集

[Kata](https://coderdojo.jp/kata) や [Sotechsha](https://coderdojo.jp/sotechsha) などのいくつかのページは、[Scrivito](https://scrivito.com/) と呼ばれる CMS (コンテンツ管理サービス) で運営しています。

編集方法は下記の手順書をご参照してください。

:scroll: Kata の編集方法 - esa   
https://esa-pages.io/p/sharing/7542/posts/213/bc0e68f705b7298ae5e0.html

Kata の編集には CoderDojo Japan のアカウントが必要です。アカウントを発行したい場合は [@yasulab](https://twitter.com/yasulab) までご連絡ください。

CMS を利用している背景や技術仕様などについては次のスライド資料にまとめています。もし興味あればお気軽にご参照ください :wink:

:scroll: CoderDojo を支える Rails CMS の活用事例 - Speaker Deck   
https://speakerdeck.com/yasulab/case-study-rails-cms-for-coderdojo



## 3. 新機能の開発やデザインの改善

本サイトでは以下の技術が使われているので、それぞれのツールをセットアップします。

- [Ruby](https://www.ruby-lang.org/ja/)
- [Ruby on Rails](http://rubyonrails.org/)
- [PostgreSQL](https://www.postgresql.jp/)
- [Scrivito](https://scrivito.com/) (Kataページ開発時に必要)

### セットアップ方法

1. 本リポジトリを fork 後、clone します
1. ターミナルから `$ bin/setup` を実行します
1. `$ rails server` でローカルサーバーを立ち上げます
1. ブラウザから [localhost:3000](http://localhost:3000) にアクセスします
1. [coderdojo.jp](https://coderdojo.jp/) と同様のサイトが表示できれば完了です

### Dockerを利用したセットアップ方法

Dockerを利用する場合は上記ツールをインストールする必要はありません。

その代わり、Dockerをインストールする必要があります。

- [Docker](https://www.docker.com/community-edition)

1. 本リポジトリを fork 後、clone します
1. `.env.sample` をコピーして `.env` にリネームします
1. ターミナルから `$ docker-compose up` を実行します
1. ターミナルから `$ docker-compose exec rails bin/setup` を実行します
1. ブラウザから [localhost:3000](http://localhost:3000) にアクセスします
1. [coderdojo.jp](https://coderdojo.jp/) と同様のサイトが表示できれば完了です

### Development with Scrivito

Some pages require [Scrivito](https://scrivito.com/), Professional Cloud-Based Rails CMS, such as:

- `/kata`
- ~~/news/*~~ (Outdated)
- `/sotechsha/*`

CMS enables wider people to contribute to editing contents, but on the other hand, this requires Scrivito API Keys for engineers to join developing Scrivito-used pages like above.

We use `SCRIVITO_TENANT` and `SCRIVITO_API_KEY` keys in production, but they are not required in development. If you find any problem that needs them report it to [GitHub Issues](https://github.com/coderdojo-japan/coderdojo.jp/issues).

## 他、開発に関する資料

開発に関する資料は [/docs](https://github.com/coderdojo-japan/coderdojo.jp/tree/master/docs) や下記サイトにまとめてあります (最新順)。必要に応じて適宜ご参照ください。

- [子どものためのプログラミング道場『CoderDojo』の Ruby/Rails 活用事例](https://speakerdeck.com/yasulab/case-study-of-how-coderdojo-japan-uses-ruby)
- [DojoCast を Jekyll から Rails に移行しました](https://yasslab.jp/ja/posts/migrate-dojocast-from-jekyll-to-rails)
- [2019年 coderdojo.jp 開発ハイライト](https://note.com/yasslab/n/n572a17f68842)
- [開発目線で見る最近の CoderDojo Japan 2018](https://yasslab.jp/ja/posts/coderdojo-japan-2018)
- [新規 Dojo の追加方法 - GitHub](https://github.com/coderdojo-japan/coderdojo.jp/blob/master/docs/how-to-add-dojo.md)
- [CoderDojo を支える Rails CMS の活用事例 - Speaker Deck](https://speakerdeck.com/yasulab/case-study-rails-cms-for-coderdojo)
- [CoderDojo Japan の各種機能と実装について【2017年版】 - Qiita](https://qiita.com/yasulab/items/1d12e6b295c0a9e577f1)
- [CoderDojo Japan のバックエンドを刷新しました【2016年】](https://coderdojo.jp/docs/post-backend-update-history)

### API (開発中)

現在提供中の API です。今後仕様が変更される可能性もあるため、    
本番環境で利用したい場合は yohei@coderdojo.jp までご連絡ください

- Podcast RSS: https://coderdojo.jp/podcasts.rss
- Sitemap XML: https://coderdojo.jp/sitemap.xml
- 近日開催の道場: https://coderdojo.jp/events.json

## Development History & Contributors

- **2012:** CoderDojo Japan started in [Facebook Group](https://www.facebook.com/groups/coderdojo.jp/about/)
- **2014:** coderdojo.jp was launched as ['coderdojo-japan.github.io'](https://github.com/coderdojo-japan/coderdojo-japan.github.io/graphs/contributors)
- **2015:** coderdojo.jp was migrated to Parse as ['web'](https://github.com/coderdojo-japan/web/graphs/contributors)
- **2016:** [Parse shutdown](https://speakerdeck.com/yasulab/case-study-rails-cms-for-coderdojo?slide=26). [@yasulab](https://github.com/yasulab) migrated ['coderdojo.jp'](https://github.com/coderdojo-japan/coderdojo.jp/graphs/contributors) from Parse to Ruby on Rails
  - Thanks [@cognitom](https://github.com/cognitom) for helps in design.
  - Thanks [@YassLab](https://github.com/YassLab) team for helps in development.
  - cf. [Contributors - coderdojo-japan/coderdojo.jp - GitHub](https://github.com/coderdojo-japan/coderdojo.jp/graphs/contributors)
- **2016-now:** [coderdojo.jp](https://coderdojo.jp/) is sustainably maintained and developed by [YassLab Inc.](https://yasslab.jp/)
  - CoderDojo Japan has been incorporated and approves [@YassLab](https://github.com/YassLab) team as one of official partners for [tons of works](https://github.com/coderdojo-japan/coderdojo.jp/graphs/contributors).
  - From then on, [YassLab Inc.](https://yasslab.jp/) maintains and develops [coderdojo.jp](https://coderdojo.jp/) with official approval from CDJ board members. See [#References](#他開発に関する資料) and contributions (['coderdojo-japan.github.io'](https://github.com/coderdojo-japan/coderdojo-japan.github.io/graphs/contributors), ['web'](https://github.com/coderdojo-japan/web/graphs/contributors), and ['coderdojo.jp'](https://github.com/coderdojo-japan/coderdojo.jp/graphs/contributors)) for their continuous efforts on development.
  [![YassLab Logo](https://yasslab.jp/img/logos/800x200.png)](https://yasslab.jp/)


## License

This web application is developed with many other brilliant works!   
Check out the followings if you are interested in. :wink:

### About Scrivito

Although [Scrivito gem](https://rubygems.org/gems/scrivito) is publishd under LGPL-3.0, the author allows us to put MIT license. 😆✨

> Sorry for the late reply, I wanted to confer with our team.   
> There is no conflict in the licenses and you are welcome to use the MIT license.  

So, this application can be used and modified under the MIT License! 🆗

### About Libraries and Icons

The libraries like [RubyGems](https://rubygems.org/) used in this web application have their own licenses. Say, this website uses [Bootstrap](https://getbootstrap.jp/), created by Twitter licensed under the [MIT License](http://opensource.org/licenses/MIT).

Also this website uses icons created by [Font Awesome](http://fontawesome.io/), licensed under SIL OFL 1.1, and [Twemoji](https://github.com/twitter/twemoji), created by Twitter, licensed under the [MIT License](http://opensource.org/licenses/MIT).

Thanks for their great works to make this app published! :sparkling_heart: 

### About Texts in Kata

The texts in [Kata page](http://coderdojo.jp/kata) are published under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed) license. But the texts do NOT include images, slides, and external websites. Please make sure to check their licenses and/or contact its owner before using them.

### About Logos and Photos

The images, such as logos and photos of [each dojo](http://coderdojo.jp/#dojos), are NOT published under the following License. Contact its owner, like the maintainer of linked external website, before using them. :relieved: 

### About Source Codes

The source codes, such as HTML/CSS/JavaScript and Ruby not declared before, are published under **[The MIT License (MIT)](https://opensource.org/licenses/MIT)**. Feel free to refer, copy, or share them. And contact `info@coderdojo.jp` if you find something unclear.

Copyright &copy; 2012-2020 [CoderDojo Japan Association](https://coderdojo.jp/)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
