// /stats のグラフ（Chartkick と Chart.js）だけが使う JS。
// application.js に入れると、グラフの無いページでも毎回読み込むので分けている。
// /stats では defer で読み込み、Chartkick のグラフは chartkick:load を待ってから描く。
// プラグインは Chartkick より先に登録する（Chartkick は読み込まれた時点でグラフを描き始める）
//
// Chart.js は本体の圧縮版（vendor/assets/javascripts/chart.umd.min.js、v4.5.1）を使う。
// Chartkick 同梱の Chart.bundle は日付のライブラリまで含むが、横軸は年とタグ名で時間の軸は使わない。
// 公式リリースの chart.js-4.5.1.tgz の dist/chart.umd.min.js から、.map を指す末尾の 1 行だけ外した
//
//= require chart.umd.min
//= require chartkick_plugins
//= require chartkick
