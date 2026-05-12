#!/usr/bin/env zsh

set -euo pipefail

REPO_BASE="${POPULAR_REPO_BASE:-https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main}"
INSTALL_DIR="${POPULAR_INSTALL_DIR:-$HOME/.popular-zsh}"
TARGET_FILE="$INSTALL_DIR/popular.zsh"

# Detect the user's default shell; POPULAR_SHELL overrides auto-detection.
POPULAR_SHELL_NAME="${POPULAR_SHELL:-${SHELL:t}}"

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

for rel in "${POPULAR_MODULE_PATHS[@]}"; do
  out="$INSTALL_DIR/$rel"
  mkdir -p "${out:h}"
  curl -fsSL "$REPO_BASE/$rel" -o "$out"
done

# ---------------------------------------------------------------------------
# Shell-specific config injection
# ---------------------------------------------------------------------------

_popular_inject_zsh() {
  local rc="${ZDOTDIR:-$HOME}/.zshrc"
  if ! grep -Fq "source $TARGET_FILE" "$rc" 2>/dev/null; then
    { print; print "# popular.zsh"; print "source $TARGET_FILE"; } >> "$rc"
  fi
  print "Installed to $TARGET_FILE"
  print "Reload your shell with:"
  print "  source \"$rc\""
}

_popular_inject_bash() {
  local rc="$HOME/.bashrc"
  if [[ ! -f "$rc" && -f "$HOME/.bash_profile" ]]; then
    rc="$HOME/.bash_profile"
  fi
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
  local rc="$config_dir/config.fish"
  mkdir -p "$config_dir"
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
  local rc="$config_dir/config.nu"
  mkdir -p "$config_dir"
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
