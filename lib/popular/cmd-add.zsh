# lib/popular/cmd-add.zsh

padd() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_padd; return 0; }

  if [[ $# -lt 2 ]]; then
    _popular_warn "padd: usage: padd <name> <command…>"$'\n'"run 'padd --help' for details"
    return 1
  fi

  local name="$1"
  shift
  _popular_save_entry "$name" "$*"
  _popular_info "Saved '$name'"
}

paddh() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_paddh; return 0; }
  local hist="$1"
  local name="$2"
  local cmd

  if [[ -z "$hist" ]]; then
    _popular_warn "paddh: usage: paddh <history#> [name]"$'\n'"event numbers from \`history\`; negative = relative (-1 = previous)"$'\n'"run 'paddh --help' for details"
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
