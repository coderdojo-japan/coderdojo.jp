// 色見本を押すと、その色のコードをコピーする。CSP でインラインの JS を止めるので、
// public/docs/styleguides.md の <script> と onclick 属性から移した（spec/requests/inline_script_spec.rb）
document.addEventListener('click', function(event) {
  var swatch = event.target.closest('[data-color]');
  if (!swatch) return;

  navigator.clipboard.writeText(swatch.dataset.color).then(function() {
    showToast('コピーしました');
  });
});

// 右下に 2 秒だけ出す通知。見た目は public/docs/styleguides.md の .copy-toast
function showToast(text) {
  var toast = document.createElement('div');
  toast.className   = 'copy-toast';
  toast.textContent = text;
  document.body.appendChild(toast);
  setTimeout(function() { toast.remove(); }, 2000);
}
