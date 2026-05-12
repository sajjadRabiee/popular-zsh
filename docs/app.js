/* ── Theme ───────────────────────────────────────────────────────── */

function applyTheme(theme) {
  document.documentElement.setAttribute('data-theme', theme);
  document.getElementById('theme-toggle').textContent = theme === 'light' ? '☾' : '☀︎';
  const banner = document.getElementById('hero-banner');
  if (banner) banner.src = theme === 'light' ? 'assets/popular-light.svg' : 'assets/popular.svg';
  localStorage.setItem('popular-theme', theme);
}

function toggleTheme() {
  const current = document.documentElement.getAttribute('data-theme');
  applyTheme(current === 'light' ? 'dark' : 'light');
}

(function () {
  const saved = localStorage.getItem('popular-theme');
  const preferred = window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark';
  applyTheme(saved || preferred);
})();

/* ── Install copy ────────────────────────────────────────────────── */

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

/* ── Shell tabs ──────────────────────────────────────────────────── */

function showShell(id, el) {
  document.querySelectorAll('.shell-panel').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.shell-tab').forEach(t => t.classList.remove('active'));
  document.getElementById('shell-' + id).classList.add('active');
  el.classList.add('active');
}
