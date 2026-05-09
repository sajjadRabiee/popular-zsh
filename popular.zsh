# popular.zsh
# A tiny zsh helper for saving and reusing your favorite commands.

: "${POPULAR_COMMANDS_FILE:=$HOME/.popular_commands}"

autoload -Uz colors
colors

_popular_usage() {
  print -r -- "${fg[cyan]}Popular Commands${reset_color}"
  print
  print "  padd <name> <command...>   Save a command"
  print "  p <name> [options...]      Run a saved command"
  print "  pls                        Show saved commands"
  print "  premove <name>             Delete a saved command"
  print "  pedit                      Open the command file in \$EDITOR"
  print "  phelp                      Show this message"
  print
  print -r -- "${fg[white]}Examples${reset_color}"
  print "  padd gs git status"
  print "  padd pcatmap './bin/digikala-pricing/cli.sh ... --entity_class={{class}}'"
  print "  p gs"
  print "  p pcatmap --class='Digikala\\\\Supernova\\\\Foo\\\\BarEntity'"
}

_popular_ensure_file() {
  [[ -f "$POPULAR_COMMANDS_FILE" ]] || : > "$POPULAR_COMMANDS_FILE"
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
  local line

  _popular_ensure_file
  line=$(awk -F'|' -v name="$name" '$1 == name { line = $0 } END { print line }' "$POPULAR_COMMANDS_FILE")
  [[ -n "$line" ]] || return 1
  print -r -- "${line#*|}"
}

_popular_placeholders() {
  local command="$1"
  printf '%s\n' "$command" | grep -o '{{[A-Za-z0-9_-]\{1,\}}}' | sed 's/^{{//; s/}}$//' | awk '!seen[$0]++'
}

_popular_placeholder_summary() {
  local command="$1"
  local placeholder
  local -a items=()

  while IFS= read -r placeholder; do
    [[ -n "$placeholder" ]] || continue
    items+=("--$placeholder")
  done < <(_popular_placeholders "$command")

  if (( ${#items[@]} > 0 )); then
    print -r -- "${(j:, :)items}"
  fi
}

_popular_render_command() {
  local template="$1"
  shift

  local -A vars=()
  local -a passthrough=()
  local -a missing=()
  local arg key value escaped
  local rendered="$template"
  local placeholder

  while [[ $# -gt 0 ]]; do
    arg="$1"
    shift

    if [[ "$arg" == --*=* ]]; then
      key="${arg%%=*}"
      key="${key#--}"
      value="${arg#*=}"
      vars[$key]="$value"
      continue
    fi

    if [[ "$arg" == --* && $# -gt 0 ]]; then
      key="${arg#--}"
      value="$1"
      shift
      vars[$key]="$value"
      continue
    fi

    passthrough+=("$arg")
  done

  while IFS= read -r placeholder; do
    [[ -n "$placeholder" ]] || continue

    if (( ! ${+vars[$placeholder]} )); then
      missing+=("$placeholder")
      continue
    fi

    escaped=$(printf '%q' "${vars[$placeholder]}")
    rendered="${rendered//\{\{$placeholder\}\}/$escaped}"
    unset "vars[$placeholder]"
  done < <(_popular_placeholders "$template")

  if (( ${#missing[@]} > 0 )); then
    _popular_warn "p: missing required option(s): ${(j: :)${missing/#/--}}"
    return 1
  fi

  if (( ${#passthrough[@]} > 0 )); then
    for arg in "${passthrough[@]}"; do
      rendered+=" $(printf '%q' "$arg")"
    done
  fi

  print -r -- "$rendered"
}

padd() {
  local name="$1"
  shift || true

  if [[ -z "$name" || $# -eq 0 ]]; then
    _popular_warn "padd: usage: padd <name> <command...>"
    return 1
  fi

  _popular_ensure_file
  awk -F'|' -v name="$name" '$1 != name' "$POPULAR_COMMANDS_FILE" > "${POPULAR_COMMANDS_FILE}.tmp"
  mv "${POPULAR_COMMANDS_FILE}.tmp" "$POPULAR_COMMANDS_FILE"
  print -r -- "$name|$*" >> "$POPULAR_COMMANDS_FILE"
  _popular_info "Saved '$name'"
}

p() {
  local name="$1"
  local command rendered

  shift || true

  if [[ -z "$name" ]]; then
    _popular_warn "p: usage: p <name>"
    return 1
  fi

  command=$(_popular_get_command "$name") || {
    _popular_warn "p: '$name' not found"
    return 1
  }

  rendered=$(_popular_render_command "$command" "$@") || return 1

  print -r -- "${fg[cyan]}→${reset_color} $rendered"
  eval "$rendered"
}

pls() {
  local count max_name line name command options preview name_pad empty_pad
  local -a rows=()

  _popular_ensure_file
  if [[ ! -s "$POPULAR_COMMANDS_FILE" ]]; then
    _popular_note "No saved commands yet."
    return 0
  fi

  count=$(_popular_names | wc -l | tr -d ' ')
  max_name=12

  while IFS='|' read -r name command; do
    [[ -n "$name" ]] || continue
    (( ${#name} > max_name )) && max_name=${#name}
    rows+=("$name|$command")
  done < "$POPULAR_COMMANDS_FILE"

  print
  print -r -- "${fg[cyan]}Popular Commands${reset_color} ${fg[white]}$count saved${reset_color}"
  print -r -- "${fg[blue]}╭──────────────────────────────────────────────────────────────────────────────╮${reset_color}"

  for line in "${rows[@]}"; do
    name="${line%%|*}"
    command="${line#*|}"
    options=$(_popular_placeholder_summary "$command")
    preview=$(printf '%s\n' "$command" | sed 's/{{[A-Za-z0-9_-]\{1,\}}}/<value>/g')
    name_pad=$(printf "%-${max_name}s" "$name")
    empty_pad=$(printf "%-${max_name}s" "")

    printf "%b\n" "${fg[blue]}│${reset_color} ${fg[green]}${name_pad}${reset_color} ${fg[blue]}│${reset_color} ${preview}"
    if [[ -n "$options" ]]; then
      printf "%b\n" "${fg[blue]}│${reset_color} ${fg[white]}${empty_pad}${reset_color} ${fg[blue]}│${reset_color} ${fg[white]}options:${reset_color} ${fg[yellow]}$options${reset_color}"
    fi
    print -r -- "${fg[blue]}│${reset_color}"
  done

  print -r -- "${fg[blue]}╰──────────────────────────────────────────────────────────────────────────────╯${reset_color}"
  print
}

premove() {
  local name="$1"

  if [[ -z "$name" ]]; then
    _popular_warn "premove: usage: premove <name>"
    return 1
  fi

  _popular_ensure_file
  awk -F'|' -v name="$name" '$1 != name' "$POPULAR_COMMANDS_FILE" > "${POPULAR_COMMANDS_FILE}.tmp"
  mv "${POPULAR_COMMANDS_FILE}.tmp" "$POPULAR_COMMANDS_FILE"
  _popular_info "Removed '$name'"
}

pedit() {
  _popular_ensure_file
  "${EDITOR:-nano}" "$POPULAR_COMMANDS_FILE"
}

phelp() {
  _popular_usage
}

_popular_complete_saved_names() {
  local -a entries
  entries=("${(@f)$(_popular_names)}")
  _describe 'saved command' entries
}

_popular_complete_template_options() {
  local name="$1"
  local command placeholder
  local -a placeholders=()
  local -a options=()
  local word used

  command=$(_popular_get_command "$name") || return 1

  while IFS= read -r placeholder; do
    [[ -n "$placeholder" ]] || continue
    placeholders+=("$placeholder")
  done < <(_popular_placeholders "$command")

  (( ${#placeholders[@]} > 0 )) || return 1

  for placeholder in "${placeholders[@]}"; do
    used=0
    for word in "${words[@]:2}"; do
      if [[ "$word" == --${placeholder} || "$word" == --${placeholder}=* ]]; then
        used=1
        break
      fi
    done

    (( used )) && continue
    options+=("--${placeholder}=")
  done

  (( ${#options[@]} > 0 )) || return 1
  _describe 'template option' options
}

_popular_complete_p() {
  if (( CURRENT == 2 )); then
    _popular_complete_saved_names
    return
  fi

  if (( CURRENT >= 3 )); then
    _popular_complete_template_options "${words[2]}"
    return
  fi
}

if [[ -o interactive ]]; then
  if ! whence compdef >/dev/null 2>&1; then
    autoload -Uz compinit
    compinit -i >/dev/null 2>&1
  fi

  if whence compdef >/dev/null 2>&1; then
    compdef _popular_complete_p p
    compdef _popular_complete_saved_names premove
  fi
fi
