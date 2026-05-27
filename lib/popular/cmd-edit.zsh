# lib/popular/cmd-edit.zsh

pedit() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_pedit; return 0; }
  local name="$1"
  local cmd flags tags tmp ed st

  _popular_ensure_file
  ed="${EDITOR:-vim}"

  if [[ -z "$name" ]]; then
    "$ed" "$POPULAR_COMMANDS_FILE"
    return 0
  fi

  cmd=$(_popular_get_command "$name") || {
    _popular_warn "pedit: '$name' not found"
    return 1
  }

  flags=$(_popular_get_flags "$name")
  tags=$(_popular_get_tags "$name")

  tmp=$(mktemp "${TMPDIR:-/tmp}/popular-pedit.XXXXXX") || {
    _popular_warn "pedit: could not create temp file"
    return 1
  }
  trap "rm -f '$tmp'" EXIT INT TERM

  print -r -- "$cmd" > "$tmp"
  "$ed" "$tmp"
  st=$?

  cmd="$(cat "$tmp")"
  cmd="${cmd//$'\r'/}"
  rm -f "$tmp"
  trap - EXIT INT TERM

  if (( st != 0 )); then
    _popular_warn "pedit: editor exited $st; changes not saved"
    return $st
  fi

  if [[ -z "${cmd//[[:space:]]/}" ]]; then
    _popular_warn "pedit: empty buffer; not saving (use premove to delete '$name')"
    return 1
  fi

  _popular_save_entry "$name" "$cmd" "$flags" "$tags"
  _popular_info "Updated '$name'"
}
