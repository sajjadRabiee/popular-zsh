# lib/popular/cmd-add.zsh

padd() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_padd; return 0; }

  local flags="" tags="" target_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --confirm) flags="confirm"; shift ;;
      --local)   target_file="$PWD/.popular_commands"; shift ;;
      -t|--tags)
        if (( $# < 2 )); then
          _popular_warn "padd: -t requires a tag value"$'\n'"run 'padd --help' for details"
          return 1
        fi
        tags="$2"; shift 2 ;;
      *) break ;;
    esac
  done

  if [[ $# -lt 2 ]]; then
    _popular_warn "padd: usage: padd [--confirm] [--local] [-t <tags>] <name> <command…>"$'\n'"run 'padd --help' for details"
    return 1
  fi

  local name="$1"
  shift
  local locality_note=""
  [[ -n "$target_file" ]] && locality_note=" [local]"
  _popular_save_entry "$name" "$*" "$flags" "$tags" "$target_file"
  if [[ "$flags" == *confirm* && -n "$tags" ]]; then
    _popular_info "Saved '$name'${locality_note} [${tags}] (⚠ confirmation required)"
  elif [[ "$flags" == *confirm* ]]; then
    _popular_info "Saved '$name'${locality_note} (⚠ confirmation required)"
  elif [[ -n "$tags" ]]; then
    _popular_info "Saved '$name'${locality_note} [${tags}]"
  else
    _popular_info "Saved '$name'${locality_note}"
  fi
}

paddh() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_paddh; return 0; }

  local flags="" tags="" target_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --confirm) flags="confirm"; shift ;;
      --local)   target_file="$PWD/.popular_commands"; shift ;;
      -t|--tags)
        if (( $# < 2 )); then
          _popular_warn "paddh: -t requires a tag value"$'\n'"run 'paddh --help' for details"
          return 1
        fi
        tags="$2"; shift 2 ;;
      *) break ;;
    esac
  done

  local hist="$1"
  local name="$2"
  local cmd

  if [[ -z "$hist" ]]; then
    _popular_warn "paddh: usage: paddh [--confirm] [--local] [-t <tags>] <history#> [name]"$'\n'"event numbers from \`history\`; negative = relative (-1 = previous)"$'\n'"run 'paddh --help' for details"
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

  local locality_note=""
  [[ -n "$target_file" ]] && locality_note=" [local]"
  _popular_save_entry "$name" "$cmd" "$flags" "$tags" "$target_file"
  if [[ "$flags" == *confirm* && -n "$tags" ]]; then
    _popular_info "Saved '$name'${locality_note} [${tags}] ← history $hist (⚠ confirmation required)"
  elif [[ "$flags" == *confirm* ]]; then
    _popular_info "Saved '$name'${locality_note} ← history $hist (⚠ confirmation required)"
  elif [[ -n "$tags" ]]; then
    _popular_info "Saved '$name'${locality_note} [${tags}] ← history $hist"
  else
    _popular_info "Saved '$name'${locality_note} ← history $hist"
  fi
  _popular_note "$cmd"
}
