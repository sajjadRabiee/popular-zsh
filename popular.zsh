# popular.zsh
# A tiny zsh helper for saving and reusing your favorite commands.

: "${POPULAR_COMMANDS_FILE:=$HOME/.popular_commands}"

autoload -Uz colors
colors

_POPULAR_RULE78='──────────────────────────────────────────────────────────────────────────────'

_POPULAR_BOX_INNER=78

_popular_box_inner_line() {
  local plain="$1"
  local colored="$2"
  local -i pad=$(( _POPULAR_BOX_INNER - ${#plain} ))
  (( pad < 0 )) && pad=0
  print -rn -- "${fg[blue]}│${reset_color}${colored}"
  printf '%*s' $pad ''
  print -r -- "${fg[blue]}│${reset_color}"
}

_popular_wrap_fill() {
  setopt local_options no_xtrace 2>/dev/null
  local text="$1"
  local width="$2"
  local -a lines
  local -i li

  if [[ -z "$text" ]]; then
    print ""
    return 0
  fi

  lines=("${(@f)text}")
  for (( li = 1; li <= ${#lines}; li++ )); do
    if [[ -z "${lines[li]}" ]]; then
      print ""
      continue
    fi
    fold -s -w "$width" <<< "${lines[li]}"
  done
}

_popular_usage_sep() {
  local dash76="${_POPULAR_RULE78[1,76]}"
  local plain=" ${dash76} "
  local colored=" ${fg[white]}${dash76}${reset_color} "
  _popular_box_inner_line "$plain" "$colored"
}

_popular_usage_box_top() {
  print -r -- "${fg[blue]}╭${_POPULAR_RULE78}╮${reset_color}"
}

_popular_usage_box_bot() {
  print -r -- "${fg[blue]}╰${_POPULAR_RULE78}╯${reset_color}"
}

_popular_usage_row() {
  local syn="$1"
  local desc="$2"
  local syn_pad cont_pad
  local -a chunks
  local first=1
  local -i chunk_w=$(( _POPULAR_BOX_INNER - 40 ))
  local -i ci
  (( chunk_w < 8 )) && chunk_w=8

  syn_pad=$(printf '%-34s' "$syn")
  cont_pad=$(printf '%34s' '')

  chunks=("${(@f)$( _popular_wrap_fill "$desc" "$chunk_w" )}")
  for (( ci = 1; ci <= ${#chunks}; ci++ )); do
    [[ -z "${chunks[ci]//[[:space:]]/}" ]] && continue
    if (( first )); then
      _popular_box_inner_line \
        "  ${syn_pad} │  ${chunks[ci]}" \
        "  ${fg[magenta]}${syn_pad}${reset_color} ${fg[blue]}│${reset_color}  ${fg[white]}${chunks[ci]}${reset_color}"
      first=0
    else
      _popular_box_inner_line \
        "  ${cont_pad} │  ${chunks[ci]}" \
        "  ${fg[magenta]}${cont_pad}${reset_color} ${fg[blue]}│${reset_color}  ${fg[white]}${chunks[ci]}${reset_color}"
    fi
  done
}

_popular_usage_example_line() {
  local ex="$1"
  local -a chunks
  local -i chunk_w=$(( _POPULAR_BOX_INNER - 5 ))
  local -i ci
  (( chunk_w < 8 )) && chunk_w=8

  chunks=("${(@f)$( _popular_wrap_fill "$ex" "$chunk_w" )}")
  for (( ci = 1; ci <= ${#chunks}; ci++ )); do
    [[ -z "${chunks[ci]//[[:space:]]/}" ]] && continue
    _popular_box_inner_line \
      "     ${chunks[ci]}" \
      "     ${fg[green]}${chunks[ci]}${reset_color}"
  done
}

_popular_usage() {
  emulate -L zsh -o no_xtrace 2>/dev/null || setopt local_options no_xtrace 2>/dev/null
  print
  _popular_usage_box_top
  local title_plain='popular.zsh · bookmark and run shell commands'
  local -i title_chunk_w=$(( _POPULAR_BOX_INNER - 2 ))
  (( title_chunk_w < 8 )) && title_chunk_w=8
  local -a chunks
  local -i ti
  local inner_plain inner_colored

  if (( ${#title_plain} + 2 > _POPULAR_BOX_INNER )); then
    chunks=("${(@f)$( _popular_wrap_fill "$title_plain" "$title_chunk_w" )}")
    for (( ti = 1; ti <= ${#chunks}; ti++ )); do
      [[ -z "${chunks[ti]//[[:space:]]/}" ]] && continue
      inner_plain="  ${chunks[ti]}"
      inner_colored="  ${fg[cyan]}${chunks[ti]}${reset_color}"
      _popular_box_inner_line "$inner_plain" "$inner_colored"
    done
  else
    inner_plain="  ${title_plain}"
    inner_colored="  ${fg[cyan]}popular.zsh${reset_color}  ${fg[white]}· bookmark and run shell commands${reset_color}"
    _popular_box_inner_line "$inner_plain" "$inner_colored"
  fi
  _popular_usage_box_bot
  print
  _popular_usage_box_top
  inner_plain='  Commands'
  inner_colored="  ${fg[yellow]}Commands${reset_color}"
  _popular_box_inner_line "$inner_plain" "$inner_colored"
  _popular_usage_sep
  _popular_usage_row "padd <name> <command…>" "Save a command"
  _popular_usage_row "paddh <#> [name]" "Save from history (event # from \`history\`; default name h<#>)"
  _popular_usage_row "p <name> [args…]" "Run: {{x}} → --x=…; [[x]] → positional (order matches template)"
  _popular_usage_row "pls" "List saved commands"
  _popular_usage_row "premove <name>" "Delete a saved command"
  _popular_usage_row "pexport [file|-]" "Export (\`-\` or empty → stdout)"
  _popular_usage_row "pimport [-r|--replace] <file>" "Import (merge, or replace store)"
  _popular_usage_row "pedit [name]" "Edit store in \${EDITOR:-vim}, or one command’s text"
  _popular_usage_row "phelp" "Show this help"
  _popular_usage_sep
  inner_plain='  Examples'
  inner_colored="  ${fg[yellow]}Examples${reset_color}"
  _popular_box_inner_line "$inner_plain" "$inner_colored"
  _popular_usage_sep
  _popular_usage_example_line 'padd gs git status'
  _popular_usage_example_line 'paddh 233 gs          # save event 233 as "gs"'
  _popular_usage_example_line 'paddh -1              # previous command as "h-1"'
  _popular_usage_example_line "padd serve 'python3 -m http.server [[port]]'"
  _popular_usage_example_line 'p gs'
  _popular_usage_example_line 'p serve 8000'
  _popular_usage_example_line 'p serve --port=8000   # when saved with {{port}}'
  _popular_usage_box_bot
  print
}

_popular_ensure_file() {
  [[ -f "$POPULAR_COMMANDS_FILE" ]] || : > "$POPULAR_COMMANDS_FILE"
}

_popular_command_encode() {
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//|/\\|}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  print -r -- "$s"
}

_popular_command_decode() {
  local rest="$1" out="" char esc

  while [[ -n "$rest" ]]; do
    char="${rest[1]}"
    rest="${rest[2,-1]}"
    if [[ "$char" == '\' && -n "$rest" ]]; then
      esc="${rest[1]}"
      rest="${rest[2,-1]}"
      case "$esc" in
        '|') out+='|' ;;
        '\\') out+='\' ;;
        'n') out+=$'\n' ;;
        'r') out+=$'\r' ;;
        *) out+='\'"$esc" ;;
      esac
    else
      out+="$char"
    fi
  done
  print -r -- "$out"
}

_popular_save_entry() {
  local name="$1"
  local cmd="$2"

  cmd=$(_popular_command_encode "$cmd")

  _popular_ensure_file
  awk -F'|' -v name="$name" '$1 != name' "$POPULAR_COMMANDS_FILE" > "${POPULAR_COMMANDS_FILE}.tmp"
  mv "${POPULAR_COMMANDS_FILE}.tmp" "$POPULAR_COMMANDS_FILE"
  print -r -- "$name|$cmd" >> "$POPULAR_COMMANDS_FILE"
}

_popular_get_history_command() {
  local n="$1"
  local line ev

  [[ "$n" =~ '^-?[0-9]+$' ]] || return 1

  if [[ "$n" == -* ]]; then
    (( HISTCMD > 0 )) || return 1
    ev=$(( HISTCMD + n ))
    (( ev >= 1 )) || return 1
    line=$(builtin fc -ln "$ev" "$ev" 2>/dev/null) || return 1
  else
    line=$(builtin fc -ln "$n" "$n" 2>/dev/null) || return 1
  fi

  line="${line//$'\r'/}"
  line="${line//$'\n'/}"

  [[ -n "$line" ]] || return 1
  print -r -- "$line"
}

_popular_info() {
  print -r -- "${fg[green]}$1${reset_color}"
}

_popular_warn() {
  print -u2 -r -- "${fg[red]}$1${reset_color}"
}

_popular_note() {
  print -r -- "${fg[white]}$1${reset_color}"
}

_popular_names() {
  _popular_ensure_file
  awk -F'|' 'NF { print $1 }' "$POPULAR_COMMANDS_FILE"
}

_popular_get_command() {
  local name="$1"
  local line cmd

  _popular_ensure_file
  line=$(awk -F'|' -v name="$name" '$1 == name { line = $0 } END { print line }' "$POPULAR_COMMANDS_FILE")
  [[ -n "$line" ]] || return 1
  cmd="${line#*|}"
  cmd=$(_popular_command_decode "$cmd")
  print -r -- "$cmd"
}

_popular_emit_template_slots() {
  local line="$1"

  while [[ -n "$line" ]]; do
    if [[ "$line" =~ '^\{\{([A-Za-z0-9_-]+)\}\}' ]]; then
      print -r -- "curly:${match[1]}"
      line="${line#$MATCH}"
    elif [[ "$line" =~ '^\[\[([A-Za-z0-9_-]+)\]\]' ]]; then
      print -r -- "bracket:${match[1]}"
      line="${line#$MATCH}"
    else
      line="${line[2,-1]}"
    fi
  done
}

_popular_placeholder_summary() {
  local command="$1"
  local kind pname
  local -a items=()
  local -A seen

  while IFS=: read -r kind pname; do
    [[ -n "${seen[$pname]}" ]] && continue
    seen[$pname]=1
    if [[ "$kind" == bracket ]]; then
      items+=("[[${pname}]]")
    else
      items+=("{{${pname}}}")
    fi
  done < <(_popular_emit_template_slots "$command")

  if (( ${#items[@]} > 0 )); then
    print -r -- "${(j:, :)items}"
  fi
}

_popular_render_command() {
  local template="$1"
  shift

  local -A curly_needed=()
  local -a bracket_order=()
  local -A bracket_seen=()
  local kind pname
  local arg key val escaped
  local -a pos_pool=()
  local -A curly_vals=()
  local -A bracket_vals=()
  local -a passthrough=()
  local rendered="$template"
  local miss

  while IFS=: read -r kind pname; do
    if [[ "$kind" == curly ]]; then
      curly_needed[$pname]=1
    elif [[ "$kind" == bracket ]]; then
      [[ -z "${bracket_seen[$pname]}" ]] && {
        bracket_order+=("$pname")
        bracket_seen[$pname]=1
      }
    fi
  done < <(_popular_emit_template_slots "$template")

  while [[ $# -gt 0 ]]; do
    arg="$1"
    shift

    if [[ "$arg" == --*=* ]]; then
      key="${arg%%=*}"
      key="${key#--}"
      val="${arg#*=}"
      if [[ -n "${curly_needed[$key]}" ]]; then
        curly_vals[$key]="$val"
      else
        pos_pool+=("$arg")
      fi
      continue
    fi

    if [[ "$arg" == --* ]]; then
      key="${arg#--}"
      if [[ -n "${curly_needed[$key]}" && $# -gt 0 ]]; then
        curly_vals[$key]="$1"
        shift
      else
        pos_pool+=("$arg")
      fi
      continue
    fi

    pos_pool+=("$arg")
  done

  miss=()
  for pname in ${(k)curly_needed}; do
    [[ -z "${curly_vals[$pname]}" ]] && miss+=("--${pname}=…")
  done
  if (( ${#miss[@]} > 0 )); then
    _popular_warn "p: missing option(s): ${(j:, :)miss}"
    return 1
  fi

  local -i nb=${#bracket_order}
  if (( nb > ${#pos_pool} )); then
    _popular_warn "p: missing positional argument(s) for: ${(j:, :)bracket_order}"
    return 1
  fi

  local -i i
  for (( i = 1; i <= nb; i++ )); do
    bracket_vals[${bracket_order[i]}]="${pos_pool[i]}"
  done

  (( nb < ${#pos_pool} )) && passthrough=("${(@)pos_pool[$((nb + 1)),-1]}")

  for pname in ${(k)curly_vals}; do
    escaped=$(printf '%q' "${curly_vals[$pname]}")
    rendered="${rendered//\{\{$pname\}\}/$escaped}"
  done
  for pname in ${(k)bracket_vals}; do
    escaped=$(printf '%q' "${bracket_vals[$pname]}")
    rendered="${rendered//\[\[$pname\]\]/$escaped}"
  done

  for arg in "${passthrough[@]}"; do
    rendered+=" $(printf '%q' "$arg")"
  done

  print -r -- "$rendered"
}

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

pls() {
  emulate -L zsh -o no_xtrace 2>/dev/null || setopt local_options no_xtrace 2>/dev/null
  local count max_name line name command options preview name_pad empty_pad hints display
  local first gap
  local -i pw oi
  local -a rows=() ochunks=()

  _popular_ensure_file
  if [[ ! -s "$POPULAR_COMMANDS_FILE" ]]; then
    _popular_note "No saved commands yet."
    return 0
  fi

  count=$(_popular_names | wc -l | tr -d ' ')
  max_name=12

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" != *'|'* ]] && continue
    name="${line%%|*}"
    command="${line#*|}"
    command=$(_popular_command_decode "$command")
    [[ -n "$name" ]] || continue
    (( ${#name} > max_name )) && max_name=${#name}
    rows+=("$name|$command")
  done < "$POPULAR_COMMANDS_FILE"

  print
  print -r -- "${fg[cyan]}Popular Commands${reset_color} ${fg[white]}$count saved${reset_color}"
  print -r -- "${fg[blue]}╭${_POPULAR_RULE78}╮${reset_color}"

  for line in "${rows[@]}"; do
    name="${line%%|*}"
    command="${line#*|}"
    hints=$(_popular_placeholder_summary "$command")
    preview=$(printf '%s\n' "$command" | sed -e 's/{{[A-Za-z0-9_-]\{1,\}}}/<value>/g' -e 's/\[\[[A-Za-z0-9_-]\{1,\}\]\]/<value>/g')
    display="$preview"
    [[ -n "$hints" ]] && display="$preview"$'\n'"$hints"
    name_pad=$(printf "%-${max_name}s" "$name")
    empty_pad=$(printf "%-${max_name}s" "")

    pw=$(( _POPULAR_BOX_INNER - 4 - max_name ))
    (( pw < 12 )) && pw=12

    first=1
    ochunks=("${(@f)$( _popular_wrap_fill "$display" "$pw" )}")
    for (( oi = 1; oi <= ${#ochunks}; oi++ )); do
      [[ -z "${ochunks[oi]//[[:space:]]/}" ]] && continue
      if (( first )); then
        _popular_box_inner_line \
          " ${name_pad} │ ${ochunks[oi]}" \
          " ${fg[green]}${name_pad}${reset_color} ${fg[blue]}│${reset_color} ${ochunks[oi]}"
        first=0
      else
        _popular_box_inner_line \
          " ${empty_pad} │ ${ochunks[oi]}" \
          " ${fg[white]}${empty_pad}${reset_color} ${fg[blue]}│${reset_color} ${ochunks[oi]}"
      fi
    done

    if (( first )); then
      _popular_box_inner_line \
        " ${name_pad} │ " \
        " ${fg[green]}${name_pad}${reset_color} ${fg[blue]}│${reset_color} "
    fi

    gap=$(printf '%*s' "$_POPULAR_BOX_INNER" '')
    _popular_box_inner_line "$gap" "$gap"
  done

  print -r -- "${fg[blue]}╰${_POPULAR_RULE78}╯${reset_color}"
  print
}

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

pedit() {
  local name="$1"
  local cmd tmp ed st

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

  tmp=$(mktemp "${TMPDIR:-/tmp}/popular-pedit.XXXXXX") || {
    _popular_warn "pedit: could not create temp file"
    return 1
  }

  print -r -- "$cmd" > "$tmp"
  "$ed" "$tmp"
  st=$?

  cmd="$(cat "$tmp")"
  cmd="${cmd//$'\r'/}"
  rm -f "$tmp"

  if (( st != 0 )); then
    _popular_warn "pedit: editor exited $st; changes not saved"
    return $st
  fi

  if [[ -z "${cmd//[[:space:]]/}" ]]; then
    _popular_warn "pedit: empty buffer; not saving (use premove to delete '$name')"
    return 1
  fi

  _popular_save_entry "$name" "$cmd"
  _popular_info "Updated '$name'"
}

phelp() {
  _popular_usage
}

_popular_complete_saved_names() {
  local -a entries
  entries=("${(@f)$(_popular_names)}")
  _describe 'saved command' entries
}

_popular_complete_template_options() {
  local name="$1"
  local command kind pname
  local -a placeholders=()
  local -a options=()
  local word used
  local -A seen_c

  command=$(_popular_get_command "$name") || return 1

  while IFS=: read -r kind pname; do
    [[ "$kind" == curly ]] || continue
    [[ -n "${seen_c[$pname]}" ]] && continue
    seen_c[$pname]=1
    placeholders+=("$pname")
  done < <(_popular_emit_template_slots "$command")

  (( ${#placeholders[@]} > 0 )) || return 1

  for placeholder in "${placeholders[@]}"; do
    used=0
    for word in "${words[@]:2}"; do
      if [[ "$word" == --${placeholder} || "$word" == --${placeholder}=* ]]; then
        used=1
        break
      fi
    done

    (( used )) && continue
    options+=("--${placeholder}=")
  done

  (( ${#options[@]} > 0 )) || return 1
  _describe 'template option' options
}

_popular_complete_p() {
  if (( CURRENT == 2 )); then
    _popular_complete_saved_names
    return
  fi

  if (( CURRENT >= 3 )); then
    _popular_complete_template_options "${words[2]}"
    return
  fi
}

if [[ -o interactive ]]; then
  if ! whence compdef >/dev/null 2>&1; then
    autoload -Uz compinit
    compinit -i >/dev/null 2>&1
  fi

  if whence compdef >/dev/null 2>&1; then
    compdef _popular_complete_p p
    compdef _popular_complete_saved_names premove

    _popular_complete_pedit() {
      (( CURRENT == 2 )) || return 1
      _popular_complete_saved_names
    }
    compdef _popular_complete_pedit pedit
    compdef _files pexport pimport
    compdef _nothing paddh
  fi
fi
