/* ── Theme ──────────────────────────────────────────────────────── */

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

/* ── Install copy ───────────────────────────────────────────────── */

function copyInstall() {
  const text = document.getElementById('install-cmd').textContent;
  navigator.clipboard.writeText(text).then(() => {
    const btn = document.getElementById('copy-install');
    btn.textContent = 'Copied!';
    btn.classList.add('copied');
    setTimeout(() => { btn.textContent = 'Copy'; btn.classList.remove('copied'); }, 2000);
  });
}

/* ── Mobile menu ────────────────────────────────────────────────── */

function toggleMenu() {
  document.getElementById('main-nav').classList.toggle('menu-open');
}

function closeMenu() {
  document.getElementById('main-nav').classList.remove('menu-open');
}

document.addEventListener('click', function (e) {
  const nav = document.getElementById('main-nav');
  if (nav && nav.classList.contains('menu-open') && !nav.contains(e.target)) {
    nav.classList.remove('menu-open');
  }
});

/* ── Shell tabs ─────────────────────────────────────────────────── */

function showShell(id, el) {
  document.querySelectorAll('.shell-panel').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.shell-tab').forEach(t => t.classList.remove('active'));
  document.getElementById('shell-' + id).classList.add('active');
  el.classList.add('active');
}

/* ── Command Registry ───────────────────────────────────────────── */

const CMDS = {

  padd: {
    syntax: 'padd <name> <command>',
    desc:   'Save a command by name',
    lines: [
      { type: 'prompt',  text: 'padd gs git status' },
      { type: 'success', text: "✓ Saved 'gs'" },
    ],
    args: [
      { id: 'name', label: 'Name',    placeholder: 'gs',         required: true },
      { id: 'cmd',  label: 'Command', placeholder: 'git status', required: true },
    ],
    simulate(i) {
      const name = i.name.trim(), cmd = i.cmd.trim();
      if (!name) return [{ type: 'error', text: 'padd: name is required' }];
      if (!cmd)  return [{ type: 'error', text: 'padd: command is required' }];
      return [
        { type: 'prompt',  text: `padd ${name} ${cmd}` },
        { type: 'success', text: `✓ Saved '${name}'` },
      ];
    }
  },

  paddh: {
    syntax: 'paddh <event#> [name]',
    desc:   'Save a command from shell history by event number',
    lines: [
      { type: 'prompt',  text: 'paddh 523 deploy' },
      { type: 'dim',     text: '# history: kubectl rollout restart deploy/staging' },
      { type: 'success', text: "✓ Saved 'deploy'" },
    ],
    args: [
      { id: 'event', label: 'Event #',           placeholder: '523',    required: true  },
      { id: 'name',  label: 'Name (optional)',    placeholder: 'deploy', required: false },
    ],
    simulate(i) {
      const ev = i.event.trim(), name = i.name.trim();
      if (!ev || isNaN(ev)) return [{ type: 'error', text: 'paddh: event number required' }];
      const alias = name || `history-${ev}`;
      return [
        { type: 'prompt',  text: `paddh ${ev}${name ? ' ' + name : ''}` },
        { type: 'dim',     text: `# history #${ev}: kubectl rollout restart deploy/staging` },
        { type: 'success', text: `✓ Saved '${alias}'` },
      ];
    }
  },

  p: {
    syntax: 'p <name> [args...]',
    desc:   'Run a saved command; expands template placeholders',
    lines: [
      { type: 'prompt', text: 'p gs' },
      { type: 'output', text: 'On branch main' },
      { type: 'dim',    text: 'nothing to commit, working tree clean' },
    ],
    args: [
      { id: 'name',  label: 'Command name',              placeholder: 'gs',       required: true  },
      { id: 'flags', label: 'Arguments / flags (opt.)',   placeholder: '--port=8080', required: false },
    ],
    simulate(i) {
      const name = i.name.trim(), flags = i.flags.trim();
      if (!name) return [{ type: 'error', text: 'p: command name required' }];
      return [
        { type: 'prompt',  text: `p ${name}${flags ? ' ' + flags : ''}` },
        { type: 'dim',     text: `# expanding '${name}'...` },
        { type: 'output',  text: 'On branch main' },
        { type: 'dim',     text: 'nothing to commit, working tree clean' },
      ];
    }
  },

  pls: {
    syntax: 'pls [filter]',
    desc:   'List all saved commands, optionally filtered',
    lines: [
      { type: 'prompt', text: 'pls' },
      { type: 'output', text: 'gs          git status' },
      { type: 'output', text: 'serve       python3 -m http.server [[port:8000]]' },
      { type: 'output', text: 'hook        curl -H "Auth: Bearer <<token>>" $URL' },
    ],
    args: [
      { id: 'filter', label: 'Filter (optional)', placeholder: 'git', required: false },
    ],
    simulate(i) {
      const filter = i.filter.trim().toLowerCase();
      const all = [
        { name: 'gs',     cmd: 'git status' },
        { name: 'gd',     cmd: 'git diff' },
        { name: 'gl',     cmd: 'git log --oneline -20' },
        { name: 'serve',  cmd: 'python3 -m http.server [[port:8000]]' },
        { name: 'hook',   cmd: 'curl -H "Auth: Bearer <<token>>" $URL' },
        { name: 'deploy', cmd: 'kubectl rollout restart deploy/{{name}}' },
      ];
      const rows = filter ? all.filter(r => r.name.includes(filter) || r.cmd.includes(filter)) : all;
      if (!rows.length) return [
        { type: 'prompt', text: `pls ${filter}` },
        { type: 'dim',    text: `no commands matching '${filter}'` },
      ];
      return [
        { type: 'prompt', text: filter ? `pls ${filter}` : 'pls' },
        ...rows.map(r => ({ type: 'output', text: r.name.padEnd(12) + r.cmd })),
      ];
    }
  },

  premove: {
    syntax: 'premove <name>',
    desc:   'Delete a saved command',
    lines: [
      { type: 'prompt',  text: 'premove gs' },
      { type: 'success', text: "Removed 'gs'" },
    ],
    args: [
      { id: 'name', label: 'Name', placeholder: 'gs', required: true },
    ],
    simulate(i) {
      const name = i.name.trim();
      if (!name) return [{ type: 'error', text: 'premove: name required' }];
      return [
        { type: 'prompt',  text: `premove ${name}` },
        { type: 'success', text: `Removed '${name}'` },
      ];
    }
  },

  pedit: {
    syntax: 'pedit [name]',
    desc:   'Edit a command (or the whole store) in $EDITOR',
    lines: [
      { type: 'prompt',  text: 'pedit gs' },
      { type: 'dim',     text: '# opens $EDITOR with gs pre-filled' },
      { type: 'success', text: "✓ Updated 'gs'" },
    ],
    args: [
      { id: 'name', label: 'Name (blank = edit all)', placeholder: 'gs', required: false },
    ],
    simulate(i) {
      const name = i.name.trim();
      return [
        { type: 'prompt',  text: `pedit${name ? ' ' + name : ''}` },
        { type: 'dim',     text: '# opening $EDITOR...' },
        { type: 'success', text: name ? `✓ Updated '${name}'` : '✓ Store updated' },
      ];
    }
  },

  pexport: {
    syntax: 'pexport [file|-]',
    desc:   'Export commands to a file — secrets never included',
    lines: [
      { type: 'prompt',  text: 'pexport ~/my-commands.txt' },
      { type: 'success', text: 'Exported 6 command(s) → ~/my-commands.txt' },
      { type: 'dim',     text: '# safe to commit — no secrets exported' },
    ],
    args: [
      { id: 'file', label: 'Output file (blank = stdout)', placeholder: '~/my-commands.txt', required: false },
    ],
    simulate(i) {
      const file = i.file.trim() || '-';
      const dest = file === '-' ? 'stdout' : file;
      return [
        { type: 'prompt',  text: `pexport ${file}` },
        { type: 'success', text: `Exported 6 command(s) → ${dest}` },
        { type: 'dim',     text: '# secrets are never included in exports' },
      ];
    }
  },

  pimport: {
    syntax: 'pimport [-r] [-R] <file|repo>',
    desc:   'Import commands from a file or remote popular-pack',
    lines: [
      { type: 'prompt',  text: 'pimport -R alice/popular-git-pack' },
      { type: 'info',    text: 'Fetched https://raw.githubusercontent.com/alice/popular-git-pack/main/commands.pop' },
      { type: 'success', text: 'Imported 8 command(s) — merged' },
    ],
    args: [
      { id: 'file',    label: 'File or owner/repo',     placeholder: 'alice/popular-git-pack', required: true  },
      { id: 'remote',  label: 'Remote? (yes/no)',        placeholder: 'yes',                   required: false },
      { id: 'replace', label: 'Replace mode? (yes/no)',  placeholder: 'no',                    required: false },
    ],
    simulate(i) {
      const file = i.file.trim();
      if (!file) return [{ type: 'error', text: 'pimport: file or repo required' }];
      const isRemote  = ['yes', 'y', '-r', '--remote'].includes(i.remote.trim().toLowerCase());
      const isReplace = ['yes', 'y', '-r', '--replace'].includes(i.replace.trim().toLowerCase());
      const flags = [isRemote ? '-R' : '', isReplace ? '-r' : ''].filter(Boolean).join(' ');
      const cmd   = `pimport ${flags} ${file}`.replace(/ {2,}/g, ' ').trim();
      const lines = [{ type: 'prompt', text: cmd }];
      if (isRemote) {
        const isUrl = file.startsWith('https://') || file.startsWith('http://');
        const url   = isUrl ? file : `https://raw.githubusercontent.com/${file}/main/commands.pop`;
        lines.push({ type: 'info', text: `Fetched ${url}` });
      }
      lines.push({ type: 'success', text: `Imported 8 command(s) — ${isReplace ? 'replaced' : 'merged'}` });
      return lines;
    }
  },

  psecret: {
    syntax: 'psecret [-g] <key>',
    desc:   'Store an AES-256-CBC encrypted secret value',
    lines: [
      { type: 'prompt',  text: 'psecret -g api-token' },
      { type: 'info',    text: 'popular.zsh master password: ••••••••' },
      { type: 'info',    text: "Global secret 'api-token': ••••••••" },
      { type: 'success', text: "✓ Stored 'api-token' (AES-256-CBC)" },
    ],
    args: [
      { id: 'key', label: 'Secret key name', placeholder: 'api-token', required: true },
    ],
    simulate(i) {
      const key = i.key.trim();
      if (!key) return [{ type: 'error', text: 'psecret: key name required' }];
      return [
        { type: 'prompt',  text: `psecret -g ${key}` },
        { type: 'info',    text: 'popular.zsh master password: ••••••••' },
        { type: 'info',    text: `Global secret '${key}': ••••••••` },
        { type: 'success', text: `✓ Stored '${key}' (AES-256-CBC encrypted)` },
      ];
    }
  },

  plock: {
    syntax: 'plock',
    desc:   'Clear cached master password from this shell session',
    lines: [
      { type: 'prompt',  text: 'plock' },
      { type: 'success', text: 'Secrets locked. Password prompted on next use.' },
    ],
    args: [],
    simulate() {
      return [
        { type: 'prompt',  text: 'plock' },
        { type: 'success', text: 'Secrets locked. Password prompted on next use.' },
      ];
    }
  },

  pupdate: {
    syntax: 'pupdate',
    desc:   'Download the latest popular.zsh from GitHub',
    lines: [
      { type: 'prompt',  text: 'pupdate' },
      { type: 'output',  text: 'Downloading popular.zsh from GitHub...' },
      { type: 'success', text: 'Updated. Reload your shell: exec zsh' },
    ],
    args: [],
    simulate() {
      return [
        { type: 'prompt',  text: 'pupdate' },
        { type: 'output',  text: 'Downloading popular.zsh from GitHub...' },
        { type: 'output',  text: 'Verifying modules...' },
        { type: 'success', text: 'Updated to latest. Reload: exec zsh' },
      ];
    }
  },

  'psecret-reset': {
    syntax: 'psecret-reset',
    desc:   'Change master password (rekey) or wipe all secrets',
    lines: [
      { type: 'prompt',  text: 'psecret-reset' },
      { type: 'info',    text: 'Do you still have your old master password? [y/N] y' },
      { type: 'info',    text: 'Old master password: ••••••••' },
      { type: 'info',    text: 'New master password: ••••••••' },
      { type: 'success', text: 'Re-encrypted 5 secret(s). New password set.' },
    ],
    args: [
      { id: 'haspw', label: 'Have old password? (yes/no)', placeholder: 'yes', required: true },
    ],
    simulate(i) {
      const h = i.haspw.trim().toLowerCase();
      const has = h === 'yes' || h === 'y';
      if (has) return [
        { type: 'prompt',  text: 'psecret-reset' },
        { type: 'info',    text: 'Do you still have your old master password? [y/N] y' },
        { type: 'info',    text: 'Old master password: ••••••••' },
        { type: 'info',    text: 'New master password: ••••••••' },
        { type: 'info',    text: 'Confirm new master password: ••••••••' },
        { type: 'success', text: 'Re-encrypted 5 secret(s). New master password set.' },
      ];
      return [
        { type: 'prompt',  text: 'psecret-reset' },
        { type: 'info',    text: 'Do you still have your old master password? [y/N] n' },
        { type: 'error',   text: 'WARNING: ALL encrypted secrets will be permanently deleted.' },
        { type: 'info',    text: 'Type yes to confirm: yes' },
        { type: 'info',    text: 'New master password: ••••••••' },
        { type: 'info',    text: 'Confirm new master password: ••••••••' },
        { type: 'success', text: 'All secrets deleted. New master password set.' },
      ];
    }
  },

  'psecret-migrate': {
    syntax: 'psecret-migrate',
    desc:   'Upgrade v1 plain-text secrets to AES-256-CBC encrypted v2',
    lines: [
      { type: 'prompt',  text: 'psecret-migrate' },
      { type: 'info',    text: 'popular.zsh master password: ••••••••' },
      { type: 'output',  text: 'Migrating 4 secret(s) to AES-256-CBC...' },
      { type: 'success', text: 'Migrated 4 secret(s). Backup: ~/.popular_commands.secrets.bak' },
    ],
    args: [],
    simulate() {
      return [
        { type: 'prompt',  text: 'psecret-migrate' },
        { type: 'info',    text: 'popular.zsh master password: ••••••••' },
        { type: 'output',  text: 'Migrating secrets to AES-256-CBC...' },
        { type: 'success', text: 'Migrated 4 secret(s) to encrypted format.' },
        { type: 'dim',     text: 'Backup saved: ~/.popular_commands.secrets.bak' },
      ];
    }
  },

  pcli: {
    syntax: 'pcli',
    desc:   'Drop into an interactive popular sub-shell',
    lines: [
      { type: 'prompt',  text: 'pcli' },
      { type: 'output',  text: '  popular shell — saved names work directly · bye to exit' },
      { type: 'dim',     text: '→ gs' },
      { type: 'success', text: 'On branch main · nothing to commit' },
    ],
    args: [],
    simulate() {
      return [
        { type: 'prompt', text: 'pcli' },
        { type: 'output', text: '  popular shell — saved names work directly · bye to exit' },
        { type: 'dim',    text: '' },
        { type: 'dim',    text: "Type saved command names directly. 'bye' to exit." },
      ];
    }
  },

};

/* ── Hover Panel ────────────────────────────────────────────────── */

let hoverDelay = null;
let typeTimer  = null;

function positionPanel(card) {
  const panel = document.getElementById('cmd-hover-panel');
  const rect  = card.getBoundingClientRect();
  const pw    = 360;
  const ph    = panel.offsetHeight || 240;

  let left = rect.right + 14;
  let top  = rect.top;

  if (left + pw > window.innerWidth - 16) left = rect.left - pw - 14;
  if (left < 12) { left = Math.max(12, rect.left); top = rect.bottom + 12; }

  top = Math.max(80, Math.min(top, window.innerHeight - ph - 16));

  panel.style.left = left + 'px';
  panel.style.top  = top  + 'px';
}

function showHoverPanel(card) {
  const key  = card.dataset.cmd;
  const data = CMDS[key];
  if (!data) return;

  const panel = document.getElementById('cmd-hover-panel');
  positionPanel(card);

  document.getElementById('hp-cmd-name').textContent = key;
  document.getElementById('hp-syntax').textContent   = data.syntax;
  document.getElementById('hp-desc').textContent     = data.desc;

  panel.classList.add('visible');
  startTypewriter(data.lines);
}

function hideHoverPanel() {
  document.getElementById('cmd-hover-panel').classList.remove('visible');
  clearTimeout(typeTimer);
}

function startTypewriter(lines) {
  const el = document.getElementById('hp-terminal');
  el.innerHTML = '';
  clearTimeout(typeTimer);

  let li = 0, ci = 0, textEl = null;

  function tick() {
    if (li >= lines.length) {
      if (textEl) {
        const cur = document.createElement('span');
        cur.className = 'tw-cursor';
        textEl.appendChild(cur);
      }
      return;
    }

    const line = lines[li];

    if (ci === 0) {
      const row = document.createElement('div');
      row.className = 'tw-line';

      if (line.type === 'prompt') {
        const pr = document.createElement('span');
        pr.className = 'tw-prompt';
        pr.textContent = '$ ';
        row.appendChild(pr);
      }

      textEl = document.createElement('span');
      textEl.className = 'tw-text-' + (
        line.type === 'prompt' ? 'prompt' :
        line.type === 'success' ? 'success' :
        line.type === 'error'   ? 'error'   :
        line.type === 'info'    ? 'info'    :
        line.type === 'dim'     ? 'dim'     : 'output'
      );
      row.appendChild(textEl);
      el.appendChild(row);
    }

    if (ci < line.text.length) {
      textEl.textContent += line.text[ci++];
      typeTimer = setTimeout(tick, line.type === 'prompt' ? 52 : 14);
    } else {
      li++; ci = 0;
      typeTimer = setTimeout(tick, line.type === 'prompt' ? 240 : 90);
    }
  }

  typeTimer = setTimeout(tick, 80);
}

/* ── Playground ─────────────────────────────────────────────────── */

let pgTimer = null;

function pgSelectCommand(key) {
  const data = CMDS[key];
  const container = document.getElementById('pg-args');
  container.innerHTML = '';
  if (!data || !data.args.length) return;

  data.args.forEach(arg => {
    const field = document.createElement('div');
    field.className = 'pg-field';

    const lbl = document.createElement('label');
    lbl.className = 'pg-label';
    lbl.setAttribute('for', 'pg-arg-' + arg.id);
    lbl.textContent = arg.label;

    const inp = document.createElement('input');
    inp.type = 'text';
    inp.className = 'pg-input';
    inp.id = 'pg-arg-' + arg.id;
    inp.placeholder = arg.placeholder;
    inp.addEventListener('keydown', e => { if (e.key === 'Enter') pgRun(); });

    field.appendChild(lbl);
    field.appendChild(inp);
    container.appendChild(field);
  });
}

function pgRun() {
  const key  = document.getElementById('pg-select').value;
  const data = CMDS[key];
  if (!data) return;

  const inputs = {};
  (data.args || []).forEach(arg => {
    const el = document.getElementById('pg-arg-' + arg.id);
    inputs[arg.id] = el ? el.value : '';
  });

  pgAnimate(data.simulate(inputs));
}

function pgAnimate(lines) {
  clearTimeout(pgTimer);
  const out = document.getElementById('pg-output');
  out.innerHTML = '';
  let li = 0;

  function addLine() {
    if (li >= lines.length) return;
    const line = lines[li++];

    const div = document.createElement('div');
    div.className = 'pg-line';

    if (line.type === 'prompt') {
      const pr = document.createElement('span');
      pr.className = 'pg-line-prompt';
      pr.textContent = '$ ';
      div.appendChild(pr);
    }

    const txt = document.createElement('span');
    txt.className = 'pg-line-text-' + (
      line.type === 'prompt'  ? 'prompt'  :
      line.type === 'success' ? 'success' :
      line.type === 'error'   ? 'error'   :
      line.type === 'info'    ? 'info'    :
      line.type === 'dim'     ? 'dim'     : 'output'
    );
    txt.textContent = line.text;
    div.appendChild(txt);
    out.appendChild(div);

    pgTimer = setTimeout(addLine, line.type === 'prompt' ? 380 : 180);
  }

  addLine();
}

/* ── Init ───────────────────────────────────────────────────────── */

document.addEventListener('DOMContentLoaded', function () {

  /* Hover panel events */
  document.querySelectorAll('.feature-card[data-cmd]').forEach(card => {
    card.addEventListener('mouseenter', () => {
      clearTimeout(hoverDelay);
      hoverDelay = setTimeout(() => showHoverPanel(card), 110);
    });
    card.addEventListener('mouseleave', () => {
      clearTimeout(hoverDelay);
      hideHoverPanel();
    });
  });

  /* Playground: init with first command */
  pgSelectCommand('padd');

});
