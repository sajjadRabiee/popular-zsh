# lib/popular/cmd-list.zsh

pls() {
  [[ "${1:-}" == --help || "${1:-}" == -h ]] && { _popular_help_pls; return 0; }
  setopt local_options no_xtrace
  _popular_set_box_width

  # --- Parse flags (-l, -g, -t must come before the needle) ---
  local local_only=0 global_only=0 tag_filter=""
  while [[ $# -gt 0 && "${1:-}" == -* ]]; do
    case "$1" in
      -l) local_only=1; shift ;;
      -g) global_only=1; shift ;;
      -t)
        if [[ $# -lt 2 || -z "${2:-}" ]]; then
          _popular_warn "pls: -t requires a tag value"$'\n'"run 'pls --help' for details"
          return 1
        fi
        tag_filter="$2"; shift 2 ;;
      *) break ;;
    esac
  done

  if (( local_only && global_only )); then
    _popular_warn "pls: -l and -g are mutually exclusive"
    return 1
  fi

  # --- Locate files ---
  local local_file=""
  if (( ! global_only )); then
    local_file=$(_popular_find_local_file)
  fi
  if (( local_only )) && [[ -z "$local_file" ]]; then
    _popular_warn "pls: no local .popular_commands file found"
    return 1
  fi

  # --- Read entries from local and/or global ---
  local count max_name line name command raw_cmd raw_flags raw_tags rest needle
  local -i pw oi shown hi ri si
  local -a rows=() row_flags=() row_tags=() row_sources=() ochunks=()
  local -a filtered=() filtered_flags=() filtered_tags=() filtered_sources=()
  local -a hint_plain hint_color
  local src_prefix_plain="" src_prefix_color="" src_name_color=""
  local name_col_plain="" name_col_color="" empty_col_plain="" empty_col_color="" src=""
  max_name=12

  local -a _src_files=() _src_labels=()
  [[ -n "$local_file" ]] && { _src_files+=("$local_file"); _src_labels+=("local") }
  if (( ! local_only )); then
    _popular_ensure_file
    _src_files+=("$POPULAR_COMMANDS_FILE")
    _src_labels+=("global")
  fi

  for (( si = 1; si <= ${#_src_files[@]}; si++ )); do
    local _src_label="${_src_labels[$si]}"
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
      row_sources+=("$_src_label")
    done < "${_src_files[$si]}"
  done

  if (( ${#rows[@]} == 0 )); then
    _popular_note "No saved commands yet."
    return 0
  fi

  needle="$*"
  needle="${needle#"${needle%%[![:space:]]*}"}"
  needle="${needle%"${needle##*[![:space:]]}"}"

  count=${#rows[@]}

  # --- Tag filter ---
  if [[ -n "$tag_filter" ]]; then
    local tflow="${tag_filter:l}"
    local rtags t match
    filtered=(); filtered_flags=(); filtered_tags=(); filtered_sources=()
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
        filtered_sources+=("${row_sources[$ri]}")
      fi
    done
    rows=( "${filtered[@]}" )
    row_flags=( "${filtered_flags[@]}" )
    row_tags=( "${filtered_tags[@]}" )
    row_sources=( "${filtered_sources[@]}" )
  fi

  # --- Needle filter ---
  if [[ -n "$needle" ]]; then
    local nlow ilow
    nlow="${needle:l}"
    filtered=(); filtered_flags=(); filtered_tags=(); filtered_sources=()
    for (( ri = 1; ri <= ${#rows[@]}; ri++ )); do
      line="${rows[$ri]}"
      name="${line%%|*}"
      ilow="${name:l}"
      if [[ "$ilow" == *${(b)nlow}* ]]; then
        filtered+=("$line")
        filtered_flags+=("${row_flags[$ri]}")
        filtered_tags+=("${row_tags[$ri]}")
        filtered_sources+=("${row_sources[$ri]}")
      fi
    done
    rows=( "${filtered[@]}" )
    row_flags=( "${filtered_flags[@]}" )
    row_tags=( "${filtered_tags[@]}" )
    row_sources=( "${filtered_sources[@]}" )
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

  # --- Compute prefix column width for mixed-source display ---
  local -i has_local=0 prefix_w=0
  for (( ri = 1; ri <= ${#rows[@]}; ri++ )); do
    [[ "${row_sources[$ri]}" == "local" ]] && { has_local=1; break }
  done
  (( has_local )) && prefix_w=2

  # --- Header ---
  local local_note=""
  if (( local_only )); then
    local_note=" ${fg[white]}·${reset_color} ${fg[yellow]}local only${reset_color} ${fg[white]}·${reset_color} ${fg[magenta]}${local_file}${reset_color}"
  elif (( global_only )); then
    local_note=" ${fg[white]}·${reset_color} ${fg[yellow]}global only${reset_color}"
  elif [[ -n "$local_file" ]]; then
    local_note=" ${fg[white]}·${reset_color} ${fg[yellow]}local:${reset_color} ${fg[magenta]}${local_file}${reset_color}"
  fi

  print
  if [[ -n "$needle" && -n "$tag_filter" ]]; then
    print -r -- "${fg[cyan]}Popular Commands${reset_color} ${fg[white]}${shown} matching · ${count} saved${reset_color} ${fg[yellow]}($needle)${reset_color} ${fg[magenta]}#$tag_filter${reset_color}${local_note}"
  elif [[ -n "$needle" ]]; then
    print -r -- "${fg[cyan]}Popular Commands${reset_color} ${fg[white]}${shown} matching · ${count} saved${reset_color} ${fg[yellow]}($needle)${reset_color}${local_note}"
  elif [[ -n "$tag_filter" ]]; then
    print -r -- "${fg[cyan]}Popular Commands${reset_color} ${fg[white]}${shown} matching · ${count} saved${reset_color} ${fg[magenta]}#$tag_filter${reset_color}${local_note}"
  else
    print -r -- "${fg[cyan]}Popular Commands${reset_color} ${fg[white]}$count saved${reset_color}${local_note}"
  fi
  print -r -- "${fg[blue]}╭${_POPULAR_RULE78}╮${reset_color}"

  # --- Render rows ---
  local name_pad empty_pad gap first
  local empty_prefix_plain
  empty_prefix_plain=$(printf '%*s' $prefix_w '')

  for (( ri = 1; ri <= ${#rows[@]}; ri++ )); do
    line="${rows[$ri]}"
    name="${line%%|*}"
    command="${line#*|}"
    src="${row_sources[$ri]:-global}"

    if [[ "$src" == "local" ]]; then
      src_prefix_plain="* "
      src_prefix_color="${fg[magenta]}*${reset_color} "
      src_name_color="${fg[magenta]}"
    else
      src_prefix_plain="$empty_prefix_plain"
      src_prefix_color="$empty_prefix_plain"
      src_name_color="${fg[green]}"
    fi

    name_pad=$(printf "%-${max_name}s" "$name")
    empty_pad=$(printf "%-${max_name}s" "")
    name_col_plain="${src_prefix_plain}${name_pad}"
    name_col_color="${src_prefix_color}${src_name_color}${name_pad}${reset_color}"
    empty_col_plain="${empty_prefix_plain}${empty_pad}"
    empty_col_color="${empty_prefix_plain}${fg[white]}${empty_pad}${reset_color}"

    pw=$(( _POPULAR_BOX_INNER - 4 - max_name - prefix_w ))
    (( pw < 12 )) && pw=12

    _popular_build_placeholder_hint_rows "$command" "$pw" hint_plain hint_color

    first=1
    ochunks=("${(@f)$( _popular_wrap_fill "$command" "$pw" )}")
    for (( oi = 1; oi <= ${#ochunks}; oi++ )); do
      [[ -z "${ochunks[oi]//[[:space:]]/}" ]] && continue
      if (( first )); then
        _popular_box_inner_line \
          " ${name_col_plain} │ ${ochunks[oi]}" \
          " ${name_col_color} ${fg[blue]}│${reset_color} ${ochunks[oi]}"
        first=0
      else
        _popular_box_inner_line \
          " ${empty_col_plain} │ ${ochunks[oi]}" \
          " ${empty_col_color} ${fg[blue]}│${reset_color} ${ochunks[oi]}"
      fi
    done

    for (( hi = 1; hi <= ${#hint_plain}; hi++ )); do
      if (( first )); then
        _popular_box_inner_line \
          " ${name_col_plain} │ ${hint_plain[hi]}" \
          " ${name_col_color} ${fg[blue]}│${reset_color} ${hint_color[hi]}"
      else
        _popular_box_inner_line \
          " ${empty_col_plain} │ ${hint_plain[hi]}" \
          " ${empty_col_color} ${fg[blue]}│${reset_color} ${hint_color[hi]}"
      fi
      first=0
    done

    if [[ -n "${row_tags[$ri]:-}" ]]; then
      local tags_line="🏷 ${row_tags[$ri]}"
      if (( first )); then
        _popular_box_inner_line \
          " ${name_col_plain} │ ${tags_line}" \
          " ${name_col_color} ${fg[blue]}│${reset_color} ${fg[cyan]}${tags_line}${reset_color}"
        first=0
      else
        _popular_box_inner_line \
          " ${empty_col_plain} │ ${tags_line}" \
          " ${empty_col_color} ${fg[blue]}│${reset_color} ${fg[cyan]}${tags_line}${reset_color}"
      fi
    fi

    if [[ "${row_flags[$ri]:-}" == *confirm* ]]; then
      if (( first )); then
        _popular_box_inner_line \
          " ${name_col_plain} │ ⚠ confirm" \
          " ${name_col_color} ${fg[blue]}│${reset_color} ${fg[yellow]}⚠ confirm${reset_color}"
        first=0
      else
        _popular_box_inner_line \
          " ${empty_col_plain} │ ⚠ confirm" \
          " ${empty_col_color} ${fg[blue]}│${reset_color} ${fg[yellow]}⚠ confirm${reset_color}"
      fi
    fi

    if (( first )); then
      _popular_box_inner_line \
        " ${name_col_plain} │ " \
        " ${name_col_color} ${fg[blue]}│${reset_color} "
    fi

    gap=$(printf '%*s' "$_POPULAR_BOX_INNER" '')
    _popular_box_inner_line "$gap" "$gap"
  done

  print -r -- "${fg[blue]}╰${_POPULAR_RULE78}╯${reset_color}"
  print
}
