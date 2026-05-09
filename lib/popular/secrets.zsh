# lib/popular/secrets.zsh

# Reserved first column in POPULAR_SECRETS_FILE. Lookup always prefers global, then per-command (fallback).
_POPULAR_SECRETS_GLOBAL='__global__'

_popular_ensure_secrets_file() {
  [[ -f "$POPULAR_SECRETS_FILE" ]] || : > "$POPULAR_SECRETS_FILE"
  chmod 600 "$POPULAR_SECRETS_FILE" 2>/dev/null
}

_popular_secrets_lookup_global_only() {
  local key="$1" enc

  _popular_ensure_secrets_file
  enc=$(awk -F'\t' -v g="$_POPULAR_SECRETS_GLOBAL" -v key="$key" '$1 == g && $2 == key { print $3; exit }' "$POPULAR_SECRETS_FILE")
  [[ -n "$enc" ]] || return 1
  REPLY=$(_popular_command_decode "$enc")
  return 0
}

_popular_secrets_lookup() {
  local name="$1" key="$2" enc

  _popular_ensure_secrets_file
  enc=$(awk -F'\t' -v g="$_POPULAR_SECRETS_GLOBAL" -v key="$key" '$1 == g && $2 == key { print $3; exit }' "$POPULAR_SECRETS_FILE")
  if [[ -z "$enc" ]]; then
    enc=$(awk -F'\t' -v name="$name" -v key="$key" '$1 == name && $2 == key { print $3; exit }' "$POPULAR_SECRETS_FILE")
  fi
  [[ -n "$enc" ]] || return 1
  REPLY=$(_popular_command_decode "$enc")
  return 0
}

_popular_secrets_set() {
  local name="$1" key="$2" val="$3" enc

  enc=$(_popular_command_encode "$val")

  _popular_ensure_secrets_file
  awk -F'\t' -v name="$name" -v key="$key" '$1 != name || $2 != key' "$POPULAR_SECRETS_FILE" > "${POPULAR_SECRETS_FILE}.tmp"
  mv "${POPULAR_SECRETS_FILE}.tmp" "$POPULAR_SECRETS_FILE"
  print -r -- "$name"$'\t'"$key"$'\t'"$enc" >> "$POPULAR_SECRETS_FILE"
  chmod 600 "$POPULAR_SECRETS_FILE" 2>/dev/null
}

_popular_secrets_remove_for_command() {
  local name="$1"

  [[ -f "$POPULAR_SECRETS_FILE" ]] || return 0
  awk -F'\t' -v name="$name" '$1 != name' "$POPULAR_SECRETS_FILE" > "${POPULAR_SECRETS_FILE}.tmp"
  mv "${POPULAR_SECRETS_FILE}.tmp" "$POPULAR_SECRETS_FILE"
}

_popular_substitute_secrets() {
  local entry="$1"
  local tail="$2" out="" rest inner idx full key

  while [[ -n "$tail" ]]; do
    if [[ "$tail" == '<<'* ]]; then
      rest="${tail#'<<'}"
      idx="${rest[(i)>>]}"
      if (( idx > ${#rest} )); then
        out+="${tail[1]}"
        tail="${tail[2,-1]}"
        continue
      fi
      inner="${rest[1,$((idx - 1))]}"
      full="<<${inner}>>"
      if [[ "$inner" != *[[:space:]]* ]] && [[ "$inner" =~ '^[A-Za-z0-9_-]+$' ]]; then
        key="$inner"
        if ! _popular_secrets_lookup "$entry" "$key"; then
          _popular_warn "p: missing secret <<${key}>> for '${entry}' (set with: psecret -g ${key} or psecret ${entry} ${key})"
          return 1
        fi
        out+="${(q)REPLY}"
        tail="${tail#"$full"}"
      else
        out+="${tail[1]}"
        tail="${tail[2,-1]}"
      fi
    else
      out+="${tail[1]}"
      tail="${tail[2,-1]}"
    fi
  done

  print -r -- "$out"
}

_popular_collect_secret_keys_for_command() {
  local cmd="$1"
  local line kind rest pname
  local -a keys=()
  local -A seen

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    kind="${line%%$'\t'*}"
    [[ "$kind" != secret ]] && continue
    rest="${line#*$'\t'}"
    pname="$rest"
    pname="${pname%%$'\t'*}"
    [[ -n "${seen[$pname]}" ]] && continue
    seen[$pname]=1
    keys+=("$pname")
  done < <(_popular_emit_template_slots "$cmd")

  print -rl -- "${keys[@]}"
}

_popular_import_prompt_missing_secrets() {
  local src="$1"
  local line name enc_cmd cmd sk val
  local -A pairs keys_union
  local pair mode ans

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" != *'|'* ]] && continue
    name="${line%%|*}"
    [[ -z "$name" ]] && continue
    enc_cmd="${line#*|}"
    cmd=$(_popular_command_decode "$enc_cmd")
    for sk in "${(@f)$(_popular_collect_secret_keys_for_command "$cmd")}"; do
      [[ -z "$sk" ]] && continue
      pairs["$name|$sk"]=1
      keys_union[$sk]=1
    done
  done < "$src"

  (( ${#pairs} )) || return 0

  local -i need_any=0
  for pair in ${(k)pairs}; do
    name="${pair%%|*}"
    sk="${pair#*|}"
    if ! _popular_secrets_lookup "$name" "$sk"; then
      need_any=1
      break
    fi
  done
  (( need_any )) || return 0

  mode=separate
  if [[ -t 0 ]] && [[ -t 1 ]]; then
    print -r ""
    _popular_note "pimport: Some <<secret>> placeholders are not in your secrets file yet."
    print -rn -- "${fg[yellow]}Save them as ${fg[cyan]}[g]lobal${reset_color}${fg[yellow]} (one value per key; ${fg[white]}global wins when both exist${fg[yellow]}) or ${fg[cyan]}[s]eparate${reset_color}${fg[yellow]} (per command)? ${fg[white]}[g/s] ${fg[yellow]}(default: g)${reset_color}: "
    read -r ans
    print -r ""
    case "${${ans:-g}:l}" in
      s | separate | per | p) mode=separate ;;
      *) mode=global ;;
    esac
  fi

  if [[ "$mode" == global ]]; then
    local -a keys_sorted keys_need_global
    local sk

    keys_sorted=("${(@ko)keys_union}")
    keys_need_global=()
    for sk in "${keys_sorted[@]}"; do
      [[ -z "$sk" ]] && continue
      _popular_secrets_lookup_global_only "$sk" && continue
      keys_need_global+=("$sk")
    done

    (( ${#keys_need_global} )) || {
      _popular_note "pimport: Global mode — all secret keys from this file already have global values."
      return 0
    }

    _popular_note "pimport: Global mode — keys from this file to save globally: ${(j:,:)keys_need_global}"

    for sk in "${keys_need_global[@]}"; do
      if [[ -t 0 ]] && [[ -t 1 ]]; then
        read -rs "?Global secret '${sk}' (<<${sk}>> for all commands): " val
        print -r ""
        if [[ -z "$val" ]]; then
          _popular_warn "pimport: skipped empty global secret '${sk}' (set later with: psecret -g ${sk})"
          continue
        fi
        _popular_secrets_set "$_POPULAR_SECRETS_GLOBAL" "$sk" "$val"
        _popular_note "Saved global secret '${sk}'"
      else
        _popular_warn "pimport: set global secret '${sk}' with: psecret -g ${sk}"
      fi
    done
    return 0
  fi

  for pair in ${(ko)pairs}; do
    name="${pair%%|*}"
    sk="${pair#*|}"
    if _popular_secrets_lookup "$name" "$sk"; then
      continue
    fi
    if [[ -t 0 ]] && [[ -t 1 ]]; then
      read -rs "?Secret '${sk}' for command '${name}': " val
      print -r ""
      if [[ -z "$val" ]]; then
        _popular_warn "pimport: skipped empty secret '${sk}' for '${name}' (set later with: psecret ${name} ${sk} or psecret -g ${sk})"
        continue
      fi
      _popular_secrets_set "$name" "$sk" "$val"
      _popular_note "Saved secret '${sk}' for '${name}'"
    else
      _popular_warn "pimport: missing secret '${sk}' for '${name}' — set with: psecret -g ${sk} or psecret ${name} ${sk}"
    fi
  done
}

_popular_collect_all_secret_keys() {
  local line name enc_cmd cmd sk
  local -A seen

  _popular_ensure_file
  [[ ! -s "$POPULAR_COMMANDS_FILE" ]] && return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" != *'|'* ]] && continue
    name="${line%%|*}"
    [[ -z "$name" ]] && continue
    [[ "$name" == "$_POPULAR_SECRETS_GLOBAL" ]] && continue
    enc_cmd="${line#*|}"
    cmd=$(_popular_command_decode "$enc_cmd")
    for sk in "${(@f)$(_popular_collect_secret_keys_for_command "$cmd")}"; do
      [[ -z "$sk" ]] && continue
      [[ -n "${seen[$sk]}" ]] && continue
      seen[$sk]=1
      print -r -- "$sk"
    done
  done < "$POPULAR_COMMANDS_FILE"
}

psecret() {
  local name="" sk="" val global=0

  while [[ "$1" == -* ]]; do
    case "$1" in
      -g | --global) global=1 ;;
      *)
        _popular_warn "psecret: unknown option: $1"
        _popular_warn "psecret: usage: psecret [-g|--global] <secret-key>"
        _popular_warn "psecret:        psecret <command-name> <secret-key>"
        return 1
        ;;
    esac
    shift
  done

  if (( global )); then
    sk="$1"
    name="$_POPULAR_SECRETS_GLOBAL"
  else
    name="$1"
    sk="$2"
  fi

  if [[ -z "$name" || -z "$sk" ]]; then
    _popular_warn "psecret: usage: psecret [-g|--global] <secret-key>   # global (preferred when running commands)"
    _popular_warn "psecret:        psecret <command-name> <secret-key>   # fallback when no global value"
    _popular_warn "psecret: reads the value from stdin if piped; otherwise prompts (hidden)"
    return 1
  fi

  if (( ! global )) && [[ "$name" == "$_POPULAR_SECRETS_GLOBAL" ]]; then
    _popular_warn "psecret: '${_POPULAR_SECRETS_GLOBAL}' is reserved — use: psecret -g <secret-key>"
    return 1
  fi

  if [[ "$sk" == "$_POPULAR_SECRETS_GLOBAL" ]]; then
    _popular_warn "psecret: that secret key name is reserved"
    return 1
  fi

  if [[ ! "$sk" =~ '^[A-Za-z0-9_-]+$' ]]; then
    _popular_warn "psecret: invalid secret key (use letters, digits, _ or -)"
    return 1
  fi

  if [[ ! -t 0 ]]; then
    val="$(cat)"
    val="${val//$'\r'/}"
    val="${val%"${val##*[![:space:]]}"}"
  else
    if (( global )); then
      read -rs "?Global secret '${sk}' (all commands): " val
    else
      read -rs "?Secret '${sk}' for command '${name}': " val
    fi
    print
  fi

  if [[ -z "$val" ]]; then
    _popular_warn "psecret: empty value; not saving"
    return 1
  fi

  _popular_secrets_set "$name" "$sk" "$val"
  if (( global )); then
    _popular_info "Saved global secret '${sk}' (${_POPULAR_SECRETS_FILE})"
  else
    _popular_info "Saved secret '${sk}' for '${name}'"
  fi
}
