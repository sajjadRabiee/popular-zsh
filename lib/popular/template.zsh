# lib/popular/template.zsh

_popular_validate_slot() {
  local label="$1" val="$2" typ="$3"
  local -a allowed
  local v
  if [[ "$typ" == int ]]; then
    if ! [[ "$val" =~ ^-?[0-9]+$ ]]; then
      _popular_warn "p: '${label}' expects an integer, got '${val}'"
      return 1
    fi
  elif [[ "$typ" == path ]]; then
    if [[ ! -e "$val" ]]; then
      _popular_warn "p: '${label}' path does not exist: ${val}"
      return 1
    fi
  elif [[ "$typ" == enum=* ]]; then
    allowed=("${(s:|:)${typ#enum=}}")
    for v in "${allowed[@]}"; do [[ "$v" == "$val" ]] && return 0; done
    _popular_warn "p: '${label}' must be one of: ${(j:, :)allowed} — got '${val}'"
    return 1
  fi
  return 0
}

_popular_emit_template_slots() {
  local line="$1"
  local rest inner full pname def
  local -i idx
  local _ce='}}'
  local _be=']]'
  local _se='>>'

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
        if [[ "$def" == int || "$def" == path ]]; then
          print -r -- $'curly\t'"$pname"$'\t\t'"$def"
        elif [[ "$def" == enum=* ]]; then
          if [[ -z "${def#enum=}" ]]; then
            print -r -- "p: warning: empty enum values for '${pname}'" >&2
          else
            print -r -- $'curly\t'"$pname"$'\t\t'"$def"
          fi
        else
          print -r -- $'curly\t'"$pname"$'\t'"$def"
        fi
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
        if [[ "$def" == int || "$def" == path ]]; then
          print -r -- $'bracket\t'"$pname"$'\t\t'"$def"
        elif [[ "$def" == enum=* ]]; then
          if [[ -z "${def#enum=}" ]]; then
            print -r -- "p: warning: empty enum values for '${pname}'" >&2
          else
            print -r -- $'bracket\t'"$pname"$'\t\t'"$def"
          fi
        else
          print -r -- $'bracket\t'"$pname"$'\t'"$def"
        fi
      else
        print -r -- $'bracket\t'"$pname"
      fi
    elif [[ "$line" == '<<'* ]]; then
      rest="${line#'<<'}"
      idx="${rest[(i)$_se]}"
      if (( idx > ${#rest} )); then
        line="${line[2,-1]}"
        continue
      fi
      inner="${rest[1,$((idx - 1))]}"
      full="<<${inner}>>"
      line="${line#"$full"}"
      [[ "$inner" =~ '^[A-Za-z0-9_-]+$' ]] || continue
      print -r -- $'secret\t'"$inner"
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
  local kind pname rest def typ
  local -a opt_names=() opt_defs=() opt_types=() arg_names=() arg_defs=() arg_types=() secret_names=()
  local -a _ph_plain=() _ph_color=()
  local -A seen_opt seen_arg seen_secret
  local dashes vplain vcolor def_plain def_color
  local -i i j dlen

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    kind="${line%%$'\t'*}"
    rest="${line#*$'\t'}"
    if [[ "$rest" != *$'\t'* ]]; then
      pname="$rest"; def=""; typ=""
    elif [[ "${rest#*$'\t'}" == $'\t'* ]]; then
      pname="${rest%%$'\t'*}"; def=""; typ="${rest#*$'\t\t'}"
    else
      pname="${rest%%$'\t'*}"; def="${rest#*$'\t'}"; typ=""
    fi
    if [[ "$kind" == curly ]]; then
      [[ -n "${seen_opt[$pname]}" ]] && continue
      seen_opt[$pname]=1
      opt_names+=("$pname")
      opt_defs+=("$def")
      opt_types+=("$typ")
    elif [[ "$kind" == secret ]]; then
      [[ -n "${seen_secret[$pname]}" ]] && continue
      seen_secret[$pname]=1
      secret_names+=("$pname")
    else
      [[ -n "${seen_arg[$pname]}" ]] && continue
      seen_arg[$pname]=1
      arg_names+=("$pname")
      arg_defs+=("$def")
      arg_types+=("$typ")
    fi
  done < <(_popular_emit_template_slots "$cmd")

  (( ${#opt_names[@]} + ${#arg_names[@]} + ${#secret_names[@]} == 0 )) && {
    eval "${plain_ref}=()"
    eval "${color_ref}=()"
    return 0
  }

  push_row() {
    vplain="$1"
    vcolor="$2"
    inner_w=$(( box_w - 4 ))
    # Plain and vcolor must represent the same visible text so pls outer borders stay aligned.
    if (( inner_w > 1 && ${#vplain} > inner_w )); then
      vplain="${vplain[1,$((inner_w - 1))]}…"
      vcolor="${fg[white]}${vplain}${reset_color}"
    fi
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
      local _th_plain="" _th_color="" _hint_text=""
      if [[ -n "${opt_types[i]}" ]]; then
        if [[ "${opt_types[i]}" == enum=* ]]; then
          local -a _ev=("${(s:|:)${opt_types[i]#enum=}}")
          _hint_text="${(j: | :)_ev}"
        else
          _hint_text="${opt_types[i]}"
        fi
        _th_plain="  (${_hint_text})"
        _th_color="  ${fg[yellow]}(${_hint_text})${reset_color}"
      fi
      push_row "  • ${opt_names[i]}${_th_plain}" "  ${fg[white]}•${reset_color} ${fg[cyan]}${opt_names[i]}${reset_color}${_th_color}"
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
      local _th_plain="" _th_color="" _hint_text=""
      if [[ -n "${arg_types[i]}" ]]; then
        if [[ "${arg_types[i]}" == enum=* ]]; then
          local -a _ev=("${(s:|:)${arg_types[i]#enum=}}")
          _hint_text="${(j: | :)_ev}"
        else
          _hint_text="${arg_types[i]}"
        fi
        _th_plain="  (${_hint_text})"
        _th_color="  ${fg[yellow]}(${_hint_text})${reset_color}"
      fi
      push_row "  • ${arg_names[i]}${_th_plain}" "  ${fg[white]}•${reset_color} ${fg[cyan]}${arg_names[i]}${reset_color}${_th_color}"
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

  if (( ${#secret_names[@]} > 0 )); then
    if (( ${#opt_names[@]} > 0 || ${#arg_names[@]} > 0 )); then
      push_row "" ""
    fi
    push_row "--secrets:" "${fg[red]}--secrets:${reset_color}"
    for (( i = 1; i <= ${#secret_names[@]}; i++ )); do
      push_row "  • <<${secret_names[i]}>> · psecret -g" \
        "  ${fg[white]}•${reset_color} ${fg[red]}<<${secret_names[i]}>>${reset_color} ${fg[white]}· psecret -g${reset_color}"
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
  local -A slot_types=()
  local line kind pname rest def typ _has_def
  local -i typ_err=0
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
    [[ "$kind" == secret ]] && continue
    rest="${line#*$'\t'}"
    if [[ "$rest" != *$'\t'* ]]; then
      pname="$rest"; def=""; typ=""; _has_def=""
    elif [[ "${rest#*$'\t'}" == $'\t'* ]]; then
      pname="${rest%%$'\t'*}"; def=""; typ="${rest#*$'\t\t'}"; _has_def=""
    else
      pname="${rest%%$'\t'*}"; def="${rest#*$'\t'}"; typ=""; _has_def=1
    fi
    [[ -n "$typ" ]] && slot_types[$pname]="$typ"
    if [[ "$kind" == curly ]]; then
      curly_needed[$pname]=1
      [[ -n "$_has_def" ]] && emb_curly[$pname]="$def"
    else
      [[ -z "${bracket_seen[$pname]}" ]] && {
        bracket_order+=("$pname")
        bracket_seen[$pname]=1
      }
      [[ -n "$_has_def" ]] && emb_bracket[$pname]="$def"
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

  typ_err=0
  for pname in ${(k)curly_needed}; do
    [[ -z "${slot_types[$pname]}" ]] && continue
    _popular_validate_slot "--${pname}" "${curly_vals[$pname]}" "${slot_types[$pname]}" || typ_err=1
  done
  local -i _bvi
  for (( _bvi = 1; _bvi <= ${#bracket_order}; _bvi++ )); do
    pname="${bracket_order[$_bvi]}"
    [[ -z "${slot_types[$pname]}" ]] && continue
    _popular_validate_slot "${pname}" "${bracket_vals[$pname]}" "${slot_types[$pname]}" || typ_err=1
  done
  [[ $typ_err -ne 0 ]] && return 1

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
