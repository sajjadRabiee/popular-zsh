# lib/popular/completion.zsh

_popular_complete_saved_names() {
  local label="${1:-saved command}"
  local -a entries
  entries=("${(@f)$(_popular_names)}")
  _describe "$label" entries
}

_popular_complete_pls() {
  (( CURRENT >= 2 )) || return 1
  _popular_complete_saved_names 'pls filter'
}

_popular_complete_template_options() {
  local name="$1"
  local command kind pname rest def
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
      pname="$rest"
      [[ -n "${seen_c[$pname]}" ]] && continue
      seen_c[$pname]=1
      used=0
      for word in "${words[@]:2}"; do
        if [[ "$word" == --${pname} || "$word" == --${pname}=* ]]; then
          used=1
          break
        fi
      done
      (( used )) && continue
      options+=("--${pname}=")
    else
      pname="${rest%%$'\t'*}"
      def="${rest#*$'\t'}"
      [[ -n "${seen_c[$pname]}" ]] && continue
      seen_c[$pname]=1
      used=0
      for word in "${words[@]:2}"; do
        if [[ "$word" == --${pname} || "$word" == --${pname}=* ]]; then
          used=1
          break
        fi
      done
      (( used )) && continue
      options+=("--${pname}=${def}")
    fi
  done < <(_popular_emit_template_slots "$command")

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
    compdef _popular_complete_p p
    compdef _popular_complete_saved_names premove
    compdef _popular_complete_pls pls

    _popular_complete_pedit() {
      (( CURRENT == 2 )) || return 1
      _popular_complete_saved_names
    }
    compdef _popular_complete_pedit pedit
    compdef _popular_complete_psecret psecret
    compdef _files pexport pimport
    compdef _nothing paddh
  fi
fi
