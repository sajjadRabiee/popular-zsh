# lib/popular/store.zsh

_popular_ensure_file() {
  if [[ ! -f "$POPULAR_COMMANDS_FILE" ]]; then
    : > "$POPULAR_COMMANDS_FILE"
    chmod 600 "$POPULAR_COMMANDS_FILE" 2>/dev/null
  fi
}

_popular_find_local_file() {
  local dir="$PWD"
  local global="${POPULAR_COMMANDS_FILE:A}"
  while [[ "$dir" != "/" ]]; do
    local candidate="$dir/.popular_commands"
    if [[ -f "$candidate" && "${candidate:A}" != "$global" ]]; then
      print -r -- "$candidate"
      return 0
    fi
    dir="${dir:h}"
  done
  return 1
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
  local tags="${4:-}"
  local file="${5:-$POPULAR_COMMANDS_FILE}"

  cmd=$(_popular_command_encode "$cmd")

  if [[ ! -f "$file" ]]; then
    : > "$file"
    chmod 600 "$file" 2>/dev/null
  fi
  awk -F'|' -v name="$name" '$1 != name' "$file" > "${file}.tmp"
  mv "${file}.tmp" "$file"
  if [[ -n "$tags" ]]; then
    print -r -- "$name|$cmd|$flags|t:$tags" >> "$file"
  else
    print -r -- "$name|$cmd|$flags" >> "$file"
  fi
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
  local local_file
  local_file=$(_popular_find_local_file)
  _popular_ensure_file
  {
    [[ -n "$local_file" ]] && awk -F'|' 'NF { print $1 }' "$local_file"
    awk -F'|' 'NF { print $1 }' "$POPULAR_COMMANDS_FILE"
  } | awk '!seen[$0]++'
}

_popular_get_command() {
  local name="$1"
  local cmd local_file

  local_file=$(_popular_find_local_file)
  if [[ -n "$local_file" ]]; then
    cmd=$(awk -F'|' -v name="$name" '
      $1 == name {
        if ($NF ~ /^t:/) {
          cmd = $2
          for (i = 3; i <= NF-2; i++) cmd = cmd "|" $i
        } else {
          cmd = $2
          for (i = 3; i <= NF-1; i++) cmd = cmd "|" $i
        }
      }
      END { print cmd }
    ' "$local_file")
    if [[ -n "$cmd" ]]; then
      cmd=$(_popular_command_decode "$cmd")
      print -r -- "$cmd"
      return 0
    fi
  fi

  _popular_ensure_file
  cmd=$(awk -F'|' -v name="$name" '
    $1 == name {
      if ($NF ~ /^t:/) {
        cmd = $2
        for (i = 3; i <= NF-2; i++) cmd = cmd "|" $i
      } else {
        cmd = $2
        for (i = 3; i <= NF-1; i++) cmd = cmd "|" $i
      }
    }
    END { print cmd }
  ' "$POPULAR_COMMANDS_FILE")
  [[ -n "$cmd" ]] || return 1
  cmd=$(_popular_command_decode "$cmd")
  print -r -- "$cmd"
}

_popular_get_flags() {
  local name="$1"
  local flags local_file found

  local_file=$(_popular_find_local_file)
  if [[ -n "$local_file" ]]; then
    found=$(awk -F'|' -v name="$name" '$1==name{f=1} END{print f+0}' "$local_file")
    if (( found )); then
      flags=$(awk -F'|' -v name="$name" '
        $1 == name { flags = ($NF ~ /^t:/) ? $(NF-1) : $NF }
        END { print flags }
      ' "$local_file")
      print -r -- "$flags"
      return 0
    fi
  fi

  _popular_ensure_file
  flags=$(awk -F'|' -v name="$name" '
    $1 == name { flags = ($NF ~ /^t:/) ? $(NF-1) : $NF }
    END { print flags }
  ' "$POPULAR_COMMANDS_FILE")
  print -r -- "$flags"
}

_popular_get_tags() {
  local name="$1"
  local tags local_file found

  local_file=$(_popular_find_local_file)
  if [[ -n "$local_file" ]]; then
    found=$(awk -F'|' -v name="$name" '$1==name{f=1} END{print f+0}' "$local_file")
    if (( found )); then
      tags=$(awk -F'|' -v name="$name" '
        $1 == name { if ($NF ~ /^t:/) tags = substr($NF, 3) }
        END { print tags }
      ' "$local_file")
      print -r -- "$tags"
      return 0
    fi
  fi

  _popular_ensure_file
  tags=$(awk -F'|' -v name="$name" '
    $1 == name { if ($NF ~ /^t:/) tags = substr($NF, 3) }
    END { print tags }
  ' "$POPULAR_COMMANDS_FILE")
  print -r -- "$tags"
}
