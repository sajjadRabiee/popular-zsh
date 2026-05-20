# lib/popular/cmd-run.zsh

p() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_p; return 0; }
  local name="$1"
  local command rendered

  shift || true

  if [[ -z "$name" ]]; then
    _popular_warn "p: usage: p <name> [args…]"$'\n'"run 'p --help' for details"
    return 1
  fi

  command=$(_popular_get_command "$name") || {
    _popular_warn "p: '$name' not found"
    return 1
  }

  rendered=$(_popular_render_command "$command" "$@") || return 1
  rendered=$(_popular_substitute_secrets "$name" "$rendered") || return 1

  print -r -- "${fg[cyan]}→${reset_color} $rendered"
  eval "$rendered"
}

pcp() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_pcp; return 0; }
  local name="$1"
  local command rendered

  shift || true

  if [[ -z "$name" ]]; then
    _popular_warn "pcp: usage: pcp <name> [args…]"$'\n'"run 'pcp --help' for details"
    return 1
  fi

  command=$(_popular_get_command "$name") || {
    _popular_warn "pcp: '$name' not found"
    return 1
  }

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
