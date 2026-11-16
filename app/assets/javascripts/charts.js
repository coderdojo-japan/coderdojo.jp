// /stats のグラフ（Chartkick と Chart.js）だけが使う JS。
// application.js に入れると、グラフの無いページでも毎回読み込むので分けている。
// /stats では defer で読み込むので、本文を読み終えてから動く。
// プラグインは Chartkick より先に登録し、グラフを描く前に使えるようにしておく
//
// Chart.js は本体の圧縮版（vendor/assets/javascripts/chart.umd.min.js、v4.6.1）を使う。
// Chartkick 同梱の Chart.bundle は日付のライブラリまで含むが、横軸は年とタグ名で時間の軸は使わない。
// 公式リリースの chart.js-4.6.1.tgz の dist/chart.umd.min.js から、.map を指す末尾の 1 行だけ外した
//
//= require chart.umd.min
//= require chartkick_plugins
//= require chartkick

// グラフのデータと設定は、ビューの div の data 属性で渡す（app/helpers/charts_helper.rb）。
// Chartkick のヘルパーが出すインラインの <script> の代わりに、ここで描く
document.querySelectorAll('[data-chartkick-type]').forEach(function(element) {
  new Chartkick[element.dataset.chartkickType](
    element,
    JSON.parse(element.dataset.chartkickData),
    JSON.parse(element.dataset.chartkickOptions)
  );
});
