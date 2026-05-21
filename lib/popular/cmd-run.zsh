# lib/popular/cmd-run.zsh

p() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_p; return 0; }

  local dry_run=0
  local -a _args=("$@")
  _args=("${_args[@]:#--dry-run}")
  (( ${#_args[@]} < $# )) && dry_run=1
  set -- "${_args[@]}"

  local name="$1"
  local command rendered flags

  (( $# > 0 )) && shift

  if [[ -z "$name" ]]; then
    _popular_warn "p: usage: p <name> [args…]"$'\n'"run 'p --help' for details"
    return 1
  fi

  command=$(_popular_get_command "$name") || {
    _popular_warn "p: '$name' not found"
    return 1
  }

  rendered=$(_popular_render_command "$command" "$@") || return 1
  if (( ! dry_run )); then
    rendered=$(_popular_substitute_secrets "$name" "$rendered") || return 1
  fi

  if (( dry_run )); then
    print -r -- "${fg[yellow]}dry-run${reset_color} ${fg[cyan]}→${reset_color} $rendered"
    return 0
  fi
  print -r -- "${fg[cyan]}→${reset_color} $rendered"

  flags=$(_popular_get_flags "$name")
  if [[ "$flags" == *confirm* ]]; then
    local _answer
    print -rn -- "${fg[yellow]}⚠ Are you sure?${reset_color} [y/N] " >/dev/tty
    read -k 1 _answer </dev/tty
    print >/dev/tty
    if [[ "$_answer" != y && "$_answer" != Y ]]; then
      _popular_warn "Aborted."
      return 1
    fi
  fi

  eval "$rendered"
}

pcp() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_pcp; return 0; }
  local name="$1"
  local command rendered
  local -a secret_keys

  (( $# > 0 )) && shift

  if [[ -z "$name" ]]; then
    _popular_warn "pcp: usage: pcp <name> [args…]"$'\n'"run 'pcp --help' for details"
    return 1
  fi

  command=$(_popular_get_command "$name") || {
    _popular_warn "pcp: '$name' not found"
    return 1
  }

  secret_keys=("${(@f)$(_popular_collect_secret_keys_for_command "$command")}")
  secret_keys=("${secret_keys[@]:#}")

  if (( ${#secret_keys[@]} > 0 )) && [[ -t 1 ]]; then
    print -r -- "${fg[yellow]}⚠ This command contains secret(s): ${(j:, :)secret_keys}${reset_color}" >/dev/tty
    print -r -- "${fg[yellow]}  Plaintext values will be placed in your clipboard.${reset_color}" >/dev/tty
    local _answer
    print -rn -- "${fg[yellow]}  Copy anyway?${reset_color} [y/N] " >/dev/tty
    read -k 1 _answer </dev/tty
    print >/dev/tty
    if [[ "$_answer" != y && "$_answer" != Y ]]; then
      _popular_warn "Aborted."
      return 1
    fi
  fi

  rendered=$(_popular_render_command "$command" "$@") || return 1
  rendered=$(_popular_substitute_secrets "$name" "$rendered") || return 1

  if [[ "$OSTYPE" == darwin* ]]; then
    print -rn -- "$rendered" | pbcopy
  elif [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    print -rn -- "$rendered" | wl-copy
  else
    print -rn -- "$rendered" | xclip -sel clip
  fi

  print -r -- "Copied."
}
