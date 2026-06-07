# lib/popular/cmd-io.zsh

premove() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_premove; return 0; }

  local scope="" name=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --local)  scope="local";  shift ;;
      --global) scope="global"; shift ;;
      *) break ;;
    esac
  done
  name="$1"

  if [[ -z "$name" ]]; then
    _popular_warn "premove: usage: premove [--local|--global] <name>"$'\n'"run 'premove --help' for details"
    return 1
  fi

  local local_file
  local_file=$(_popular_find_local_file)

  if [[ "$scope" == "local" ]]; then
    if [[ -z "$local_file" ]]; then
      _popular_warn "premove: no local .popular_commands file found"
      return 1
    fi
    local found
    found=$(awk -F'|' -v name="$name" '$1==name{f=1} END{print f+0}' "$local_file")
    if (( ! found )); then
      _popular_warn "premove: '$name' not found in local file"
      return 1
    fi
    awk -F'|' -v name="$name" '$1 != name' "$local_file" > "${local_file}.tmp"
    mv "${local_file}.tmp" "$local_file"
    _popular_info "Removed '$name' (local)"
    return 0
  fi

  if [[ "$scope" == "global" ]]; then
    _popular_ensure_file
    awk -F'|' -v name="$name" '$1 != name' "$POPULAR_COMMANDS_FILE" > "${POPULAR_COMMANDS_FILE}.tmp"
    mv "${POPULAR_COMMANDS_FILE}.tmp" "$POPULAR_COMMANDS_FILE"
    _popular_secrets_remove_for_command "$name"
    _popular_info "Removed '$name'"
    return 0
  fi

  # Default: local-first
  if [[ -n "$local_file" ]]; then
    local found
    found=$(awk -F'|' -v name="$name" '$1==name{f=1} END{print f+0}' "$local_file")
    if (( found )); then
      awk -F'|' -v name="$name" '$1 != name' "$local_file" > "${local_file}.tmp"
      mv "${local_file}.tmp" "$local_file"
      _popular_info "Removed '$name' (local)"
      return 0
    fi
  fi

  _popular_ensure_file
  awk -F'|' -v name="$name" '$1 != name' "$POPULAR_COMMANDS_FILE" > "${POPULAR_COMMANDS_FILE}.tmp"
  mv "${POPULAR_COMMANDS_FILE}.tmp" "$POPULAR_COMMANDS_FILE"
  _popular_secrets_remove_for_command "$name"
  _popular_info "Removed '$name'"
}

pexport() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_pexport; return 0; }
  local dest="$1"

  _popular_ensure_file
  if [[ -z "$dest" || "$dest" == - ]]; then
    cat "$POPULAR_COMMANDS_FILE"
    return 0
  fi

  cat "$POPULAR_COMMANDS_FILE" >| "$dest" || {
    _popular_warn "pexport: could not write: $dest"
    return 1
  }
  _popular_info "Exported to '$dest'"
}

_popular_import_merge() {
  local src="$1"
  local names_tmp merged_tmp name line
  local -A imp_line last_no
  local -i n=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" != *'|'* ]] && {
      _popular_warn "pimport: skipping line (expected name|command): ${line:0:80}"
      continue
    }
    name="${line%%|*}"
    [[ -z "$name" ]] && continue
    (( n++ ))
    last_no[$name]=$n
    imp_line[$name]="$line"
  done < "$src"

  names_tmp=$(mktemp)
  chmod 600 "$names_tmp" 2>/dev/null
  merged_tmp=$(mktemp)
  chmod 600 "$merged_tmp" 2>/dev/null

  for k in ${(k)last_no}; do
    print -r -- "${last_no[$k]}:$k"
  done | sort -t: -k1,1n | cut -d: -f2- > "$names_tmp"

  awk -F'|' -v nf="$names_tmp" '
    BEGIN { while ((getline n < nf) > 0) drop[n] = 1 }
    NF && $1 != "" && !($1 in drop) { print }
  ' "$POPULAR_COMMANDS_FILE" > "$merged_tmp"

  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    print -r -- "${imp_line[$name]}" >> "$merged_tmp"
  done < "$names_tmp"

  mv "$merged_tmp" "$POPULAR_COMMANDS_FILE"
  rm -f "$names_tmp"
}

_popular_resolve_remote_url() {
  local arg="$1"
  if [[ "$arg" == http://* ]]; then
    _popular_warn "pimport: plain http:// URLs are not allowed; use https://"
    return 1
  fi
  if [[ "$arg" == https://* ]]; then
    print -r -- "$arg"
    return 0
  fi
  local owner repo branch="main" path="commands.pop"
  if [[ "$arg" == *:* ]]; then
    local base="${arg%%:*}"
    branch="${arg##*:}"
    owner="${base%%/*}"
    repo="${base#*/}"
  elif [[ "$arg" == */*/* ]]; then
    owner="${arg%%/*}"
    local rest="${arg#*/}"
    repo="${rest%%/*}"
    path="${rest#*/}"
  else
    owner="${arg%%/*}"
    repo="${arg#*/}"
  fi
  if [[ ! "$owner" =~ '^[A-Za-z0-9._-]+$' ]]; then
    _popular_warn "pimport: invalid GitHub owner name: $owner"
    return 1
  fi
  if [[ ! "$repo" =~ '^[A-Za-z0-9._-]+$' ]]; then
    _popular_warn "pimport: invalid GitHub repo name: $repo"
    return 1
  fi
  if [[ "$path" == *..* ]]; then
    _popular_warn "pimport: path traversal not allowed in remote path: $path"
    return 1
  fi
  print -r -- "https://raw.githubusercontent.com/${owner}/${repo}/${branch}/${path}"
}

pimport() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_pimport; return 0; }
  local replace=0 remote=0 src tmp_remote=""

  while [[ "$1" == -* ]]; do
    case "$1" in
      -r | --replace) replace=1 ;;
      -R | --remote)  remote=1  ;;
      *)
        _popular_warn "pimport: unknown option: $1"$'\n'"usage: pimport [-r|--replace] [-R|--remote] <file|repo>"$'\n'"run 'pimport --help' for details"
        return 1
        ;;
    esac
    shift
  done

  src="$1"
  if [[ -z "$src" ]]; then
    _popular_warn "pimport: usage: pimport [-r|--replace] [-R|--remote] <file|repo>"$'\n'"run 'pimport --help' for details"
    return 1
  fi

  if (( remote )); then
    if ! command -v curl >/dev/null 2>&1; then
      _popular_warn "pimport: curl not found (required for --remote)"
      return 1
    fi
    local url
    url="$(_popular_resolve_remote_url "$src")" || return 1
    tmp_remote=$(mktemp)
    chmod 600 "$tmp_remote" 2>/dev/null
    if ! curl -fsSL "$url" -o "$tmp_remote"; then
      _popular_warn "pimport: download failed: $url"
      rm -f "$tmp_remote"
      return 1
    fi
    _popular_info "Fetched $url"

    # Show a preview of the downloaded file and require explicit confirmation
    # before merging — remote files execute as shell commands via 'p <name>'.
    if [[ -t 1 ]]; then
      local _line_count _preview_lines=10
      _line_count=$(wc -l < "$tmp_remote")
      print -r "" >/dev/tty
      print -r "${fg[yellow]}── remote file preview (${_line_count} line(s)) ──────────────────────${reset_color}" >/dev/tty
      head -n "$_preview_lines" "$tmp_remote" | while IFS= read -r _ln; do
        print -r "  ${_ln}" >/dev/tty
      done
      if (( _line_count > _preview_lines )); then
        print -r "  ${fg[white]}… $((  _line_count - _preview_lines )) more line(s)${reset_color}" >/dev/tty
      fi
      print -r "${fg[yellow]}────────────────────────────────────────────────────────────────────${reset_color}" >/dev/tty
      print -r "" >/dev/tty
      local _answer
      print -rn -- "${fg[yellow]}Import these commands?${reset_color} [y/N] " >/dev/tty
      read -k 1 _answer </dev/tty
      print >/dev/tty
      if [[ "$_answer" != y && "$_answer" != Y ]]; then
        _popular_warn "pimport: aborted."
        rm -f "$tmp_remote"
        return 1
      fi
    fi

    src="$tmp_remote"
  fi

  if [[ ! -f "$src" || ! -r "$src" ]]; then
    _popular_warn "pimport: cannot read file: $src"
    [[ -n "$tmp_remote" ]] && rm -f "$tmp_remote"
    return 1
  fi

  _popular_ensure_file

  if (( replace )); then
    local tmp bad
    tmp=$(mktemp)
    bad=$(awk '
      /^[[:space:]]*$/ { next }
      {
        line = $0
        sub(/^[[:space:]]+/, "", line)
        sub(/[[:space:]]+$/, "", line)
        if (line == "") next
        n = index(line, "|")
        if (n == 0) { printf "%s ", NR; next }
        name = substr(line, 1, n - 1)
        if (name == "") printf "%s ", NR
      }
    ' "$src")
    awk '
      /^[[:space:]]*$/ { next }
      {
        line = $0
        sub(/^[[:space:]]+/, "", line)
        sub(/[[:space:]]+$/, "", line)
        if (line == "") next
        n = index(line, "|")
        if (n == 0) next
        name = substr(line, 1, n - 1)
        if (name == "") next
        print line
      }
    ' "$src" > "$tmp"
    [[ -n "$bad" ]] && _popular_warn "pimport: skipped invalid line(s) at: $bad"
    mv "$tmp" "$POPULAR_COMMANDS_FILE"
    _popular_import_prompt_missing_secrets "$src"
    [[ -n "$tmp_remote" ]] && rm -f "$tmp_remote"
    _popular_info "Replaced commands from '$src'"
    return 0
  fi

  _popular_import_merge "$src"
  _popular_import_prompt_missing_secrets "$src"
  [[ -n "$tmp_remote" ]] && rm -f "$tmp_remote"
  _popular_info "Merged commands from '$src'"
}
