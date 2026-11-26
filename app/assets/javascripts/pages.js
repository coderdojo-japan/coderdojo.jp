// 特定のページで動かす JS。CSP を強制する時に 'unsafe-inline' を外せるよう、
// ビューの <script> と onchange 属性から移した（spec/requests/inline_script_spec.rb）。
// 全ページで読むので、どの処理も対象の要素が無ければ何もしない

// 道場一覧（/dojos）: 対象期間を選んだら、その年の表へ移る
document.addEventListener('change', function(event) {
  var select = event.target;
  if (!select.matches || !select.matches('select[data-year-filter]')) { return; }

  var path = select.dataset.yearFilter;
  window.location.href = select.value ? path + '?year=' + select.value + '#table' : path + '#table';
});

// トップのお問い合わせフォーム（Wufoo）。フォームの名前は div の data 属性で渡す
document.addEventListener('DOMContentLoaded', function() {
  var box = document.querySelector('[data-wufoo-form]');
  if (!box) { return; }

  var formHash = box.dataset.wufooForm;
  var script   = document.createElement('script');
  script.async = true;
  script.src   = 'https://www.wufoo.com/scripts/embed/form.js';
  script.onload = function() {
    try {
      // 以前の埋め込みのコードと同じく、フォームの名前の変数に入れておく
      window[formHash] = new WufooForm();
      window[formHash].initialize({
        userName:   box.dataset.wufooUser,
        formHash:   formHash,
        autoResize: true,
        height:     '497',
        async:      true,
        host:       'wufoo.com',
        header:     'show',
        ssl:        true
      });
      window[formHash].display();
    } catch (e) {}
  };
  document.head.appendChild(script);
});

