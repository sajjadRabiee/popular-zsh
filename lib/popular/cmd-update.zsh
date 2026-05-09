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
  lib/popular/completion.zsh
)

pupdate() {
  local base="${POPULAR_REPO_BASE:-https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main}"
  local root="$_POPULAR_INSTALL_DIR"
  local rel tmp

  if [[ -z "$root" || ! -f "$root/popular.zsh" ]]; then
    _popular_warn "pupdate: could not resolve install directory (is popular.zsh sourced from a file?)"
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

  for rel in "${_popular_upstream_paths[@]}"; do
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
  _popular_note "Reload with: source \"$root/popular.zsh\""
}
