// /stats のグラフ（Chartkick と Chart.js）だけが使う JS。
// application.js に入れると、グラフの無いページでも毎回読み込むので分けている。
// /stats では defer で読み込み、Chartkick のグラフは chartkick:load を待ってから描く。
// プラグインは Chartkick より先に登録する（Chartkick は読み込まれた時点でグラフを描き始める）
//
//= require Chart.bundle
//= require chartkick_plugins
//= require chartkick
