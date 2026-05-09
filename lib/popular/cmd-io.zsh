# lib/popular/cmd-io.zsh

premove() {
  local name="$1"

  if [[ -z "$name" ]]; then
    _popular_warn "premove: usage: premove <name>"
    return 1
  fi

  _popular_ensure_file
  awk -F'|' -v name="$name" '$1 != name' "$POPULAR_COMMANDS_FILE" > "${POPULAR_COMMANDS_FILE}.tmp"
  mv "${POPULAR_COMMANDS_FILE}.tmp" "$POPULAR_COMMANDS_FILE"
  _popular_info "Removed '$name'"
}

pexport() {
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
  merged_tmp=$(mktemp)

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

pimport() {
  local replace=0 src

  while [[ "$1" == -* ]]; do
    case "$1" in
      -r | --replace) replace=1 ;;
      *)
        _popular_warn "pimport: unknown option: $1"
        _popular_warn "pimport: usage: pimport [-r|--replace] <file>"
        return 1
        ;;
    esac
    shift
  done

  src="$1"
  if [[ -z "$src" ]]; then
    _popular_warn "pimport: usage: pimport [-r|--replace] <file>"
    return 1
  fi

  if [[ ! -f "$src" || ! -r "$src" ]]; then
    _popular_warn "pimport: cannot read file: $src"
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
    _popular_info "Replaced commands from '$src'"
    return 0
  fi

  _popular_import_merge "$src"
  _popular_info "Merged commands from '$src'"
}
