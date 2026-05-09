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
  _popular_usage_row "p <name> [args…]" "Run: {{x}} → --x=…; [[x]] → positional; optional {{x:def}} / [[x:def]] defaults in the saved command"
  _popular_usage_row "pls [needle…]" "List saved commands (optional: filter names, substring, case-insensitive)"
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
  _popular_usage_example_line "padd lazy 'curl http://[[host:localhost]]:[[port:8080]]/health'"
  _popular_usage_example_line 'p lazy                  # uses localhost and 8080 from template'
  _popular_usage_example_line 'pls git               # list commands whose name contains "git"'
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
  local rest inner full pname def
  local -i idx
  local _ce='}}'
  local _be=']]'

  while [[ -n "$line" ]]; do
    if [[ "$line" == '{{'* ]]; then
      rest="${line#'{{'}"
      idx="${rest[(i)$_ce]}"
      if (( idx > ${#rest} )); then
        line="${line[2,-1]}"
        continue
      fi
      inner="${rest[1,$((idx - 1))]}"
      full="{{${inner}}}"
      line="${line#"$full"}"
      if [[ "$inner" == *:* ]]; then
        pname="${inner%%:*}"
        def="${inner#*:}"
      else
        pname="$inner"
        def=""
      fi
      [[ "$pname" =~ '^[A-Za-z0-9_-]+$' ]] || continue
      if [[ "$inner" == *:* ]]; then
        print -r -- $'curly\t'"$pname"$'\t'"$def"
      else
        print -r -- $'curly\t'"$pname"
      fi
    elif [[ "$line" == '[['* ]]; then
      rest="${line#'[['}"
      idx="${rest[(i)$_be]}"
      if (( idx > ${#rest} )); then
        line="${line[2,-1]}"
        continue
      fi
      inner="${rest[1,$((idx - 1))]}"
      full="[[$inner]]"
      line="${line#"$full"}"
      if [[ "$inner" == *:* ]]; then
        pname="${inner%%:*}"
        def="${inner#*:}"
      else
        pname="$inner"
        def=""
      fi
      [[ "$pname" =~ '^[A-Za-z0-9_-]+$' ]] || continue
      if [[ "$inner" == *:* ]]; then
        print -r -- $'bracket\t'"$pname"$'\t'"$def"
      else
        print -r -- $'bracket\t'"$pname"
      fi
    else
      line="${line[2,-1]}"
    fi
  done
}

_popular_build_placeholder_hint_rows() {
  emulate -L zsh -o no_xtrace 2>/dev/null || setopt local_options no_xtrace 2>/dev/null
  local cmd="$1"
  local -i box_w="$2"
  local plain_ref="$3"
  local color_ref="$4"
  local kind pname rest def
  local -a opt_names=() opt_defs=() arg_names=() arg_defs=()
  local -a _ph_plain=() _ph_color=()
  local -A seen_opt seen_arg
  local dashes vplain vcolor def_plain def_color
  local -i i j dlen

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    kind="${line%%$'\t'*}"
    rest="${line#*$'\t'}"
    if [[ "$rest" != *$'\t'* ]]; then
      pname="$rest"
      def=""
    else
      pname="${rest%%$'\t'*}"
      def="${rest#*$'\t'}"
    fi
    if [[ "$kind" == curly ]]; then
      [[ -n "${seen_opt[$pname]}" ]] && continue
      seen_opt[$pname]=1
      opt_names+=("$pname")
      opt_defs+=("$def")
    else
      [[ -n "${seen_arg[$pname]}" ]] && continue
      seen_arg[$pname]=1
      arg_names+=("$pname")
      arg_defs+=("$def")
    fi
  done < <(_popular_emit_template_slots "$cmd")

  (( ${#opt_names[@]} + ${#arg_names[@]} == 0 )) && {
    eval "${plain_ref}=()"
    eval "${color_ref}=()"
    return 0
  }

  push_row() {
    vplain="$1"
    vcolor="$2"
    inner_w=$(( box_w - 4 ))
    pad=$(( inner_w - ${#vplain} ))
    (( pad < 0 )) && pad=0
    _ph_plain+=( "│ ${vplain}$(printf '%*s' $pad '') │" )
    _ph_color+=( "${fg[blue]}│${reset_color} ${vcolor}$(printf '%*s' $pad '') ${fg[blue]}│${reset_color}" )
  }

  dlen=$(( box_w - 2 ))
  dashes=""
  for (( j = 1; j <= dlen; j++ )); do dashes+="─"; done
  _ph_plain+=( "╭${dashes}╮" )
  _ph_color+=( "${fg[blue]}╭${dashes}╮${reset_color}" )

  if (( ${#opt_names[@]} > 0 )); then
    push_row "--options:" "${fg[yellow]}--options:${reset_color}"
    for (( i = 1; i <= ${#opt_names[@]}; i++ )); do
      push_row "  • ${opt_names[i]}" "  ${fg[white]}•${reset_color} ${fg[cyan]}${opt_names[i]}${reset_color}"
      def_plain="${opt_defs[i]:-—}"
      if [[ "$def_plain" == "—" ]]; then
        def_color="${fg[white]}—${reset_color}"
      else
        def_color="${fg[green]}${def_plain}${reset_color}"
      fi
      push_row "    default: ${def_plain}" \
        "    ${fg[white]}default:${reset_color} ${def_color}"
    done
  fi

  if (( ${#opt_names[@]} > 0 && ${#arg_names[@]} > 0 )); then
    push_row "" ""
  fi

  if (( ${#arg_names[@]} > 0 )); then
    push_row "--arguments:" "${fg[yellow]}--arguments:${reset_color}"
    for (( i = 1; i <= ${#arg_names[@]}; i++ )); do
      push_row "  • ${arg_names[i]}" "  ${fg[white]}•${reset_color} ${fg[cyan]}${arg_names[i]}${reset_color}"
      def_plain="${arg_defs[i]:-—}"
      if [[ "$def_plain" == "—" ]]; then
        def_color="${fg[white]}—${reset_color}"
      else
        def_color="${fg[green]}${def_plain}${reset_color}"
      fi
      push_row "    default: ${def_plain}" \
        "    ${fg[white]}default:${reset_color} ${def_color}"
    done
  fi

  _ph_plain+=( "╰${dashes}╯" )
  _ph_color+=( "${fg[blue]}╰${dashes}╯${reset_color}" )

  set -A "$plain_ref" "${_ph_plain[@]}"
  set -A "$color_ref" "${_ph_color[@]}"
}

_popular_render_command() {
  local template="$1"
  shift

  local -A curly_needed=()
  local -a bracket_order=()
  local -A bracket_seen=()
  local -A emb_curly=()
  local -A emb_bracket=()
  local line kind pname rest def
  local arg key val escaped
  local -a pos_pool=()
  local -A curly_vals=()
  local -A bracket_vals=()
  local -a passthrough=()
  local rendered=""
  local miss tail="$template"

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    kind="${line%%$'\t'*}"
    rest="${line#*$'\t'}"
    if [[ "$rest" != *$'\t'* ]]; then
      pname="$rest"
      if [[ "$kind" == curly ]]; then
        curly_needed[$pname]=1
      else
        [[ -z "${bracket_seen[$pname]}" ]] && {
          bracket_order+=("$pname")
          bracket_seen[$pname]=1
        }
      fi
    else
      pname="${rest%%$'\t'*}"
      def="${rest#*$'\t'}"
      if [[ "$kind" == curly ]]; then
        curly_needed[$pname]=1
        emb_curly[$pname]="$def"
      else
        [[ -z "${bracket_seen[$pname]}" ]] && {
          bracket_order+=("$pname")
          bracket_seen[$pname]=1
        }
        emb_bracket[$pname]="$def"
      fi
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

  for pname in ${(k)curly_needed}; do
    [[ -n "${curly_vals[$pname]+set}" ]] && continue
    [[ -n "${emb_curly[$pname]+set}" ]] && curly_vals[$pname]="${emb_curly[$pname]}"
  done

  local -i nb=${#bracket_order}
  while (( nb > ${#pos_pool} )); do
    pname="${bracket_order[${#pos_pool} + 1]}"
    [[ -n "${emb_bracket[$pname]+set}" ]] || break
    pos_pool+=("${emb_bracket[$pname]}")
  done

  miss=()
  for pname in ${(k)curly_needed}; do
    [[ -n "${curly_vals[$pname]+set}" ]] && continue
    miss+=("--${pname}=…")
  done
  if (( ${#miss[@]} > 0 )); then
    _popular_warn "p: missing option(s): ${(j:, :)miss}"
    return 1
  fi

  if (( nb > ${#pos_pool} )); then
    _popular_warn "p: missing positional argument(s) for: ${(j:, :)bracket_order}"
    return 1
  fi

  local -i i
  for (( i = 1; i <= nb; i++ )); do
    bracket_vals[${bracket_order[i]}]="${pos_pool[i]}"
  done

  (( nb < ${#pos_pool} )) && passthrough=("${(@)pos_pool[$((nb + 1)),-1]}")

  local tw_rest tw_inner tw_full tw_name
  local -i tw_idx
  local _ce='}}'
  local _be=']]'
  while [[ -n "$tail" ]]; do
    if [[ "$tail" == '{{'* ]]; then
      tw_rest="${tail#'{{'}"
      tw_idx="${tw_rest[(i)$_ce]}"
      if (( tw_idx > ${#tw_rest} )); then
        rendered+="${tail[1]}"
        tail="${tail[2,-1]}"
        continue
      fi
      tw_inner="${tw_rest[1,$((tw_idx - 1))]}"
      tw_full="{{${tw_inner}}}"
      tw_name="${tw_inner%%:*}"
      [[ "$tw_inner" == *:* ]] || tw_name="$tw_inner"
      rendered+="${(q)curly_vals[$tw_name]}"
      tail="${tail#"$tw_full"}"
    elif [[ "$tail" == '[['* ]]; then
      tw_rest="${tail#'[['}"
      tw_idx="${tw_rest[(i)$_be]}"
      if (( tw_idx > ${#tw_rest} )); then
        rendered+="${tail[1]}"
        tail="${tail[2,-1]}"
        continue
      fi
      tw_inner="${tw_rest[1,$((tw_idx - 1))]}"
      tw_full="[[$tw_inner]]"
      tw_name="${tw_inner%%:*}"
      [[ "$tw_inner" == *:* ]] || tw_name="$tw_inner"
      rendered+="${(q)bracket_vals[$tw_name]}"
      tail="${tail#"$tw_full"}"
    else
      rendered+="${tail[1]}"
      tail="${tail[2,-1]}"
    fi
  done

  for arg in "${passthrough[@]}"; do
    rendered+=" ${(q)arg}"
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
  local count max_name line name command preview name_pad empty_pad
  local first gap needle nlow ilow
  local -i pw oi shown hi
  local -a rows=() ochunks=() filtered=() hint_plain hint_color

  _popular_ensure_file
  if [[ ! -s "$POPULAR_COMMANDS_FILE" ]]; then
    _popular_note "No saved commands yet."
    return 0
  fi

  needle="$*"
  needle="${needle#"${needle%%[![:space:]]*}"}"
  needle="${needle%"${needle##*[![:space:]]}"}"

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

  if [[ -n "$needle" ]]; then
    nlow="${needle:l}"
    filtered=()
    for line in "${rows[@]}"; do
      name="${line%%|*}"
      ilow="${name:l}"
      [[ "$ilow" == *${(b)nlow}* ]] && filtered+=("$line")
    done
    rows=( "${filtered[@]}" )
    max_name=12
    for line in "${rows[@]}"; do
      name="${line%%|*}"
      [[ -n "$name" ]] || continue
      (( ${#name} > max_name )) && max_name=${#name}
    done
    shown=${#rows[@]}
    if (( shown == 0 )); then
      _popular_note "No commands match: $needle"
      return 0
    fi
  fi

  print
  if [[ -n "$needle" ]]; then
    print -r -- "${fg[cyan]}Popular Commands${reset_color} ${fg[white]}${shown} matching · ${count} saved${reset_color} ${fg[yellow]}($needle)${reset_color}"
  else
    print -r -- "${fg[cyan]}Popular Commands${reset_color} ${fg[white]}$count saved${reset_color}"
  fi
  print -r -- "${fg[blue]}╭${_POPULAR_RULE78}╮${reset_color}"

  for line in "${rows[@]}"; do
    name="${line%%|*}"
    command="${line#*|}"
    preview="$command"
    name_pad=$(printf "%-${max_name}s" "$name")
    empty_pad=$(printf "%-${max_name}s" "")

    pw=$(( _POPULAR_BOX_INNER - 4 - max_name ))
    (( pw < 12 )) && pw=12

    _popular_build_placeholder_hint_rows "$command" "$pw" hint_plain hint_color

    first=1
    ochunks=("${(@f)$( _popular_wrap_fill "$preview" "$pw" )}")
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

    for (( hi = 1; hi <= ${#hint_plain}; hi++ )); do
      if (( first )); then
        _popular_box_inner_line \
          " ${name_pad} │ ${hint_plain[hi]}" \
          " ${fg[green]}${name_pad}${reset_color} ${fg[blue]}│${reset_color} ${hint_color[hi]}"
      else
        _popular_box_inner_line \
          " ${empty_pad} │ ${hint_plain[hi]}" \
          " ${fg[white]}${empty_pad}${reset_color} ${fg[blue]}│${reset_color} ${hint_color[hi]}"
      fi
      first=0
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
  local label="${1:-saved command}"
  local -a entries
  entries=("${(@f)$(_popular_names)}")
  _describe "$label" entries
}

_popular_complete_pls() {
  (( CURRENT >= 2 )) || return 1
  _popular_complete_saved_names 'pls filter'
}

_popular_complete_template_options() {
  local name="$1"
  local command kind pname rest def
  local -a options=()
  local word used
  local -A seen_c

  command=$(_popular_get_command "$name") || return 1

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    kind="${line%%$'\t'*}"
    [[ "$kind" != curly ]] && continue
    rest="${line#*$'\t'}"
    if [[ "$rest" != *$'\t'* ]]; then
      pname="$rest"
      [[ -n "${seen_c[$pname]}" ]] && continue
      seen_c[$pname]=1
      used=0
      for word in "${words[@]:2}"; do
        if [[ "$word" == --${pname} || "$word" == --${pname}=* ]]; then
          used=1
          break
        fi
      done
      (( used )) && continue
      options+=("--${pname}=")
    else
      pname="${rest%%$'\t'*}"
      def="${rest#*$'\t'}"
      [[ -n "${seen_c[$pname]}" ]] && continue
      seen_c[$pname]=1
      used=0
      for word in "${words[@]:2}"; do
        if [[ "$word" == --${pname} || "$word" == --${pname}=* ]]; then
          used=1
          break
        fi
      done
      (( used )) && continue
      options+=("--${pname}=${def}")
    fi
  done < <(_popular_emit_template_slots "$command")

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
    compdef _popular_complete_pls pls

    _popular_complete_pedit() {
      (( CURRENT == 2 )) || return 1
      _popular_complete_saved_names
    }
    compdef _popular_complete_pedit pedit
    compdef _files pexport pimport
    compdef _nothing paddh
  fi
fi
