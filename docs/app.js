function copyInstall() {
  const text = document.getElementById('install-cmd').textContent;
  navigator.clipboard.writeText(text).then(() => {
    const btn = document.getElementById('copy-install');
    btn.textContent = 'Copied!';
    btn.classList.add('copied');
    setTimeout(() => {
      btn.textContent = 'Copy';
      btn.classList.remove('copied');
    }, 2000);
  });
}

function showShell(id, el) {
  document.querySelectorAll('.shell-panel').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.shell-tab').forEach(t => t.classList.remove('active'));
  document.getElementById('shell-' + id).classList.add('active');
  el.classList.add('active');
}
