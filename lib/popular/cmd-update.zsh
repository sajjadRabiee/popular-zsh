# lib/popular/cmd-update.zsh
# Keep _popular_upstream_paths in sync with install.sh (POPULAR_MODULE_PATHS).

typeset -ga _popular_upstream_paths=(
  popular.zsh
  install.sh
  lib/popular/ui.zsh
  lib/popular/store.zsh
  lib/popular/template.zsh
  lib/popular/secrets.zsh
  lib/popular/cmd-add.zsh
  lib/popular/cmd-run.zsh
  lib/popular/cmd-list.zsh
  lib/popular/cmd-io.zsh
  lib/popular/cmd-edit.zsh
  lib/popular/cmd-update.zsh
  lib/popular/cmd-cli.zsh
  lib/popular/cmd-help.zsh
  lib/popular/completion.zsh
)

pupdate() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_pupdate; return 0; }
  local base="${POPULAR_REPO_BASE:-https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main}"
  # POPULAR_INSTALL_DIR env var overrides auto-detected _POPULAR_INSTALL_DIR;
  # --dir / -d flag overrides both.
  local root="${POPULAR_INSTALL_DIR:-$_POPULAR_INSTALL_DIR}"
  local rel tmp

  while [[ "${1:-}" == -* ]]; do
    case "$1" in
      -d | --dir)
        shift
        if [[ -z "${1:-}" ]]; then
          _popular_warn "pupdate: --dir requires a path"
          return 1
        fi
        root="$1"
        ;;
      *)
        _popular_warn "pupdate: unknown option: $1"$'\n'"usage: pupdate [-d|--dir <path>]"$'\n'"run 'pupdate --help' for details"
        return 1
        ;;
    esac
    shift
  done

  if [[ -z "$root" || ! -f "$root/popular.zsh" ]]; then
    _popular_warn "pupdate: could not resolve install directory"$'\n'"hint: run 'pupdate --dir /path/to/popular-zsh' or set POPULAR_INSTALL_DIR"
    return 1
  fi

  if [[ ! -d "$root/lib/popular" ]]; then
    _popular_warn "pupdate: missing lib/popular under $root — use install.sh or clone the full repo layout"
    return 1
  fi

  if ! command -v curl >/dev/null 2>&1; then
    _popular_warn "pupdate: curl not found"
    return 1
  fi

  # Download cmd-update.zsh first and re-source it so _popular_upstream_paths
  # reflects any newly added modules before the main download loop runs.
  # Without this, a file added to the list only appears after a second pupdate.
  local updater_rel="lib/popular/cmd-update.zsh"
  tmp="${root}/${updater_rel}.tmp.$$"
  if ! curl -fsSL "$base/$updater_rel" -o "$tmp"; then
    _popular_warn "pupdate: download failed: $base/$updater_rel"
    rm -f "$tmp"
    return 1
  fi
  mv -f "$tmp" "${root}/${updater_rel}"
  source "${root}/${updater_rel}" 2>/dev/null

  for rel in "${_popular_upstream_paths[@]}"; do
    [[ "$rel" == "$updater_rel" ]] && continue   # already fetched above
    tmp="${root}/${rel}.tmp.$$"
    mkdir -p "${tmp:h}"
    if ! curl -fsSL "$base/$rel" -o "$tmp"; then
      _popular_warn "pupdate: download failed: $base/$rel"
      rm -f "$tmp"
      return 1
    fi
    mv -f "$tmp" "${root}/${rel}"
  done

  _popular_info "Updated from $base"

  # Re-source popular.zsh so every updated function is live immediately —
  # no manual reload needed.
  if source "$root/popular.zsh" 2>/dev/null; then
    _popular_note "All commands reloaded."
  else
    _popular_warn "pupdate: auto-reload failed — run: source \"$root/popular.zsh\""
  fi
}
