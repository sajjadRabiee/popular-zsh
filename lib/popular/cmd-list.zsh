# lib/popular/cmd-list.zsh

pls() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_pls; return 0; }
  setopt local_options no_xtrace
  _popular_set_box_width
  local count max_name line name command preview name_pad empty_pad
  local first gap needle nlow ilow rest raw_cmd raw_flags raw_tags tag_filter
  local -i pw oi shown hi
  local -a rows=() row_flags=() row_tags=() ochunks=() filtered=() filtered_flags=() filtered_tags=() hint_plain hint_color

  tag_filter=""
  if [[ "${1:-}" == -t ]]; then
    if [[ $# -lt 2 || -z "${2:-}" ]]; then
      _popular_warn "pls: -t requires a tag value"$'\n'"run 'pls --help' for details"
      return 1
    fi
    tag_filter="$2"
    shift 2
  fi

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
    rest="${line#*|}"
    if [[ "$rest" == *'|'* ]]; then
      local last="${rest##*|}"
      if [[ "$last" == t:* ]]; then
        raw_tags="${last#t:}"
        rest="${rest%|*}"
        raw_flags="${rest##*|}"
        raw_cmd="${rest%|*}"
      else
        raw_tags=""
        raw_flags="$last"
        raw_cmd="${rest%|*}"
      fi
    else
      raw_cmd="$rest"
      raw_flags=""
      raw_tags=""
    fi
    command=$(_popular_command_decode "$raw_cmd")
    [[ -n "$name" ]] || continue
    (( ${#name} > max_name )) && max_name=${#name}
    rows+=("$name|$command")
    row_flags+=("$raw_flags")
    row_tags+=("$raw_tags")
  done < "$POPULAR_COMMANDS_FILE"

  if [[ -n "$tag_filter" ]]; then
    local tflow="${tag_filter:l}"
    local rtags t match
    filtered=()
    filtered_flags=()
    filtered_tags=()
    for (( ri = 1; ri <= ${#rows[@]}; ri++ )); do
      rtags="${row_tags[$ri]:-}"
      match=0
      for t in "${(s:,:)rtags}"; do
        [[ "${t:l}" == "$tflow" ]] && { match=1; break }
      done
      if (( match )); then
        filtered+=("${rows[$ri]}")
        filtered_flags+=("${row_flags[$ri]}")
        filtered_tags+=("${row_tags[$ri]}")
      fi
    done
    rows=( "${filtered[@]}" )
    row_flags=( "${filtered_flags[@]}" )
    row_tags=( "${filtered_tags[@]}" )
  fi

  if [[ -n "$needle" ]]; then
    nlow="${needle:l}"
    filtered=()
    filtered_flags=()
    filtered_tags=()
    for (( ri = 1; ri <= ${#rows[@]}; ri++ )); do
      line="${rows[$ri]}"
      name="${line%%|*}"
      ilow="${name:l}"
      if [[ "$ilow" == *${(b)nlow}* ]]; then
        filtered+=("$line")
        filtered_flags+=("${row_flags[$ri]}")
        filtered_tags+=("${row_tags[$ri]}")
      fi
    done
    rows=( "${filtered[@]}" )
    row_flags=( "${filtered_flags[@]}" )
    row_tags=( "${filtered_tags[@]}" )
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

  if [[ -n "$tag_filter" ]] && (( ${#rows[@]} == 0 )); then
    _popular_note "No commands tagged: $tag_filter"
    return 0
  fi

  shown=${#rows[@]}
  print
  if [[ -n "$needle" && -n "$tag_filter" ]]; then
    print -r -- "${fg[cyan]}Popular Commands${reset_color} ${fg[white]}${shown} matching · ${count} saved${reset_color} ${fg[yellow]}($needle)${reset_color} ${fg[magenta]}#$tag_filter${reset_color}"
  elif [[ -n "$needle" ]]; then
    print -r -- "${fg[cyan]}Popular Commands${reset_color} ${fg[white]}${shown} matching · ${count} saved${reset_color} ${fg[yellow]}($needle)${reset_color}"
  elif [[ -n "$tag_filter" ]]; then
    print -r -- "${fg[cyan]}Popular Commands${reset_color} ${fg[white]}${shown} matching · ${count} saved${reset_color} ${fg[magenta]}#$tag_filter${reset_color}"
  else
    print -r -- "${fg[cyan]}Popular Commands${reset_color} ${fg[white]}$count saved${reset_color}"
  fi
  print -r -- "${fg[blue]}╭${_POPULAR_RULE78}╮${reset_color}"

  local -i ri
  for (( ri = 1; ri <= ${#rows[@]}; ri++ )); do
    line="${rows[$ri]}"
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

    if [[ -n "${row_tags[$ri]:-}" ]]; then
      local tags_line="🏷 ${row_tags[$ri]}"
      if (( first )); then
        _popular_box_inner_line \
          " ${name_pad} │ ${tags_line}" \
          " ${fg[green]}${name_pad}${reset_color} ${fg[blue]}│${reset_color} ${fg[cyan]}${tags_line}${reset_color}"
        first=0
      else
        _popular_box_inner_line \
          " ${empty_pad} │ ${tags_line}" \
          " ${fg[white]}${empty_pad}${reset_color} ${fg[blue]}│${reset_color} ${fg[cyan]}${tags_line}${reset_color}"
      fi
    fi

    if [[ "${row_flags[$ri]:-}" == *confirm* ]]; then
      if (( first )); then
        _popular_box_inner_line \
          " ${name_pad} │ ⚠ confirm" \
          " ${fg[green]}${name_pad}${reset_color} ${fg[blue]}│${reset_color} ${fg[yellow]}⚠ confirm${reset_color}"
        first=0
      else
        _popular_box_inner_line \
          " ${empty_pad} │ ⚠ confirm" \
          " ${fg[white]}${empty_pad}${reset_color} ${fg[blue]}│${reset_color} ${fg[yellow]}⚠ confirm${reset_color}"
      fi
    fi

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
