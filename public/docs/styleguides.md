# 🎨 CoderDojo Japan 配色ガイドライン

## カラーパレット🎨
クリックで16進数カラーコードがコピーできます。
<h3>カラー</h3>
<div class="colors">
  <div class="color">
    <div class="one-color" style="background-color: #2275ca" onclick="Copy('#2275ca')"><p style="color: #fff;">main-blue<br>#2275ca</p></div>
  </div>
  <div class="color">
    <div class="one-color" style="background-color: #2e9ad9" onclick="Copy('#2e9ad9')"><p style="color: #fff;">lightblue<br>#2e9ad9</p></div>
  </div>
  <div class="color">
    <div class="one-color" style="background-color: #00176e" onclick="Copy('#00176e')"><p style="color: #fff;">darkblue<br>#00176e</p></div>
  </div>
  <div class="color">
    <div class="one-color" style="background-color: #ffd700" onclick="Copy('#ffd700')"><p style="color: #333;">yellow<br>#ffd700</p></div>
  </div>
</div>
<h3>グレースケール</h3>
<div class="colors graycolors">
  <div class="color">
    <div class="one-color" style="background-color: #333" onclick="Copy('#333')"><p style="color: #fff;">black<br>#333</p></div>
  </div>
  <div class="color">
    <div class="one-color" style="background-color: #555" onclick="Copy('#555')"><p style="color: #fff;">gray-5<br>#555</p></div>
  </div>
  <div class="color">
    <div class="one-color" style="background-color: #777" onclick="Copy('#777')"><p style="color: #fff;">gray-7<br>#777</p></div>
  </div>
  <div class="color">
    <div class="one-color" style="background-color: #999" onclick="Copy('#999')"><p style="color: #fff;">gray-9<br>#999</p></div>
  </div>
  <div class="color">
    <div class="one-color" style="background-color: #b8b8b8" onclick="Copy('#b8b8b8')"><p style="color: #333;">gray-b<br>#b8b8b8</p></div>
  </div>
  <div class="color">
    <div class="one-color" style="background-color: #ccc" onclick="Copy('#ccc')"><p style="color: #333;">gray-c<br>#ccc</p></div>
  </div>
  <div class="color">
    <div class="one-color" style="background-color: #f7f7f7" onclick="Copy('#f7f7f7')"><p style="color: #333;">lightgray<br>#f7f7f7</p></div>
  </div>
</div>

## 色の適用ルール

### 基本色
本文及び見出しの文字色はblack(#333)を使用してください。
背景色の輝度(HSLでいうL)が50%未満の場合は、白(#fff)を使用してください。

### リンク
通常はmain-blueで、ホバー時はdarkblueを使用してください。

色彩Tips🎨: 色の見え方は様々なので、色による区別のみではなく、プラス明るさや形での区別がおすすめです！

### ボタン
背景色はmain-blue, 文字色は#fff(bold)を使用してください。


<style media="screen">
  .color {
    margin: 4px;
    width: calc(25% - 8px);
  }
  .one-color {
    height: 100px;
    cursor: pointer;
    border-radius: 4px;
    padding: 8px;
  }
  .colors {
    display: flex;
    flex-wrap: wrap;
  }
  .graycolors .color {
    width: calc(14.28% - 8px);
  }
</style>
<div id='copy' style='color:#fff;opacity:0;'></div>

<script type='text/javascript' src="/js/notify.js"></script>

<script type="text/javascript">
  function Copy(color) {
    var div = document.getElementById('copy');
    div.innerHTML = '';
    var text = document.createTextNode(color);
    div.appendChild(text);
    window.getSelection().selectAllChildren(div);
    document.execCommand('copy');
    $.notify.defaults({autoHideDelay: 2000, arrowShow: false, globalPosition: 'bottom right'});
    $.notify("コピーしました", "success");
    
  }
</script>


