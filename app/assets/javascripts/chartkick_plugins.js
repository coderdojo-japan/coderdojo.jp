// Chartkick（Chart.js）のグラフを、以前の Highcharts と同じ見た目にする Chart.js のプラグイン。
// どれも Ruby（app/models/chartkick_builder.rb）から library: { plugins: { 名前: { enabled: true } } } で有効にする。
//
// - htmlLegend: 凡例を HTML で描く。系列を縦に並べ、棒は丸、折れ線は「線の上に点」の印にする。
//               押すと、その系列を隠したり出したりする（Highcharts と同じ。Chart.js の凡例は横に並べる）
// - barLabels:  棒の中の上の方に、数を白い字で書く
// - kFormat:    目盛り（scales.*.ticks.kFormat: true）の数を「3.5k」のように千を k で書く
(function () {
  if (typeof Chart === 'undefined') return;

  var SVG_NS = 'http://www.w3.org/2000/svg';
  var FONT_FAMILY = '"Lucida Grande","Lucida Sans Unicode",Arial,Helvetica,sans-serif';

  function marker(dataset) {
    var color = dataset.borderColor || dataset.backgroundColor;
    var svg = document.createElementNS(SVG_NS, 'svg');
    svg.setAttribute('width', '16');
    svg.setAttribute('height', '12');
    svg.style.verticalAlign = 'middle';
    svg.style.marginRight = '4px';

    if (dataset.type === 'line') {
      var line = document.createElementNS(SVG_NS, 'path');
      line.setAttribute('d', 'M 0 6 L 16 6');
      line.setAttribute('stroke', color);
      line.setAttribute('stroke-width', '2');
      svg.appendChild(line);
    }
    var dot = document.createElementNS(SVG_NS, 'circle');
    dot.setAttribute('cx', '8');
    dot.setAttribute('cy', '6');
    dot.setAttribute('r', dataset.type === 'line' ? '4' : '6');
    dot.setAttribute('fill', color);
    svg.appendChild(dot);
    return svg;
  }

  function legendElement(chart) {
    var holder = chart.canvas.parentNode;
    var list = holder.parentNode.querySelector('.chartkick-legend[data-chart-id="' + chart.id + '"]');
    if (list) return list;

    list = document.createElement('ul');
    list.className = 'chartkick-legend';
    list.setAttribute('data-chart-id', chart.id);
    // 凡例全体は中央に置き、2 行の印の左端をそろえる（Highcharts と同じ）。
    // 下の余白は、Highcharts のグラフ全体の高さ（凡例まで含めて 400px）にそろえるため。
    // margin だと外側の枠の margin と相殺されるので padding で取る
    list.style.cssText = 'list-style:none; display:table; margin:0 auto; padding:0 0 13px; text-align:left;';
    holder.parentNode.insertBefore(list, holder.nextSibling);
    return list;
  }

  Chart.register({
    id: 'htmlLegend',
    defaults: { enabled: false },
    afterUpdate: function (chart, _args, options) {
      if (!options.enabled) return;
      var list = legendElement(chart);
      while (list.firstChild) list.removeChild(list.firstChild);

      // 系列の順（棒が上、折れ線が下）に並べる。Highcharts と同じ
      chart.data.datasets.forEach(function (dataset, index) {
        var visible = chart.isDatasetVisible(index);
        var item = document.createElement('li');
        item.style.cssText = 'cursor:pointer; line-height:16px; font-size:12px; font-weight:bold;' +
          'font-family:' + FONT_FAMILY + '; color:' + (visible ? '#333333' : '#cccccc') + ';';
        item.appendChild(marker(dataset));
        item.appendChild(document.createTextNode(dataset.label));
        item.onclick = function () {
          chart.setDatasetVisibility(index, !chart.isDatasetVisible(index));
          chart.update();
        };
        list.appendChild(item);
      });
    }
  });

  Chart.register({
    id: 'barLabels',
    defaults: { enabled: false },
    afterDatasetsDraw: function (chart, _args, options) {
      if (!options.enabled) return;
      var ctx = chart.ctx;
      ctx.save();
      ctx.fillStyle = '#ffffff';
      ctx.font = 'bold 11px ' + FONT_FAMILY;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      chart.data.datasets.forEach(function (dataset, index) {
        if (!chart.isDatasetVisible(index)) return;
        chart.getDatasetMeta(index).data.forEach(function (bar, i) {
          var value = chart.data.datasets[index].data[i];
          if (value === null || value === undefined) return;
          // Highcharts の dataLabels（y: 20）と同じく、棒の上端から少し下に書く
          ctx.fillText(Array.isArray(value) ? value[1] : (value.y !== undefined ? value.y : value), bar.x, bar.y + 10);
        });
      });
      ctx.restore();
    }
  });

  // 刻みが 1000 以上の目盛りは「3.5k」と書く。それ以外は区切りの無い数のまま（Highcharts と同じ）
  Chart.register({
    id: 'kFormat',
    beforeInit: function (chart) {
      var scales = chart.options.scales || {};
      Object.keys(scales).forEach(function (id) {
        var ticks = scales[id].ticks;
        // 縦の目盛り（Ruby で kFormat を true か false に決めたもの）だけ。横軸（年・タグ名）には触れない
        if (!ticks || ticks.kFormat === undefined) return;
        ticks.callback = ticks.kFormat ?
          function (value) { return value === 0 ? '0' : (value / 1000) + 'k'; } :
          function (value) { return String(value); };
      });
    }
  });
})();
