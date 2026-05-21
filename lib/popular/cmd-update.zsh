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
  local dir_explicit=0
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
        dir_explicit=1
        ;;
      *)
        _popular_warn "pupdate: unknown option: $1"$'\n'"usage: pupdate [-d|--dir <path>]"$'\n'"run 'pupdate --help' for details"
        return 1
        ;;
    esac
    shift
  done

  # Prompt for the install directory when no explicit override was given and
  # we're on a real TTY.  Press Enter to accept the detected default.
  if (( ! dir_explicit )) && [[ -z "${POPULAR_INSTALL_DIR:-}" ]] && [[ -e /dev/tty ]]; then
    local _answer
    print -n "Install directory [${root}]: " >/dev/tty
    read -r _answer </dev/tty
    if [[ -n "$_answer" ]]; then
      root="${_answer/#\~/$HOME}"
    fi
  fi

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

  # ---------------------------------------------------------------------------
  # Staged download + checksum verification.
  # All files land in a temp dir; we verify every hash before touching $root.
  # Fails closed: missing or mismatched checksums abort the update.
  # ---------------------------------------------------------------------------

  local _sha256
  _sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "$1" | awk '{print $1}'
    else
      shasum -a 256 "$1" | awk '{print $1}'
    fi
  }

  local stage_dir
  stage_dir=$(mktemp -d "${TMPDIR:-/tmp}/popular-update.XXXXXX")
  # Clean up staging dir on exit, interrupt, or error.
  local _stage_trap="rm -rf '$stage_dir'"
  trap "$_stage_trap" EXIT INT TERM

  # 1. Fetch checksums first.
  local checksums_file="$stage_dir/checksums.sha256"
  if ! curl -fsSL "$base/checksums.sha256" -o "$checksums_file"; then
    _popular_warn "pupdate: could not download checksums.sha256 — aborting"
    return 1
  fi

  # 2. Download cmd-update.zsh first to a staging path so _popular_upstream_paths
  #    reflects any newly added modules before the main loop runs.
  local updater_rel="lib/popular/cmd-update.zsh"
  local updater_stage="$stage_dir/$updater_rel"
  mkdir -p "${updater_stage:h}"
  if ! curl -fsSL "$base/$updater_rel" -o "$updater_stage"; then
    _popular_warn "pupdate: download failed: $base/$updater_rel"
    return 1
  fi

  # 3. Verify updater before sourcing it.
  local _exp _act
  _exp=$(awk -v f="$updater_rel" '($2==f||$2==("*"f)){print $1}' "$checksums_file")
  if [[ -z "$_exp" ]]; then
    _popular_warn "pupdate: no checksum entry for $updater_rel — aborting"
    return 1
  fi
  _act=$(_sha256 "$updater_stage")
  if [[ "$_act" != "$_exp" ]]; then
    _popular_warn "pupdate: checksum mismatch for $updater_rel — aborting"
    return 1
  fi
  source "$updater_stage" 2>/dev/null

  # 4. Download remaining modules to staging.
  for rel in "${_popular_upstream_paths[@]}"; do
    [[ "$rel" == "$updater_rel" ]] && continue
    local stage_file="$stage_dir/$rel"
    mkdir -p "${stage_file:h}"
    if ! curl -fsSL "$base/$rel" -o "$stage_file"; then
      _popular_warn "pupdate: download failed: $base/$rel"
      return 1
    fi
  done

  # 5. Verify all files against checksums.sha256.
  for rel in "${_popular_upstream_paths[@]}"; do
    local stage_file="$stage_dir/$rel"
    _exp=$(awk -v f="$rel" '($2==f||$2==("*"f)){print $1}' "$checksums_file")
    if [[ -z "$_exp" ]]; then
      _popular_warn "pupdate: no checksum entry for $rel — aborting"
      return 1
    fi
    _act=$(_sha256 "$stage_file")
    if [[ "$_act" != "$_exp" ]]; then
      _popular_warn "pupdate: checksum mismatch for $rel — aborting"
      return 1
    fi
  done

  # 6. All checksums pass — move files into place.
  for rel in "${_popular_upstream_paths[@]}"; do
    local dest="$root/$rel"
    mkdir -p "${dest:h}"
    mv -f "$stage_dir/$rel" "$dest"
  done

  trap - EXIT INT TERM
  rm -rf "$stage_dir"

  _popular_info "Updated from $base"

  # Re-source popular.zsh so every updated function is live immediately —
  # no manual reload needed.
  if source "$root/popular.zsh" 2>/dev/null; then
    _popular_note "All commands reloaded."
  else
    _popular_warn "pupdate: auto-reload failed — run: source \"$root/popular.zsh\""
  fi
}
