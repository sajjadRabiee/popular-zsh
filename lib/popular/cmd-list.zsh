# lib/popular/cmd-list.zsh

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
