# lib/popular/store.zsh

_popular_ensure_file() {
  if [[ ! -f "$POPULAR_COMMANDS_FILE" ]]; then
    : > "$POPULAR_COMMANDS_FILE"
    chmod 600 "$POPULAR_COMMANDS_FILE" 2>/dev/null
  fi
}

_popular_command_encode() {
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//|/\\|}
  s=${s//$'\t'/\\t}
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
        't') out+=$'\t' ;;
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
  local flags="${3:-}"

  cmd=$(_popular_command_encode "$cmd")

  _popular_ensure_file
  awk -F'|' -v name="$name" '$1 != name' "$POPULAR_COMMANDS_FILE" > "${POPULAR_COMMANDS_FILE}.tmp"
  mv "${POPULAR_COMMANDS_FILE}.tmp" "$POPULAR_COMMANDS_FILE"
  print -r -- "$name|$cmd|$flags" >> "$POPULAR_COMMANDS_FILE"
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

_popular_info() { _popular_msg_box green  '✓' "$1" }
_popular_warn() { _popular_msg_box red    '✗' "$1" >&2 }
_popular_note() { _popular_msg_box yellow '·' "$1" }

_popular_names() {
  _popular_ensure_file
  awk -F'|' 'NF { print $1 }' "$POPULAR_COMMANDS_FILE"
}

_popular_get_command() {
  local name="$1"
  local cmd

  _popular_ensure_file
  cmd=$(awk -F'|' -v name="$name" '$1 == name { cmd = $2 } END { print cmd }' "$POPULAR_COMMANDS_FILE")
  [[ -n "$cmd" ]] || return 1
  cmd=$(_popular_command_decode "$cmd")
  print -r -- "$cmd"
}

_popular_get_flags() {
  local name="$1"
  local flags

  _popular_ensure_file
  flags=$(awk -F'|' -v name="$name" '$1 == name { flags = $3 } END { print flags }' "$POPULAR_COMMANDS_FILE")
  print -r -- "$flags"
}
