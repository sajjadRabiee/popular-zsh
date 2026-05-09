# lib/popular/cmd-run.zsh

p() {
  local name="$1"
  local command rendered

  shift || true

  if [[ -z "$name" ]]; then
    _popular_warn "p: usage: p <name>"
    return 1
  fi

  command=$(_popular_get_command "$name") || {
    _popular_warn "p: '$name' not found"
    return 1
  }

  rendered=$(_popular_render_command "$command" "$@") || return 1

  print -r -- "${fg[cyan]}→${reset_color} $rendered"
  eval "$rendered"
}
