# lib/popular/ui.zsh

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
  _popular_usage_row "p <name> [args…]" "Run: {{x}} → --x=…; [[x]] → positional; <<x>> → secret (see psecret); optional {{x:def}} / [[x:def]] defaults in the saved command"
  _popular_usage_row "pls [needle…]" "List saved commands (optional: filter names, substring, case-insensitive)"
  _popular_usage_row "premove <name>" "Delete a saved command"
  _popular_usage_row "pexport [file|-]" "Export commands only (\`-\` or empty → stdout); secrets file is never included"
  _popular_usage_row "pimport [-r|--replace] <file>" "Import; if <<secrets>> missing, asks global vs per-command (TTY); global values take priority when running \`p\`"
  _popular_usage_row "psecret [-g|--global] <key>" "Save global <<key>> (${POPULAR_SECRETS_FILE}; used first by \`p\`)"
  _popular_usage_row "psecret <name> <key>" "Save <<key>> only for <name> (used if no global value)"
  _popular_usage_row "pedit [name]" "Edit store in \${EDITOR:-vim}, or one command’s text"
  _popular_usage_row "pupdate" "Re-download popular.zsh + lib from GitHub (\$POPULAR_REPO_BASE)"
  _popular_usage_row "pcli" "Drop into a sub-shell with saved commands available directly by name (no \`p\` prefix); type \`bye\` to exit"
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

phelp() {
  _popular_usage
}
