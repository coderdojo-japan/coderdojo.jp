# 🛠 記事：CoderDojo Japan のバックエンド刷新

<p class="text-center"><small>本記事は2016年12月12日に公開した記事を一部改訂したアーカイブ版です。</small></p>

2016年の CoderDojo Advent Calendar で公開した、coderdojo.jp のバックエンド刷新に関する技術記事です。

-----

[CoderDojo Advent Calendar](http://www.adventar.org/calendars/1619) 12日目、coderdojo.jp の裏側をリニューアルした話です。 (執筆: [@yasulab](https://twitter.com/yasulab))

## 🗣 動画版

<div class='home-point-video'>
  <iframe loading='lazy' src="https://www.youtube.com/embed/B96S3Z1zsq4" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

<br>

## 📜 スライド版

<script async class="speakerdeck-embed" data-id="1d622012901b4f6197ccee4e98d2734f" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

<br>


## 📝 記事版

<br>

トップページ ([https://coderdojo.jp/](https://coderdojo.jp/)) が変わっていないので気づきにくいですが、**実は coderdojo.jp の裏側 (バックエンド) が新しくなりました! 🎊**

裏側が新しくなったので、ついでにブログ記事も coderdojo.jp で書いてみようかなと思い立ち、ササっと組み立ててこちらから公開しています。まだデザインやSNS周りが出来ていないので質素なページではありますが、ブラウザからブログ記事を執筆・公開するぐらいならサっとできてしまいます! 📝✨(どうやっているかは後述)

本記事はブラウザからの投稿テストも兼ねつつ、どんな背景があって、どういう風に裏側が置き換わって、どういうことができるようになったのかを書いていきますね😆

### 🔙 これまでの coderdojo.jp の変遷

初めて知る方もいるかもしれませんが、これまでの coderdojo.jp ([coderdojo-japan/web](https://github.com/coderdojo-japan/web)) は CoderDojo Tokyo (現: CoderDojo 下北沢) の河村さんが作った [coderdojo-tokyo/web](https://github.com/coderdojo-tokyo/web) をアレンジして作られています。裏側はどちらも同じで、Parse と呼ばれる MBaaS を使っています。しかしこの Parse というサービス、なんと[2017年1月28日に閉鎖](https://en.wikipedia.org/wiki/Parse_(platform))してしまうんですね😱 したがって、閉鎖するまでに裏側を別のサービスに移行する必要がありました💦

また、使われている技術がやや高度なこともあってか (あるいは周知不足もあってか)、以前からオープンソースとして公開されているものの、この coderdojo.jp の開発・運用は @yasulab がほぼ１人で行っていました (参考: [当時のコミット状況](https://github.com/coderdojo-japan/web/graphs/contributors))。開発は好きなので自分が進める分には問題ありませんが、やはりエンジニアではなくとも気軽に編集・更新できる仕組みがあるともっと良さそうです 🆙

他にも同様の課題として、CoderDojo Japan に掲載している Dojo 情報を編集したいときは毎回 @yasulab に連絡する必要がある、という仕組み上の課題があります。Dojo の数が 20~30 ぐらいの時はこれでもまだ機能していますが、現在のような規模にまで増えていくと、それぞれの Dojo がそれぞれの情報を編集できた方が良さそうですよね 😅

### 🚜 移行は必須。安定した運用を重視

**「移行は必須。ただせっかくなら、もっとうまく開発・管理・運用できるようにしたい」**という思いは2016年の初頭から感じていて、もっといろんな人が気軽にできる編集や投稿できるものだといいなぁ、とぼんやりと考えていました👀💭

要件をまとめると、次の３つになります ✅

1. ブログ機能なども実装したいし、拡張性・柔軟性も保持したい
   - 作ってみたい機能の例: [GitHub Issues](https://github.com/coderdojo-japan/coderdojo.jp/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
2. 何かあっても大丈夫なように、少なくとも @yasulab が開発・メンテできる
   - => Ruby/Rails + Heroku
3. Ruby/Rails を知らない人でもブラウザからポチポチ編集できるとベスト 💯
   - => Rails + CMS ... ??? 🤔

上記の `1.` と `2.` については Ruby/Rails + Heroku で十分そうです。また、これまで開発・運営は [@yasulab](https://twitter.com/yasulab) が対応していたので、技術面、運用面ともに問題になることはなさそうです。でも `3.` は...? 

### ☁️  Cloud-Based Rails CMS: Scrivito

そんな時にふと舞い降りた話が、Scrivito です。

> Cloud-Based Rails CMS
> [https://scrivito.com/](https://scrivito.com/)

次のデモ動画を見てもらうと分かりやすいのですが、Ruby/Rails を Cloud-Based CMS として活用できるようにするプロ向けの有料サービスです。

<div class='home-point-video'>
  <iframe loading='lazy' src="https://www.youtube.com/embed/gsjt5ykGPgA" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

2016年にリリースされたばかりのサービスですが、豊富なプラグイン機能や開発者と直接話せるサポート体制もあり、順調に[採用事例も増えている](https://scrivito.com/customers)ようです。ただ、これだけ充実していることもあってか、[お値段もそれなり](https://scrivito.com/pricing)にします 💸

> Large: 　$499/month
> Medium: $169/month
> Basic:　  $19/month

なんとかして使えるといいなぁと思っていた頃、なんと Product Owner (PO) の Thomas さんが来日しているとの話が...👂 ダメ元で尋ねてみた結果、(本当は1時間ほどの英語での打ち合わせでしたが要約すると) 次のような話になりました😸

> - _Thomas「日本ではまだ利用例がなくて、利用事例は欲しいんだよねぇ🤔」_
> - _yasulab「CoderDojoはOSSコミュニティなので、丸ごと公開できますよ!」_
> - _Thomas「おぉ、それいいね! 👍」_
> - _Thomas「実は**ドイツの開発チームでは CoderDojo もやってる**んだよね。CoderDojo ならぜひ!」_
> - _yasulab「ドイツにも CoderDojo 結構ありますもんね〜😸」_
> - _Thomas「じゃあ本社 (ドイツ) に戻ったら相談して、問題なければ永久無料アカウントを配布するね🎫」_
> - _yasulab「ぜひぜひ! お返事お待ちしております! 😆」_

まさかこんなに話がすんなり進むとは思いませんでしたが、後日 **CoderDojo Japan 向けに永久無料アカウントを無事発行**してもらうことになり、Scrivito を無料で使えるようになりました。その後、休日や仕事の合間で少しずつ載せ替えていき、現在に至ります。

そして今こうしてバックエンドが新しくなったので、既存の状態 ([トップページ](/)) も保持しつつ、新しい機能を追加しやすくなり、かつ、技術に詳しくない人でもブラウザ上から開発に参加できるようになりました! 🆕✨

### 🎁 今できること、今後できること

バックエンドが刷新され、開発面・運用面ともに改善されたので、今後は様々な機能をリリースしていけそうです 🚀🆕

既に実装済みのアイデアも含め、現時点では次のような構想を考えています 👀💭✨

- [x] フロント側の再現 (http://coderdojojp/)
  - cf. GitHub Issues #26
- [x] ブログ機能の実装 (本記事自体もこのブログ機能で書かれています📝 )
2016年12月発売のCoderDojo Japan公式本の解説記事なども、この機能で執筆・公開する予定です🔜
   - cf. [GitHub Issues #20](https://github.com/coderdojo-japan/coderdojo.jp/issues/20)
- [ ] 各種イベント管理サービスのAPIを叩いて、統計情報を集計したい
   - cf. [GitHub Issues #12](https://github.com/coderdojo-japan/coderdojo.jp/issues/12)
- [ ] Dojoの募集ボード 📋
   - cf. [GitHub Issues #13](https://github.com/coderdojo-japan/coderdojo.jp/issues/13)
- [ ] トップページに CoderDojo Map を埋め込む
   - cf. [GitHub Issues #32](https://github.com/coderdojo-japan/coderdojo.jp/issues/32)

今回のバックエンド刷新に伴い、スピーディーに実装を進めて行ける環境が整っているので、何か面白そうなアイデアがあれば他にも作ってみようと考えています🔧✨ もちろん GitHub 上からも公開しているので、欲しい機能があれば Issue や PR などでリクエストしてもらうことも可能です😸👌

### 🔧 他、やったこと

上記の他にも、細々とした更新があります。特にドメイン周りも複数人で管理できるようにしたり、**下北沢オープンソースCafe**からの支援をいただけた部分が大きいです。主な更新は次のとおりです。

- ✅ coderdojo.jp のネームサーバーを Gehirn DNS に変更
  - 管理者を複数用意して、権限を持った人が各自で扱えるようになりました 👥
- ✅ coderdojo.jp ドメイン代は下北沢オープンソースCafeがスポンサーに! 💰
  - ただDNS代も費用なので、ここも何かできたらいいかもしれない? 🤔
  - 「もしかしたら Dozens が支援してくれるかもしれない...?」 (OSS Cafe店長談)
  - こちらについては、後日僕の方で直接伺ってみようかなと思います 👀
- ✅ Apex Alias を使ってルートドメインに変更
  - `www.coderdojo.jp` →` coderdojo.jp`
  - ※ ただしcacheにヒットするとリダイレクトループが発生してしまうため、 Parse も平行して運用
  - cf. [Do not redirect if all caches refer to Parse - GitHub](https://github.com/coderdojo-japan/web/commit/5f739cf2939197176de1fd2c9ada09921e8d680f)
- ✅ **新 coderdojo.jp リポジトリのオープンソース化**
  - [coderdojo-japan/coderdojo.jp - GitHub](https://github.com/coderdojo-japan/coderdojo.jp)
  - 万が一の場合すぐに Private にロールバックできるよう、開発チームである [YassLab Organization](https://github.com/yasslab) で管理していましたが、しばらく運用してみて問題なさそうだったので、2017年に [CoderDojo Japan Organization](https://github.com/coderdojo-japan) に移管しました 🚜💨 ([GitHub Issue #88](https://github.com/coderdojo-japan/coderdojo.jp/issues/88))

### 🔖 まとめ

- ✅ Parseシャットダウン後も存続できるようになった
- ✅ Ruby/Railsを知らなくても編集できるようになった
- ✅ [coderdojo.jp](https://coderdojo.jp/) に便利機能を追加できる環境が整った

とまぁ、こんな感じでバックエンドが無事に移行できました! 

色々とできることの幅も広がったので、個人的にも開発がもっと楽しくなりそうです😆✨ 何か気になることがあれば [@yasulab](https://twitter.com/yasulab) までお気軽にお問い合わせください 😸

[CoderDojo Advent Calendar](http://www.adventar.org/calendars/1619) もまだまだ続きますので、引き続きお楽しみください 😉

執筆: Yohei Yasukawa

---

## 💖 謝辞

今回の coderdojo.jp のバックエンド刷新は [YassLab 社](https://yasslab.jp/ja/)の以下の方々に協力してもらいました。この場を借りて御礼申し上げます。ありがとうございます!! 😆✨

- Naoya Matayoshi ([GitHub](https://github.com/nanophate))
- Tomoko Hirata ([GitHub](https://github.com/tomoko523))

[![YassLab 株式会社](/partners/yasslab.png)](https://yasslab.jp/ja/)

<br>

## 📖 合わせて読みたい ✨

- [📚 coderdojo.jp 開発マガジン - note](https://note.com/yasslab/m/m7ed183f728c3)
- [💎 RubyWorld Conference 2019 で coderdojo.jp 開発事例を講演 - note](https://note.com/yasslab/n/n9439edba53bb)
- [☯️ 2019年 coderdojo.jp 開発ハイライト - note](https://note.com/yasslab/n/n572a17f68842)
- [☯️ 大阪Ruby会議02で coderdojo.jp 開発事例を発表します - yasslab.jp](https://yasslab.jp/ja/news/cfp-accepted-at-osaka-rubykaigi02)
- [🛠 DojoCast を Jekyll から Rails に移行しました - yasslab.jp](https://yasslab.jp/ja/news/migrate-dojocast-from-jekyll-to-rails)
- [☯️ 開発目線で見る最近の CoderDojo Japan 2018 - yasslab.jp](https://yasslab.jp/ja/news/coderdojo-japan-2018)
- [☯️ CoderDojo Japan の各種機能と実装について【2017年版】 - Qiita](https://qiita.com/yasulab/items/1d12e6b295c0a9e577f1)
