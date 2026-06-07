# lib/popular/cmd-edit.zsh

pedit() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_pedit; return 0; }
  local name="" open_local=0
  if [[ "${1:-}" == "--local" ]]; then
    open_local=1
    shift
  fi
  name="${1:-}"
  local cmd flags tags tmp ed st source_file

  ed="${EDITOR:-vim}"

  if [[ -z "$name" ]]; then
    if (( open_local )); then
      local local_file
      local_file=$(_popular_find_local_file)
      if [[ -z "$local_file" ]]; then
        _popular_warn "pedit: no local .popular_commands file found"
        return 1
      fi
      "$ed" "$local_file"
    else
      _popular_ensure_file
      "$ed" "$POPULAR_COMMANDS_FILE"
    fi
    return 0
  fi

  # Determine which file holds this entry
  source_file=""
  local local_file
  local_file=$(_popular_find_local_file)
  if [[ -n "$local_file" ]]; then
    local found
    found=$(awk -F'|' -v name="$name" '$1==name{f=1} END{print f+0}' "$local_file")
    (( found )) && source_file="$local_file"
  fi
  if [[ -z "$source_file" ]]; then
    _popular_ensure_file
    source_file="$POPULAR_COMMANDS_FILE"
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

  _popular_save_entry "$name" "$cmd" "$flags" "$tags" "$source_file"
  _popular_info "Updated '$name'"
}
