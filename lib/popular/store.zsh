# lib/popular/store.zsh

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
