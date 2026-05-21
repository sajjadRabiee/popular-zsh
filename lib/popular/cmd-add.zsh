# lib/popular/cmd-add.zsh

padd() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_padd; return 0; }

  local flags=""
  [[ "${1:-}" == --confirm ]] && { flags="confirm"; shift; }

  if [[ $# -lt 2 ]]; then
    _popular_warn "padd: usage: padd [--confirm] <name> <command…>"$'\n'"run 'padd --help' for details"
    return 1
  fi

  local name="$1"
  shift
  _popular_save_entry "$name" "$*" "$flags"
  if [[ "$flags" == *confirm* ]]; then
    _popular_info "Saved '$name' (⚠ confirmation required)"
  else
    _popular_info "Saved '$name'"
  fi
}

paddh() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_paddh; return 0; }

  local flags=""
  [[ "${1:-}" == --confirm ]] && { flags="confirm"; shift; }

  local hist="$1"
  local name="$2"
  local cmd

  if [[ -z "$hist" ]]; then
    _popular_warn "paddh: usage: paddh [--confirm] <history#> [name]"$'\n'"event numbers from \`history\`; negative = relative (-1 = previous)"$'\n'"run 'paddh --help' for details"
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

  _popular_save_entry "$name" "$cmd" "$flags"
  if [[ "$flags" == *confirm* ]]; then
    _popular_info "Saved '$name' ← history $hist (⚠ confirmation required)"
  else
    _popular_info "Saved '$name' ← history $hist"
  fi
  _popular_note "$cmd"
}
