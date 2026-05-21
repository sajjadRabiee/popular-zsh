#!/usr/bin/env zsh
# Guard: must run under zsh, not sh/bash.
if [ -z "${ZSH_VERSION-}" ]; then
  echo "error: install.sh requires zsh — run:  zsh ./install.sh" >&2
  exit 1
fi

set -euo pipefail

REPO_BASE="${POPULAR_REPO_BASE:-https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main}"
INSTALL_DIR="${POPULAR_INSTALL_DIR:-$HOME/.popular-zsh}"
TARGET_FILE="$INSTALL_DIR/popular.zsh"

# Detect the user's default shell; POPULAR_SHELL overrides auto-detection.
# ${SHELL##*/} is POSIX-compatible basename; avoids zsh-only :t modifier.
POPULAR_SHELL_NAME="${POPULAR_SHELL:-${SHELL##*/}}"

typeset -a POPULAR_MODULE_PATHS=(
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
  lib/popular/completion.zsh
)

mkdir -p "$INSTALL_DIR/lib/popular"

# ---------------------------------------------------------------------------
# Checksum verification — download all files to a staging dir, verify, then
# install atomically so a partial download never lands in $INSTALL_DIR.
# Fails closed: if checksums.sha256 is missing or any hash mismatches, abort.
# ---------------------------------------------------------------------------

_popular_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

STAGE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/popular-install.XXXXXX")
trap 'rm -rf "$STAGE_DIR"' EXIT INT TERM

# 1. Fetch the checksums file first.
CHECKSUMS_FILE="$STAGE_DIR/checksums.sha256"
if ! curl -fsSL "$REPO_BASE/checksums.sha256" -o "$CHECKSUMS_FILE"; then
  print "error: could not download checksums.sha256 — aborting install" >&2
  exit 1
fi

# 2. Download each module to the staging area.
for rel in "${POPULAR_MODULE_PATHS[@]}"; do
  stage_out="$STAGE_DIR/$rel"
  mkdir -p "${stage_out:h}"
  if ! curl -fsSL "$REPO_BASE/$rel" -o "$stage_out"; then
    print "error: download failed: $rel" >&2
    exit 1
  fi
done

# 3. Verify every file against checksums.sha256 before touching $INSTALL_DIR.
for rel in "${POPULAR_MODULE_PATHS[@]}"; do
  stage_out="$STAGE_DIR/$rel"
  expected=$(awk -v f="$rel" '($2 == f || $2 == ("*"f)) { print $1 }' "$CHECKSUMS_FILE")
  if [[ -z "$expected" ]]; then
    print "error: no checksum entry for $rel in checksums.sha256" >&2
    exit 1
  fi
  actual=$(_popular_sha256 "$stage_out")
  if [[ "$actual" != "$expected" ]]; then
    print "error: checksum mismatch for $rel (expected $expected, got $actual)" >&2
    exit 1
  fi
done

# 4. All checks passed — move files into place.
for rel in "${POPULAR_MODULE_PATHS[@]}"; do
  out="$INSTALL_DIR/$rel"
  mkdir -p "${out:h}"
  mv -f "$STAGE_DIR/$rel" "$out"
done

# ---------------------------------------------------------------------------
# Interactive RC file prompt
# ---------------------------------------------------------------------------

# Ask the user which RC file to inject into.
# Uses /dev/tty so it works even when the script is piped from curl.
# Falls back silently to $1 (the default) when:
#   - POPULAR_RC_FILE env var is set (non-interactive override)
#   - /dev/tty is not available (truly non-interactive)
_popular_ask_rc() {
  local default="$1"
  if [[ -n "${POPULAR_RC_FILE:-}" ]]; then
    local _rc_path="${POPULAR_RC_FILE/#\~/$HOME}"
    if [[ "$_rc_path" != "$HOME/"* && "$_rc_path" != "$HOME" ]]; then
      print "error: POPULAR_RC_FILE must be inside \$HOME — got: ${POPULAR_RC_FILE}" >&2
      return 1
    fi
    print "$_rc_path"
    return
  fi
  if [[ -e /dev/tty ]]; then
    print "" >/dev/tty
    print "Where should the source line be added?" >/dev/tty
    print -n "  RC file [${default}]: " >/dev/tty
    local answer
    read -r answer </dev/tty
    answer="${answer:-$default}"
    print "${answer/#\~/$HOME}"
  else
    print "$default"
  fi
}

# ---------------------------------------------------------------------------
# Shell-specific config injection
# ---------------------------------------------------------------------------

_popular_inject_zsh() {
  local default_rc="${ZDOTDIR:-$HOME}/.zshrc"
  local rc
  rc="$(_popular_ask_rc "$default_rc")"
  if ! grep -Fq "source $TARGET_FILE" "$rc" 2>/dev/null; then
    { print; print "# popular.zsh"; print "source $TARGET_FILE"; } >> "$rc"
  fi
  print "Installed to $TARGET_FILE"
  print "Reload your shell with:"
  print "  source \"$rc\""
}

_popular_inject_bash() {
  local default_rc="$HOME/.bashrc"
  if [[ ! -f "$default_rc" && -f "$HOME/.bash_profile" ]]; then
    default_rc="$HOME/.bash_profile"
  fi
  local rc
  rc="$(_popular_ask_rc "$default_rc")"
  if grep -Fq '_p_zsh()' "$rc" 2>/dev/null; then
    print "popular.zsh bash wrappers already in $rc — skipping."
    print "Reload your shell with:  source \"$rc\""
    return
  fi
  local snippet
  snippet=$(sed "s|__POPULAR_TARGET__|${TARGET_FILE}|g" << 'SNIPPET'

# popular.zsh
_p_zsh() {
  local cmd="$1"; shift
  zsh -c "source __POPULAR_TARGET__ 2>/dev/null && $cmd \"$@\"" -- "$@"
}
p()       { _p_zsh p       "$@"; }
padd()    { _p_zsh padd    "$@"; }
paddh()   { _p_zsh paddh   "$@"; }
pls()     { _p_zsh pls     "$@"; }
premove() { _p_zsh premove "$@"; }
pedit()   { _p_zsh pedit   "$@"; }
pexport() { _p_zsh pexport "$@"; }
pimport() { _p_zsh pimport "$@"; }
psecret() { _p_zsh psecret "$@"; }
pupdate() { zsh -c "source __POPULAR_TARGET__ 2>/dev/null && pupdate"; }
phelp()   { zsh -c "source __POPULAR_TARGET__ 2>/dev/null && phelp";   }
pcli()    { zsh -i -c "source __POPULAR_TARGET__ 2>/dev/null && pcli"; }
SNIPPET
)
  print "$snippet" >> "$rc"
  print "Installed to $TARGET_FILE"
  print "Added bash wrappers to $rc"
  print "Reload your shell with:"
  print "  source \"$rc\""
}

_popular_inject_fish() {
  local config_dir="$HOME/.config/fish"
  local default_rc="$config_dir/config.fish"
  mkdir -p "$config_dir"
  local rc
  rc="$(_popular_ask_rc "$default_rc")"
  mkdir -p "${rc:h}"
  if grep -Fq 'function _p_zsh' "$rc" 2>/dev/null; then
    print "popular.zsh fish wrappers already in $rc — skipping."
    print "Reload your shell with:  source \"$rc\""
    return
  fi
  local snippet
  snippet=$(sed "s|__POPULAR_TARGET__|${TARGET_FILE}|g" << 'SNIPPET'

# popular.zsh
function _p_zsh
    set --local cmd $argv[1]; set --erase argv[1]
    zsh -c "source __POPULAR_TARGET__ 2>/dev/null && $cmd \"$@\"" -- $argv
end
function p;       _p_zsh p       $argv; end
function padd;    _p_zsh padd    $argv; end
function paddh;   _p_zsh paddh   $argv; end
function pls;     _p_zsh pls     $argv; end
function premove; _p_zsh premove $argv; end
function pedit;   _p_zsh pedit   $argv; end
function pexport; _p_zsh pexport $argv; end
function pimport; _p_zsh pimport $argv; end
function psecret; _p_zsh psecret $argv; end
function pupdate; zsh -c "source __POPULAR_TARGET__ 2>/dev/null && pupdate"; end
function phelp;   zsh -c "source __POPULAR_TARGET__ 2>/dev/null && phelp";   end
function pcli;    zsh -i -c "source __POPULAR_TARGET__ 2>/dev/null && pcli"; end
SNIPPET
)
  print "$snippet" >> "$rc"
  print "Installed to $TARGET_FILE"
  print "Added fish wrappers to $rc"
  print "Reload your shell with:"
  print "  source \"$rc\""
}

_popular_inject_nushell() {
  local config_dir="$HOME/.config/nushell"
  local default_rc="$config_dir/config.nu"
  mkdir -p "$config_dir"
  local rc
  rc="$(_popular_ask_rc "$default_rc")"
  mkdir -p "${rc:h}"
  if grep -Fq 'def p [' "$rc" 2>/dev/null; then
    print "popular.zsh nushell wrappers already in $rc — skipping."
    print "Restart nushell to apply."
    return
  fi
  local snippet
  snippet=$(sed "s|__POPULAR_TARGET__|${TARGET_FILE}|g" << 'SNIPPET'

# popular.zsh
def p [...rest: string] { zsh -c $"source __POPULAR_TARGET__ 2>/dev/null && p ($rest | str join ' ')" }
def padd [...rest: string] { zsh -c $"source __POPULAR_TARGET__ 2>/dev/null && padd ($rest | str join ' ')" }
def paddh [...rest: string] { zsh -c $"source __POPULAR_TARGET__ 2>/dev/null && paddh ($rest | str join ' ')" }
def pls [...rest: string] { zsh -c $"source __POPULAR_TARGET__ 2>/dev/null && pls ($rest | str join ' ')" }
def premove [name: string] { zsh -c $"source __POPULAR_TARGET__ 2>/dev/null && premove ($name)" }
def pedit [...rest: string] { zsh -c $"source __POPULAR_TARGET__ 2>/dev/null && pedit ($rest | str join ' ')" }
def pexport [...rest: string] { zsh -c $"source __POPULAR_TARGET__ 2>/dev/null && pexport ($rest | str join ' ')" }
def pimport [...rest: string] { zsh -c $"source __POPULAR_TARGET__ 2>/dev/null && pimport ($rest | str join ' ')" }
def psecret [...rest: string] { zsh -c $"source __POPULAR_TARGET__ 2>/dev/null && psecret ($rest | str join ' ')" }
def pupdate [] { zsh -c "source __POPULAR_TARGET__ 2>/dev/null && pupdate" }
def phelp [] { zsh -c "source __POPULAR_TARGET__ 2>/dev/null && phelp" }
def pcli [] { zsh -i -c "source __POPULAR_TARGET__ 2>/dev/null && pcli" }
SNIPPET
)
  print "$snippet" >> "$rc"
  print "Installed to $TARGET_FILE"
  print "Added nushell wrappers to $rc"
  print "Restart nushell to apply."
}

# ---------------------------------------------------------------------------
# Dispatch based on detected shell
# ---------------------------------------------------------------------------

case "$POPULAR_SHELL_NAME" in
  zsh)
    _popular_inject_zsh
    ;;
  bash)
    _popular_inject_bash
    ;;
  fish)
    _popular_inject_fish
    ;;
  nu|nushell)
    _popular_inject_nushell
    ;;
  *)
    print "Unknown shell '$POPULAR_SHELL_NAME' — defaulting to zsh injection."
    print "Set POPULAR_SHELL=bash, fish, or nu to override."
    _popular_inject_zsh
    ;;
esac
