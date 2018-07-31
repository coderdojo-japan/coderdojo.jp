[![Cover](https://raw.githubusercontent.com/coderdojo-japan/coderdojo.jp/master/public/cover.png)](https://coderdojo.jp/)

# CoderDojo Japan

[![Build Status](https://travis-ci.org/coderdojo-japan/coderdojo.jp.svg?branch=master)](https://travis-ci.org/coderdojo-japan/coderdojo.jp#)

一般社団法人 CoderDojo Japan の公式サイトです。[Ruby on Rails](http://rubyonrails.org/) で実装されています。

## 開発に参加するには?

coderdojo.jp の開発には以下のいずれかの方法で参加できます。Dojo 情報の修正やドキュメントの追加・執筆であれば、ブラウザだけで参加できます。

1. Dojo 情報やドキュメントの修正 (ブラウザのみ)
2. [CoderDojo Kata](https://coderdojo.jp/kata) の執筆・編集 (ブラウザ + ユーザー登録)
3. 新機能の開発やデザインの改善 (各種ツールのセットアップ)

新機能の開発やデザインの改善には開発環境が必要ですが、ちょっとした文言の追記・修正であればブラウザだけで参加できるようになっているのが特徴です ✨📝💨 
それぞれの参加方法は次のとおりです。

### 1. Dojo 情報やドキュメントの修正

Dojo 情報は以下の手順で簡単に修正できます。

1. [db/dojos.yaml](https://github.com/coderdojo-japan/coderdojo.jp/blob/master/db/dojos.yaml) を開く
2. 画面右にある ✎ アイコン (Fork this project and edit this file) をクリックする
3. 気になる箇所を修正し、修正内容にタイトルと説明文を付け、Propose file change をクリックする
4. 修正内容を確認し、問題なければ Create pull request をクリックする

以上で完了です。提案された修正はメンテナーによってチェックされ、問題なければ提案された内容が反映されます。もし問題があってもメンテナー側で気付いて修正できるので、まずはお気軽に提案してみてください ;)

https://coderdojo.jp/docs にあるドキュメントの編集方法も同様です。[db/docs](https://github.com/coderdojo-japan/coderdojo.jp/tree/master/db/docs)ディレクトリをブラウザで開き、修正したいファイルをクリックして、修正内容を提案してください。同ディレクトページの右上にある `Create new file` ボタンをクリックすると、新しいドキュメントの追記を提案することもできます。

### 2. CoderDojo Kata の執筆・編集

[Kata](https://coderdojo.jp/kata) や [Sotechsha](https://coderdojo.jp/sotechsha) などのいくつかのページは、[Scrivito](https://scrivito.com/) と呼ばれる CMS (コンテンツ管理サービス) で運営しています。背景や使用例については次のスライドをご参照ください。

CoderDojo を支える Rails CMS の活用事例 - Speaker Deck   
https://speakerdeck.com/yasulab/case-study-rails-cms-for-coderdojo

編集方法については下記の手順書をご参考にしてください。

記事の編集手順書 - Google Drive   
http://bit.ly/coderdojo-kata-edit


編集用のユーザーアカウントを発行したい場合は [@yasulab](https://twitter.com/yasulab) までお問い合わせください。

### 3. 新機能の開発やデザインの改善

本サイトでは以下の技術が使われているので、それぞれのツールをセットアップします。

- [Ruby](https://www.ruby-lang.org/ja/)
- [Ruby on Rails](http://rubyonrails.org/)
- [PostgreSQL](https://www.postgresql.jp/)
- [Scrivito](https://scrivito.com/) (Kataページ開発時に必要)

#### セットアップ方法

1. 本リポジトリを fork 後、clone します
1. ターミナルから `$ bin/setup` を実行します
1. `$ rails server` でローカルサーバーを立ち上げます
1. ブラウザから [localhost:3000](http://localhost:3000) にアクセスします
1. [coderdojo.jp](https://coderdojo.jp/) と同様のサイトが表示できれば完了です

#### Dockerを利用したセットアップ方法

Dockerを利用する場合は上記ツールをインストールする必要はありません。

その代わり、Dockerをインストールする必要があります。

- [Docker](https://www.docker.com/community-edition)

1. 本リポジトリを fork 後、clone します
1. `.env.sample` をコピーして `.env` にリネームします
1. ターミナルから `$ docker-compose up` を実行します
1. ターミナルから `$ docker-compose exec rails bin/setup` を実行します
1. ブラウザから [localhost:3000](http://localhost:3000) にアクセスします
1. [coderdojo.jp](https://coderdojo.jp/) と同様のサイトが表示できれば完了です

#### Development with Scrivito

Some pages require [Scrivito](https://scrivito.com/), Professional Cloud-Based Rails CMS, such as:

- `/kata`
- `/news/*`
- `/sotechsha/*`

CMS enables wider people to contribute to editing contents,   
but on the other hand, this requires Scrivito API Keys for    
engineers to join developing Scrivito-used pages like above.

If interested in developing them, contact [@yasulab](https://github.com/yasulab) to
get production keys (`SCRIVITO_TENANT` and `SCRIVITO_API_KEY`).

### 他、開発に関する資料

開発に関する資料は [/docs](https://github.com/coderdojo-japan/coderdojo.jp/tree/master/docs) や下記サイトにまとめてあります。必要に応じて適宜ご参照ください。

- [新規 Dojo の追加方法 - GitHub](https://github.com/coderdojo-japan/coderdojo.jp/blob/master/docs/how-to-add-dojo.md)
- [CoderDojo Japan の各種機能と実装について【2017年版】 - Qiita](https://qiita.com/yasulab/items/1d12e6b295c0a9e577f1)
- [CoderDojo Japan のバックエンドを更新しました (2016年)](https://coderdojo.jp/news/2016/12/12/new-backend)

## Contributors

Initially designed by [@cognitom](https://github.com/cognitom) in 2015,   
being developed by [YassLab Inc.](https://yasslab.jp/) since 2016, and   
had been migrated to [CoderDojo Japan](http://github.com/coderdojo-japan) organization in 2017.

[![YassLab Logo](https://yasslab.jp/img/logo_800x200.jpg)](https://yasslab.jp/)

## License

Although [Scrivito gem](https://rubygems.org/gems/scrivito) is publishd under LGPL-3.0, the author allows us to put MIT license. 😆✨

> Sorry for the late reply, I wanted to confer with our team.   
> There is no conflict in the licenses and you are welcome to use the MIT license.  

So, this application can be used and modified under the MIT License! 🆗

### The MIT License (MIT)

Copyright &copy; 2012-2018 [CoderDojo Japan](https://coderdojo.jp/)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### About ICON

The icons used in the website are created by [Font Awesome](http://fontawesome.io/), licensed under SIL OFL 1.1.
