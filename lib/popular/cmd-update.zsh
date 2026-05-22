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
  # Helpers
  # ---------------------------------------------------------------------------

  local _sha256
  _sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "$1" | awk '{print $1}'
    else
      shasum -a 256 "$1" | awk '{print $1}'
    fi
  }

  local _bar
  _bar() {
    local -i cur=$1 tot=$2 w=20 filled i
    (( tot == 0 )) && tot=1
    filled=$(( cur * w / tot ))
    local bar=""
    for (( i = 0; i < w; i++ )); do
      (( i < filled )) && bar+="█" || bar+="░"
    done
    printf '%s' "$bar"
  }

  # ---------------------------------------------------------------------------
  # Banner
  # ---------------------------------------------------------------------------

  print -r ""
  printf "  \033[1mpopular.zsh\033[0m  ·  updating \033[36m%s\033[0m\n\n" \
    "${root/#$HOME/\~}"

  local stage_dir
  stage_dir=$(mktemp -d "${TMPDIR:-/tmp}/popular-update.XXXXXX")
  local _stage_trap="rm -rf '$stage_dir'"
  trap "$_stage_trap" EXIT INT TERM

  # ---------------------------------------------------------------------------
  # 1. Fetch checksums first.
  # ---------------------------------------------------------------------------

  local checksums_file="$stage_dir/checksums.sha256"
  printf "  \033[33m▸\033[0m Fetching checksums... "
  if ! curl -fsSL "$base/checksums.sha256" -o "$checksums_file"; then
    printf "\n"
    _popular_warn "pupdate: could not download checksums.sha256 — aborting"
    return 1
  fi
  printf "\033[32m✓\033[0m\n\n"

  # ---------------------------------------------------------------------------
  # 2. Download cmd-update.zsh first — it may extend _popular_upstream_paths.
  # ---------------------------------------------------------------------------

  local updater_rel="lib/popular/cmd-update.zsh"
  local updater_stage="$stage_dir/$updater_rel"
  mkdir -p "${updater_stage:h}"
  local _total=${#_popular_upstream_paths[@]}
  local _dl=1 _exp _act

  printf "\r  \033[33mDownloading\033[0m  [\033[36m%s\033[0m]  %2d/%-2d  %-40s" \
    "$(_bar 1 $_total)" 1 $_total "$updater_rel"
  if ! curl -fsSL "$base/$updater_rel" -o "$updater_stage"; then
    printf "\n"
    _popular_warn "pupdate: download failed: $base/$updater_rel"
    return 1
  fi

  # Verify and source the updater before fetching the rest.
  _exp=$(awk -v f="$updater_rel" '($2==f||$2==("*"f)){print $1}' "$checksums_file")
  if [[ -z "$_exp" ]]; then
    printf "\n"
    _popular_warn "pupdate: no checksum entry for $updater_rel — aborting"
    return 1
  fi
  _act=$(_sha256 "$updater_stage")
  if [[ "$_act" != "$_exp" ]]; then
    printf "\n"
    _popular_warn "pupdate: checksum mismatch for $updater_rel — aborting"
    return 1
  fi
  source "$updater_stage" 2>/dev/null
  _total=${#_popular_upstream_paths[@]}   # re-read in case new modules were added

  # ---------------------------------------------------------------------------
  # 3. Download remaining modules.
  # ---------------------------------------------------------------------------

  for rel in "${_popular_upstream_paths[@]}"; do
    [[ "$rel" == "$updater_rel" ]] && continue
    (( _dl++ ))
    printf "\r  \033[33mDownloading\033[0m  [\033[36m%s\033[0m]  %2d/%-2d  %-40s" \
      "$(_bar $_dl $_total)" $_dl $_total "$rel"
    local stage_file="$stage_dir/$rel"
    mkdir -p "${stage_file:h}"
    if ! curl -fsSL "$base/$rel" -o "$stage_file"; then
      printf "\n"
      _popular_warn "pupdate: download failed: $base/$rel"
      return 1
    fi
  done
  printf "\r  \033[32mDownloading\033[0m  [\033[32m%s\033[0m]  %2d/%-2d  %-40s\n" \
    "$(_bar $_total $_total)" $_total $_total "complete ✓"

  # ---------------------------------------------------------------------------
  # 4. Verify all files against checksums.sha256.
  # ---------------------------------------------------------------------------

  local _vr=0
  for rel in "${_popular_upstream_paths[@]}"; do
    (( _vr++ ))
    printf "\r  \033[33mVerifying  \033[0m  [\033[36m%s\033[0m]  %2d/%-2d  %-40s" \
      "$(_bar $_vr $_total)" $_vr $_total "$rel"
    local stage_file="$stage_dir/$rel"
    _exp=$(awk -v f="$rel" '($2==f||$2==("*"f)){print $1}' "$checksums_file")
    if [[ -z "$_exp" ]]; then
      printf "\n"
      _popular_warn "pupdate: no checksum entry for $rel — aborting"
      return 1
    fi
    _act=$(_sha256 "$stage_file")
    if [[ "$_act" != "$_exp" ]]; then
      printf "\n"
      _popular_warn "pupdate: checksum mismatch for $rel — aborting"
      return 1
    fi
  done
  printf "\r  \033[32mVerifying  \033[0m  [\033[32m%s\033[0m]  %2d/%-2d  %-40s\n" \
    "$(_bar $_total $_total)" $_total $_total "all passed ✓"

  # ---------------------------------------------------------------------------
  # 5. All checksums pass — move files into place.
  # ---------------------------------------------------------------------------

  printf "  \033[33mInstalling \033[0m  "
  for rel in "${_popular_upstream_paths[@]}"; do
    local dest="$root/$rel"
    mkdir -p "${dest:h}"
    mv -f "$stage_dir/$rel" "$dest"
  done
  printf "%d files → \033[36m%s\033[0m  \033[32m✓\033[0m\n\n" \
    $_total "${root/#$HOME/\~}"

  trap - EXIT INT TERM
  rm -rf "$stage_dir"

  # Re-source popular.zsh so every updated function is live immediately —
  # no manual reload needed.
  if source "$root/popular.zsh" 2>/dev/null; then
    _popular_info "Update complete. All commands reloaded."
  else
    _popular_warn "pupdate: auto-reload failed — run: source \"$root/popular.zsh\""
  fi
}
