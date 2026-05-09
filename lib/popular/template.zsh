# lib/popular/template.zsh

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
