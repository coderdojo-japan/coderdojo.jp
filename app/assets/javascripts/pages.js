// 特定のページで動かす JS。CSP を強制する時に 'unsafe-inline' を外せるよう、
// ビューの <script> と onchange 属性から移した（spec/requests/inline_script_spec.rb）。
// 全ページで読むので、どの処理も対象の要素が無ければ何もしない。
// application.js は <head> で同期して読むので、$(function) は本文を読み終えてから動く

// 道場一覧（/dojos）: 対象期間を選んだら、その年の表へ移る
document.addEventListener('change', function(event) {
  var select = event.target;
  if (!select.matches || !select.matches('select[data-year-filter]')) { return; }

  var path = select.dataset.yearFilter;
  window.location.href = select.value ? path + '?year=' + select.value + '#table' : path + '#table';
});

// 道場の一覧（トップのスマホ表示・/stats）: 都道府県を開いたら矢印を下向きにし、閉じたら戻す。
// Bootstrap 3 の collapse のイベントは jQuery で出るので、jQuery で受ける
$(document).on('shown.bs.collapse', '#accordion .collapse', function() {
  $(this).parent().find('.fa-chevron-right').removeClass('fa-chevron-right').addClass('fa-chevron-down');
});
$(document).on('hidden.bs.collapse', '#accordion .collapse', function() {
  $(this).parent().find('.fa-chevron-down').removeClass('fa-chevron-down').addClass('fa-chevron-right');
});

// 道場・パートナーの画像のツールチップ（Bootstrap 3）
$(function() {
  $('[data-toggle="tooltip"]').tooltip();
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

// 統計（/stats）の日本地図。jquery.japan-map.js は /stats だけで読む。
// 地図の色と数は、#japan-map-container の data 属性で渡す
$(function() {
  var container = document.getElementById('japan-map-container');
  if (!container || !$.fn.japanMap) { return; }

  var areas      = JSON.parse(container.dataset.areas);
  var dataByPref = JSON.parse(container.dataset.byPrefecture);
  var showCount  = function(data) {
    $('#japan-map-text').text(data.name + ': ' + dataByPref[data.name]);
  };

  $(container).japanMap({
    areas: areas,
    selection: 'prefecture',
    borderLineWidth: 0.1,
    drawsBoxLine: false,
    movesIslands: true,
    showsAreaName: true,
    showsPrefectureName: false,
    prefectureNameType: 'short',
    width: 651,
    font: 'Hiragino Kaku Gothic Pro',
    fontSize: 12,
    fontColor: 'white',
    fontShadowColor: '#444455',
    onSelect: showCount, // スマホでタップした時
    onHover:  showCount
  });
});
