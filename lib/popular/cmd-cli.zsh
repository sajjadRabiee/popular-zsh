# lib/popular/cmd-cli.zsh
# pcli — drop into your normal shell with popular commands available.
# Your PS1 is untouched; a [p] badge appears on the right so you always know
# you're inside the popular session. Type any saved command name directly to run it.

pcli() {
  local _dir
  _dir=$(mktemp -d "${TMPDIR:-/tmp}/pcli.XXXXXX") || return 1

  local _install_dir="$_POPULAR_INSTALL_DIR"
  local _cmds="${POPULAR_COMMANDS_FILE:-$HOME/.popular_commands}"
  local _secs="${POPULAR_SECRETS_FILE:-${_cmds}.secrets}"

  cat > "$_dir/.zshrc" << 'HEREDOC_GUARD'
# ── inherit the user's real environment ──────────────────────────────────────
[[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc" 2>/dev/null
export _PCLI_SHELL=1
HEREDOC_GUARD

  # Append the parts that need shell-variable expansion
  cat >> "$_dir/.zshrc" << ZSHRC
export POPULAR_COMMANDS_FILE="$_cmds"
export POPULAR_SECRETS_FILE="$_secs"

source "$_install_dir/popular.zsh"

# ── short aliases (no-prefix mode) ───────────────────────────────────────────
alias add='padd'
alias addh='paddh'
alias list='pls'
alias remove='premove'
alias edit='pedit'
alias update='pupdate'
alias secret='psecret'
alias save='pexport'
alias load='pimport'
alias help='phelp'
alias bye='exit'

# ── run saved-command names directly ─────────────────────────────────────────
command_not_found_handler() {
  local _name="\$1"; shift
  if _popular_names 2>/dev/null | command grep -qFx "\$_name"; then
    p "\$_name" "\$@"
  else
    print -u2 "pcli: \$_name: command not found"
    return 127
  fi
}

# ── completions ───────────────────────────────────────────────────────────────
# Complete aliases by their own name, not the expanded command.
setopt COMPLETE_ALIASES

# Ensure the completion system is live (user's compinit may have been cached
# before popular.zsh was sourced; a -C re-init is cheap and picks up new defs).
autoload -Uz compinit 2>/dev/null
compinit -C 2>/dev/null

# Wrapper completers for each alias so compdef always resolves correctly.
# (Using compdef alias=cmd form is unreliable when COMPLETE_ALIASES is set.)
_pcli_complete_list()   { _popular_complete_pls "\$@"; }
_pcli_complete_remove() { _popular_complete_saved_names 'command'; }
_pcli_complete_edit()   {
  (( CURRENT == 2 )) || return 1
  _popular_complete_saved_names
}
_pcli_complete_secret() { _popular_complete_psecret "\$@"; }

compdef _pcli_complete_list   list
compdef _pcli_complete_remove remove
compdef _pcli_complete_edit   edit
compdef _pcli_complete_secret secret
compdef _files  save load
compdef _nothing add addh update help bye

# ── first-word completion: offer saved command names in command position ──────
# When the user starts typing a saved name as the first word and hits Tab,
# this makes zsh suggest it alongside normal executables.
_pcli_command_completer() {
  local -a _pnames
  _pnames=("\${(@f)\$(_popular_names 2>/dev/null)}")
  (( \${#_pnames} )) && compadd -a -- _pnames
  # fall through to normal command completion (builtins, PATH executables, etc.)
  _command_names -e 2>/dev/null
  return 0
}
compdef _pcli_command_completer -command-

# ── badge: keep user's PS1, add [p] on the right ─────────────────────────────
RPROMPT="%F{magenta}%B[p]%b%f\${RPROMPT:+ \$RPROMPT}"

# ── entry banner ──────────────────────────────────────────────────────────────
() {
  local _cyan=\$'\\e[36m' _mag=\$'\\e[35m' _bold=\$'\\e[1m' _dim=\$'\\e[2m' _r=\$'\\e[0m'
  print ""
  print "\${_bold}\${_mag}[p]\${_r}  \${_cyan}popular shell\${_r}\${_dim}  —  your normal shell + popular commands\${_r}"
  print "\${_dim}saved commands run directly · aliases: add addh list remove edit secret save load help · bye to exit\${_r}"
  print ""
}
ZSHRC

  ZDOTDIR="$_dir" zsh
  local _rc=$?
  rm -rf "$_dir"
  return $_rc
}
