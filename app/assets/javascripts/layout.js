// 全ページのレイアウトとヘッダーで動かす JS。CSP を強制する時に 'unsafe-inline' を外せるよう、
// ビューの <script> から移した（spec/requests/inline_script_spec.rb）。
// application.js は <head> で同期して読むので、ここで DOMContentLoaded に登録しておけば、
// 本文の末尾で読む DocSearch も定義された後に動く。application.js に async・defer を付けるとこの前提が崩れる。
// 外部の JS（Twemoji・DocSearch など）が広告ブロック等で読めなくても他の処理が止まらないよう、処理ごとに分ける

// 開閉（スマホのヘッダーのメニュー・スマホの道場一覧）。Bootstrap 3 の collapse.js の代わりに、
// data-toggle="collapse" を押したら、data-target か href の要素の in を付け外しする（HTML と CSS は Bootstrap 3 のまま）。
// ヘッダーのメニューは、メニューの開閉ボタン以外のどこをクリックしても閉じる
document.addEventListener('click', function(event) {
  var trigger    = event.target.closest('[data-toggle="collapse"]');
  var navTrigger = document.querySelector('[data-target="#header-nav-toggle"]');
  var nav        = document.getElementById('header-nav-toggle');

  if (trigger !== navTrigger && nav && nav.classList.contains('in')) { toggleCollapse(navTrigger); }
  if (!trigger) { return; }

  event.preventDefault();
  toggleCollapse(trigger);
});

function toggleCollapse(trigger) {
  var target = document.querySelector(trigger.dataset.target || trigger.getAttribute('href'));
  if (!target) { return; }

  var open = target.classList.toggle('in');
  target.setAttribute('aria-expanded', open);
  trigger.setAttribute('aria-expanded', open);
  trigger.classList.toggle('collapsed', !open);

  // 道場一覧の都道府県の矢印: 開いたら下向き、閉じたら右向き
  var arrow = trigger.querySelector('.fa-chevron-right, .fa-chevron-down');
  if (arrow) {
    arrow.classList.toggle('fa-chevron-right', !open);
    arrow.classList.toggle('fa-chevron-down',  open);
  }
}

// Twemoji parse
document.addEventListener('DOMContentLoaded', function() {
  if (window.twemoji) { twemoji.parse(document.body); }
});

// DocSearch (v3): https://docsearch.algolia.com/docs/DocSearch-v3
// 検索専用の API キーは、ヘッダーの #docsearch の data 属性で渡す。
// v3 のボタンは隠した #docsearch に描き、ヘッダーの「検索で探す」を押したら、そのボタンを押して検索の画面を開く
document.addEventListener('DOMContentLoaded', function() {
  var container = document.getElementById('docsearch');
  var button    = document.getElementById('search-button');
  if (!container || !button || !window.docsearch) { return; }

  docsearch({
    container: container,
    appId:     container.dataset.algoliaAppId,
    apiKey:    container.dataset.algoliaApiKey,
    indexName: 'coderdojo',
    placeholder: '例: コンテスト、教材',
    translations: {
      modal: {
        searchBox:   { resetButtonTitle: '消す', cancelButtonText: '閉じる' },
        startScreen: { recentSearchesTitle: '最近の検索', noRecentSearchesText: '最近の検索はありません',
                       saveRecentSearchButtonTitle: '保存する', removeRecentSearchButtonTitle: '履歴から消す',
                       favoriteSearchesTitle: '保存した検索', removeFavoriteSearchButtonTitle: '保存から消す' },
        errorScreen: { titleText: '結果を取得できませんでした', helpText: 'ネットワークの接続を確かめてください' },
        footer:      { selectText: '選ぶ', navigateText: '移動', closeText: '閉じる', searchByText: '検索:' },
        noResultsScreen: { noResultsText: '見つかりませんでした:', suggestedQueryText: '次の言葉で探してみてください:' }
      }
    }
  });
  button.addEventListener('click', function() {
    var docsearchButton = container.querySelector('.DocSearch-Button');
    if (docsearchButton) { docsearchButton.click(); }
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

// 送信ボタンの二重押しを防ぐ。f.submit が付ける data-disable-with の文言に替えて押せなくする
// （jquery_ujs が受け持っていた分。押したボタンの値が送られるよう、無効にするのは送信が始まった後にする）
document.addEventListener('submit', function(event) {
  var buttons = event.target.querySelectorAll('input[data-disable-with], button[data-disable-with]');
  setTimeout(function() {
    buttons.forEach(function(button) {
      button.dataset.enableWith = button.tagName === 'INPUT' ? button.value : button.textContent;
      setButtonText(button, button.dataset.disableWith);
      button.disabled = true;
    });
  }, 0);
});

// 「戻る」でキャッシュから表示した時は、無効にしたボタンを元の文言で押せるように戻す。
// 初めて開いた時の pageshow は load の後に届くので、読み込み中に押したボタンを戻さないよう persisted の時だけにする
window.addEventListener('pageshow', function(event) {
  if (!event.persisted) { return; }
  document.querySelectorAll('[data-enable-with]').forEach(function(button) {
    setButtonText(button, button.dataset.enableWith);
    button.disabled = false;
    delete button.dataset.enableWith;
  });
});

function setButtonText(button, text) {
  if (button.tagName === 'INPUT') { button.value = text; } else { button.textContent = text; }
}
