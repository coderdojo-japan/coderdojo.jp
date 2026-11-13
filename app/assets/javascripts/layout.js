// 全ページのレイアウトとヘッダーで動かす JS。CSP を強制する時に 'unsafe-inline' を外せるよう、
// ビューの <script> から移した（spec/requests/inline_script_spec.rb）。
// application.js は <head> で同期して読むので、ここで DOMContentLoaded に登録しておけば、
// 本文の末尾で読む DocSearch も定義された後に動く。application.js に async・defer を付けるとこの前提が崩れる。
// 外部の JS（Twemoji・DocSearch など）が広告ブロック等で読めなくても他の処理が止まらないよう、処理ごとに分ける

// どこをクリックしてもメニューを閉じる
document.addEventListener('click', function() {
  var nav = document.getElementById('header-nav-toggle');
  if (nav) { nav.classList.remove('in'); }
});

// 検索アイコンを押したら、検索欄に入力できるようにする
document.addEventListener('DOMContentLoaded', function() {
  var searchCheckbox = document.querySelector('.search-checkbox');
  var searchbox      = document.getElementById('searchbox');
  if (searchCheckbox && searchbox) {
    searchCheckbox.addEventListener('click', function() { searchbox.focus(); });
  }
});

// Twemoji parse
document.addEventListener('DOMContentLoaded', function() {
  if (window.twemoji) { twemoji.parse(document.body); }
});

// DocSearch (v2): https://docsearch.algolia.com/
// 検索専用の API キーは、ヘッダーの #searchbox の data 属性で渡す
document.addEventListener('DOMContentLoaded', function() {
  var searchbox = document.getElementById('searchbox');
  if (!searchbox || !window.docsearch) { return; }

  docsearch({
    appId:  searchbox.dataset.algoliaAppId,
    apiKey: searchbox.dataset.algoliaApiKey,
    indexName:     'coderdojo',
    inputSelector: '#searchbox',
    debug: false // Set true if you want to inspect the dropdown
  });
});

// Facebook SDK
document.addEventListener('DOMContentLoaded', function() {
  (function(d, s, id) {
    var js, fjs = d.getElementsByTagName(s)[0];
    if (d.getElementById(id)) return;
    js = d.createElement(s); js.id = id;
    js.src = "//connect.facebook.net/ja_JP/sdk.js#xfbml=1&version=v2.8&appId=805184859580207";
    fjs.parentNode.insertBefore(js, fjs);
  }(document, 'script', 'facebook-jssdk'));
});

// Google Analytics
document.addEventListener('DOMContentLoaded', function() {
  (function(i,s,o,g,r,a,m){
    i['GoogleAnalyticsObject']=r;
    i[r]=i[r]||function(){
      (i[r].q=i[r].q||[]).push(arguments)
    },
    i[r].l=1*new Date();
    a=s.createElement(o), m=s.getElementsByTagName(o)[0];
    a.async=1; a.src=g; m.parentNode.insertBefore(a,m)
  })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-62337761-1', 'auto');
  ga('send',   'pageview');
});
