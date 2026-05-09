# lib/popular/cmd-add.zsh

padd() {
  local name="$1"
  shift || true

  if [[ -z "$name" || $# -eq 0 ]]; then
    _popular_warn "padd: usage: padd <name> <command...>"
    return 1
  fi

  _popular_save_entry "$name" "$*"
  _popular_info "Saved '$name'"
}

paddh() {
  local hist="$1"
  local name="$2"
  local cmd

  if [[ -z "$hist" ]]; then
    _popular_warn "paddh: usage: paddh <history#> [name]"
    _popular_warn "paddh: event numbers match the first column of \`history\` (or negative: -1 = previous)"
    return 1
  fi

  if [[ ! -o interactive ]]; then
    _popular_warn "paddh: history is only available in interactive shells"
    return 1
  fi

  cmd=$(_popular_get_history_command "$hist") || {
    _popular_warn "paddh: no history event '$hist' (try \`history\` to list events)"
    return 1
  }

  [[ -n "$name" ]] || name="h$hist"

  _popular_save_entry "$name" "$cmd"
  _popular_info "Saved '$name' ← history $hist"
  _popular_note "$cmd"
}
