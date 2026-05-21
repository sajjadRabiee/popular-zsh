# lib/popular/ui.zsh

typeset -g _POPULAR_BOX_INNER=0
typeset -g _POPULAR_RULE78=''

# Set _POPULAR_BOX_INNER and _POPULAR_RULE78 to match the current terminal width.
# Optional min_w: grow the box to at least this inner width (content-aware sizing).
_popular_set_box_width() {
  local -i min_w="${1:-0}"
  local -i cols
  cols=$(tput cols 2>/dev/null) || cols="${COLUMNS:-80}"
  local -i inner=$(( cols - 2 ))
  (( inner < 20 )) && inner=20
  (( inner > 120 )) && inner=120
  (( inner < min_w )) && inner=$min_w
  typeset -g _POPULAR_BOX_INNER=$inner
  typeset -g _POPULAR_RULE78=${(l:$inner::─:)}
}

_popular_set_box_width  # initialise at source time

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
  local text="$1"
  local -i width="$2"
  local -a in_lines words
  local line word cur
  local -i cur_len wlen

  if [[ -z "$text" ]]; then
    print ""
    return 0
  fi

  in_lines=("${(@f)text}")
  for line in "${in_lines[@]}"; do
    if [[ -z "$line" ]]; then
      print ""
      continue
    fi
    words=( ${(s: :)line} )
    cur=""
    cur_len=0
    for word in "${words[@]}"; do
      wlen=${#word}
      if (( cur_len == 0 )); then
        cur=$word
        cur_len=$wlen
      elif (( cur_len + 1 + wlen <= width )); then
        cur="$cur $word"
        (( cur_len += 1 + wlen ))
      else
        print -r -- "$cur"
        cur=$word
        cur_len=$wlen
      fi
    done
    [[ -n "$cur" ]] && print -r -- "$cur"
  done
}

_popular_usage_sep() {
  local -i sep_w=$(( _POPULAR_BOX_INNER - 2 ))
  (( sep_w < 1 )) && sep_w=1
  local dash="${_POPULAR_RULE78[1,$sep_w]}"
  local plain=" ${dash} "
  local colored=" ${fg[white]}${dash}${reset_color} "
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

  syn_pad=${(r:34:)syn}
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
  _popular_set_box_width
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
    inner_colored="  ${fg[cyan]}popular.zsh${reset_color} ${fg[white]}· bookmark and run shell commands${reset_color}"
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
  _popular_usage_row "p <name> [args…]" "Run: {{x}} → --x=…; [[x]] → positional; <<x>> → secret; {{x:def}} → default; {{x:int/path/enum=…}} → typed (validated before exec)"
  _popular_usage_row "pcp <name> [args…]" "Same expansion as \`p\`, but copies result to clipboard instead of running (pbcopy / wl-copy / xclip)"
  _popular_usage_row "pls [needle…]" "List saved commands (optional: filter names, substring, case-insensitive)"
  _popular_usage_row "premove <name>" "Delete a saved command"
  _popular_usage_row "pexport [file|-]" "Export commands only (\`-\` or empty → stdout); secrets file is never included"
  _popular_usage_row "pimport [-r|--replace] <file>" "Import; if <<secrets>> missing, asks global vs per-command (TTY); global values take priority when running \`p\`"
  _popular_usage_row "psecret [-g|--global] <key>" "Save global <<key>> (${POPULAR_SECRETS_FILE}; used first by \`p\`)"
  _popular_usage_row "psecret <name> <key>" "Save <<key>> only for <name> (used if no global value)"
  _popular_usage_row "pedit [name]" "Edit store in \${EDITOR:-vim}, or one command’s text"
  _popular_usage_row "pupdate" "Re-download popular.zsh + lib from GitHub (\$POPULAR_REPO_BASE)"
  _popular_usage_row "pcli" "Drop into a sub-shell with saved commands available directly by name (no \`p\` prefix); type \`bye\` to exit"
  _popular_usage_row "plock" "Lock secrets (clear cached master password for this session)"
  _popular_usage_row "psecret-migrate" "Encrypt an existing plain-text secrets file with AES-256 (run once after upgrading)"
  _popular_usage_row "psecret-reset" "Change master password: re-encrypts all secrets if old password known; wipes all secrets if lost"
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
  _popular_usage_example_line "padd serve 'python3 -m http.server {{port:int}}'"
  _popular_usage_example_line "padd rel 'kubectl rollout restart -n {{env:enum=dev|staging|prod}}'"
  _popular_usage_example_line 'p rel --env=staging   # enum: validated before exec, tab-completed'
  _popular_usage_example_line 'pls git               # list commands whose name contains "git"'
  _popular_usage_box_bot
  print
}

phelp() {
  _popular_usage
}

# ---------------------------------------------------------------------------
# _popular_msg_box — bordered message used by _popular_info / warn / note
# color: red | green | yellow | white | blue
# icon:  single terminal-column character
# msg:   text, may contain literal newlines for multi-line output
# ---------------------------------------------------------------------------

_popular_msg_box() {
  local color="$1" icon="$2" msg="$3"
  _popular_set_box_width
  local -i chunk_w=$(( _POPULAR_BOX_INNER - 6 ))
  (( chunk_w < 8 )) && chunk_w=8
  local -a raw_lines=("${(@f)msg}") wrapped=()
  local line chunk
  local -a chunks
  for line in "${raw_lines[@]}"; do
    [[ -z "$line" ]] && continue
    chunks=("${(@f)$(_popular_wrap_fill "$line" "$chunk_w")}")
    for chunk in "${chunks[@]}"; do
      [[ -n "${chunk//[[:space:]]/}" ]] && wrapped+=("$chunk")
    done
  done
  print -r -- "${fg[$color]}╭${_POPULAR_RULE78}╮${reset_color}"
  local first=1 plain colored
  local -i pad
  for line in "${wrapped[@]}"; do
    if (( first )); then
      plain="  ${icon}  ${line}"
      colored="  ${fg[$color]}${icon}${reset_color}  ${line}"
      first=0
    else
      plain="     ${line}"
      colored="     ${line}"
    fi
    pad=$(( _POPULAR_BOX_INNER - ${#plain} ))
    (( pad < 0 )) && pad=0
    print -rn -- "${fg[$color]}│${reset_color}${colored}"
    printf '%*s' $pad ''
    print -r -- "${fg[$color]}│${reset_color}"
  done
  print -r -- "${fg[$color]}╰${_POPULAR_RULE78}╯${reset_color}"
}

# ---------------------------------------------------------------------------
# Per-command --help box helpers (reuse existing box primitives)
# ---------------------------------------------------------------------------

_popular_help_open() {
  local cmd="$1" desc="$2"
  _popular_set_box_width
  print
  _popular_usage_box_top
  local plain="  ${cmd} · ${desc}"
  local colored="  ${fg[cyan]}${cmd}${reset_color} ${fg[white]}· ${desc}${reset_color}"
  _popular_box_inner_line "$plain" "$colored"
  _popular_usage_sep
}

_popular_help_examples() {
  _popular_usage_sep
  local ip="  Examples" ic="  ${fg[yellow]}Examples${reset_color}"
  _popular_box_inner_line "$ip" "$ic"
  _popular_usage_sep
}

_popular_help_close() {
  _popular_usage_box_bot
  print
}
