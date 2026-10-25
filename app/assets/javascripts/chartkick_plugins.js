// Chartkick（Chart.js）のグラフを、以前の Highcharts と同じ見た目にする Chart.js のプラグイン。
// どれも Ruby（app/models/chartkick_builder.rb）から library: { plugins: { 名前: { enabled: true } } } で有効にする。
//
// - htmlLegend: 凡例を HTML で描く。系列を縦に並べ、棒は丸、折れ線は「線の上に点」の印にする。
//               押すと、その系列を隠したり出したりする（Highcharts と同じ。Chart.js の凡例は横に並べる）
// - barLabels:  棒の中の上の方に、数を白い字で書く
// - kFormat:    目盛り（scales.*.ticks.kFormat: true）の数を「3.5k」のように千を k で書く
// - htmlTooltip: マウスを重ねた時の吹き出しを HTML で描く。薄い灰色の地に系列の色の枠と影、
//               点を指す矢印、「● 名前: 値（太字）」（Highcharts と同じ。Chart.js の吹き出しは値だけを太字にできない）
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

  function tooltipElement(chart) {
    var holder = chart.canvas.parentNode;
    var box = holder.querySelector('.chartkick-tooltip');
    if (box) return box;

    holder.style.position = 'relative';
    box = document.createElement('div');
    box.className = 'chartkick-tooltip';
    box.style.cssText = 'position:absolute; z-index:1; pointer-events:none; white-space:nowrap; text-align:left; opacity:0;' +
      'transition:opacity .15s; padding:5px 8px 6px; border:1px solid; border-radius:3px;' +
      'background:rgba(247,247,247,0.85); box-shadow:1px 1px 3px rgba(0,0,0,0.25);' +
      'color:#333333; font-size:12px; line-height:16px; font-family:' + FONT_FAMILY + ';';
    // 矢印は枠の色の三角に、地の色の三角を 1px ずらして重ねる
    ['outer', 'inner'].forEach(function (name) {
      var arrow = document.createElement('div');
      arrow.className = 'chartkick-tooltip-' + name;
      arrow.style.cssText = 'position:absolute; width:0; height:0; border-style:solid; border-color:transparent;' +
        (name === 'outer' ? 'bottom:-7px; margin-left:-7px; border-width:7px 7px 0;' :
                            'bottom:-6px; margin-left:-6px; border-width:6px 6px 0; border-top-color:#f7f7f7;');
      box.appendChild(arrow);
    });
    box.appendChild(document.createElement('div'));
    holder.appendChild(box);
    return box;
  }

  function showTooltip(context) {
    var chart = context.chart;
    var tooltip = context.tooltip;
    var box = tooltipElement(chart);
    if (tooltip.opacity === 0 || !tooltip.dataPoints || !tooltip.dataPoints.length) {
      box.style.opacity = 0;
      return;
    }

    var point = tooltip.dataPoints[0];
    var dataset = point.dataset;
    var color = dataset.type === 'line' ? dataset.borderColor : dataset.backgroundColor;

    var content = box.lastChild;
    content.textContent = '';
    var header = document.createElement('span');
    header.style.fontSize = '10px';
    header.textContent = point.label;
    var dot = document.createElement('span');
    dot.style.color = color;
    dot.textContent = '●';
    var value = document.createElement('b');
    // 3 桁ごとに「,」で区切る（Highcharts の lang.thousandsSep: ','。0e52994b）
    value.textContent = point.parsed.y.toLocaleString('en-US');
    content.appendChild(header);
    content.appendChild(document.createElement('br'));
    content.appendChild(dot);
    content.appendChild(document.createTextNode(' ' + dataset.label + ': '));
    content.appendChild(value);

    box.style.borderColor = color;
    box.querySelector('.chartkick-tooltip-outer').style.borderTopColor = color;

    // 点（棒は上端）の真上に置く。グラフの外にはみ出す時は箱だけずらし、矢印は点を指したままにする
    var x = chart.canvas.offsetLeft + point.element.x;
    var y = chart.canvas.offsetTop + point.element.y;
    var width = box.offsetWidth;
    var left = Math.max(0, Math.min(x - width / 2, chart.canvas.parentNode.clientWidth - width));
    box.style.left = left + 'px';
    box.style.top = (y - box.offsetHeight - 10) + 'px';
    box.querySelector('.chartkick-tooltip-outer').style.left = (x - left) + 'px';
    box.querySelector('.chartkick-tooltip-inner').style.left = (x - left) + 'px';
    box.style.opacity = 1;
  }

  Chart.register({
    id: 'htmlTooltip',
    defaults: { enabled: false },
    beforeInit: function (chart) {
      var plugins = chart.config.options.plugins || {};
      if (!plugins.htmlTooltip || !plugins.htmlTooltip.enabled) return;
      plugins.tooltip = Object.assign({}, plugins.tooltip, { enabled: false, external: showTooltip });
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
