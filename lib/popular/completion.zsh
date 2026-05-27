# lib/popular/completion.zsh

_popular_all_tags() {
  _popular_ensure_file
  awk -F'|' '
    $NF ~ /^t:/ {
      tags = substr($NF, 3)
      n = split(tags, a, ",")
      for (i = 1; i <= n; i++) if (a[i] != "") print a[i]
    }
  ' "$POPULAR_COMMANDS_FILE" | sort -u
}

_popular_complete_saved_names() {
  local label="${1:-saved command}"
  local -a entries
  entries=("${(@f)$(_popular_names)}")
  _describe "$label" entries
}

_popular_complete_pls() {
  (( CURRENT >= 2 )) || return 1
  if [[ "${words[CURRENT-1]}" == -t ]]; then
    local -a tags
    tags=("${(@f)$(_popular_all_tags)}")
    (( ${#tags[@]} )) && _describe 'tag' tags
    return
  fi
  if [[ "$CURRENT" == 2 ]]; then
    compadd -- -t
    _popular_complete_saved_names 'pls filter'
    return
  fi
  _popular_complete_saved_names 'pls filter'
}

_popular_complete_padd() {
  case "$CURRENT" in
    2)
      compadd -- --confirm -t --tags --help
      ;;
    *)
      if [[ "${words[CURRENT-1]}" == -t || "${words[CURRENT-1]}" == --tags ]]; then
        local -a tags
        tags=("${(@f)$(_popular_all_tags)}")
        (( ${#tags[@]} )) && _describe 'tag' tags
        return
      fi
      compadd -- --confirm -t --tags
      ;;
  esac
}

_popular_complete_template_options() {
  local name="$1"
  local command kind pname rest def typ
  local -a options=()
  local word used
  local -A seen_c

  command=$(_popular_get_command "$name") || return 1

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    kind="${line%%$'\t'*}"
    [[ "$kind" != curly ]] && continue
    rest="${line#*$'\t'}"
    if [[ "$rest" != *$'\t'* ]]; then
      pname="$rest"; def=""; typ=""
    elif [[ "${rest#*$'\t'}" == $'\t'* ]]; then
      pname="${rest%%$'\t'*}"; def=""; typ="${rest#*$'\t\t'}"
    else
      pname="${rest%%$'\t'*}"; def="${rest#*$'\t'}"; typ=""
    fi
    [[ -n "${seen_c[$pname]}" ]] && continue
    seen_c[$pname]=1
    used=0
    local -i _wi
    for (( _wi = 3; _wi <= ${#words[@]}; _wi++ )); do
      (( _wi == CURRENT )) && continue
      if [[ "${words[$_wi]}" == --${pname} || "${words[$_wi]}" == --${pname}=* ]]; then
        used=1
        break
      fi
    done
    (( used )) && continue
    if [[ "$typ" == enum=* ]]; then
      local -a _ev=("${(s:|:)${typ#enum=}}")
      local _v
      for _v in "${_ev[@]}"; do
        options+=("--${pname}=${_v}")
      done
    elif [[ -n "$def" ]]; then
      options+=("--${pname}=${def}")
    else
      options+=("--${pname}=")
    fi
  done < <(_popular_emit_template_slots "$command")

  (( ${#options[@]} > 0 )) || return 1
  _describe 'template option' options
}

_popular_complete_bracket_pos() {
  local name="$1"
  local command kind pname rest typ
  local -a bracket_names=() bracket_types=()
  local -A seen_b

  command=$(_popular_get_command "$name") || return 1

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    kind="${line%%$'\t'*}"
    [[ "$kind" != bracket ]] && continue
    rest="${line#*$'\t'}"
    if [[ "$rest" != *$'\t'* ]]; then
      pname="$rest"; typ=""
    elif [[ "${rest#*$'\t'}" == $'\t'* ]]; then
      pname="${rest%%$'\t'*}"; typ="${rest#*$'\t\t'}"
    else
      pname="${rest%%$'\t'*}"; typ=""
    fi
    [[ -n "${seen_b[$pname]}" ]] && continue
    seen_b[$pname]=1
    bracket_names+=("$pname")
    bracket_types+=("$typ")
  done < <(_popular_emit_template_slots "$command")

  (( ${#bracket_names[@]} == 0 )) && return 1

  local -i pos_count=0 _wi
  for (( _wi = 3; _wi < CURRENT; _wi++ )); do
    [[ "${words[$_wi]}" == --* ]] && continue
    (( pos_count++ ))
  done

  local -i slot=$(( pos_count + 1 ))
  (( slot > ${#bracket_names[@]} )) && return 1

  local slot_type="${bracket_types[$slot]}"
  [[ "$slot_type" == enum=* ]] || return 1

  local -a _ev=("${(s:|:)${slot_type#enum=}}")
  _describe 'value' _ev
}

_popular_complete_p() {
  if (( CURRENT == 2 )); then
    _popular_complete_saved_names
    return
  fi

  if (( CURRENT >= 3 )); then
    _popular_complete_bracket_pos "${words[2]}"
    _popular_complete_template_options "${words[2]}"
    return
  fi
}

_popular_complete_psecret() {
  local command
  local -a keys

  if (( CURRENT == 2 )); then
    compadd -- -g --global
    _popular_complete_saved_names 'command name'
    return
  fi

  if (( CURRENT == 3 )); then
    if [[ "${words[2]}" == -g || "${words[2]}" == --global ]]; then
      keys=("${(@f)$(_popular_collect_all_secret_keys)}")
      (( ${#keys[@]} )) || return 1
      _describe 'secret key' keys
      return
    fi
    command=$(_popular_get_command "${words[2]}") || return 1
    keys=("${(@f)$(_popular_collect_secret_keys_for_command "$command")}")
    (( ${#keys[@]} )) || return 1
    _describe 'secret key' keys
    return
  fi

  return 1
}

if [[ -o interactive ]]; then
  if ! whence compdef >/dev/null 2>&1; then
    autoload -Uz compinit
    compinit -i >/dev/null 2>&1
  fi

  if whence compdef >/dev/null 2>&1; then
    compdef _popular_complete_p p pcp
    compdef _popular_complete_saved_names premove
    compdef _popular_complete_pls pls
    compdef _popular_complete_padd padd

    _popular_complete_pedit() {
      (( CURRENT == 2 )) || return 1
      _popular_complete_saved_names
    }
    compdef _popular_complete_pedit pedit
    compdef _popular_complete_psecret psecret
    compdef _files pexport pimport
    compdef _nothing paddh pupdate psecret-reset
  fi
fi
