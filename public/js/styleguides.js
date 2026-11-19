// 色見本を押すと、その色のコードをコピーする。CSP でインラインの JS を止めるので、
// public/docs/styleguides.md の <script> と onclick 属性から移した（spec/requests/inline_script_spec.rb）
document.addEventListener('click', function(event) {
  var swatch = event.target.closest('[data-color]');
  if (!swatch) return;

  var div = document.getElementById('copy');
  div.innerHTML = '';
  div.appendChild(document.createTextNode(swatch.dataset.color));
  window.getSelection().selectAllChildren(div);
  document.execCommand('copy');
  $.notify.defaults({autoHideDelay: 2000, arrowShow: false, globalPosition: 'bottom right'});
  $.notify("コピーしました", "success");
});
