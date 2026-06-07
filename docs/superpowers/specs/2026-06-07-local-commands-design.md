# Local `.popular_commands` File Support

**Date:** 2026-06-07
**Status:** Approved

## Summary

`~/.popular_commands` stays global, but if a `.popular_commands` file exists in `$PWD` or any ancestor directory, it is checked first. This lets projects carry their own command sets that follow the repo.

---

## Approach

Walk up from `$PWD` at call time (no session variable, no `chpwd` hook). Each relevant function calls `_popular_find_local_file()` and falls back to the global file if nothing is found. This is always correct and matches the codebase's existing "do the work in the function" style.

---

## Section 1: Core lookup (`store.zsh`)

### `_popular_find_local_file()`

New function. Walks from `$PWD` to `/`, returns the path of the first `.popular_commands` found, or exits with status 1.

```zsh
_popular_find_local_file() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    [[ -f "$dir/.popular_commands" ]] && { print -r -- "$dir/.popular_commands"; return 0 }
    dir="${dir:h}"
  done
  return 1
}
```

### `_popular_get_command()`, `_popular_get_flags()`, `_popular_get_tags()`

Each gets a local-first check: call `_popular_find_local_file`, search the local file for the name, return immediately on hit. Fall through to `$POPULAR_COMMANDS_FILE` otherwise.

### `_popular_save_entry()`

Gains an optional 5th argument `file`. Defaults to `$POPULAR_COMMANDS_FILE`. `padd --local` passes `$PWD/.popular_commands`. The file is created with `chmod 600` if it does not exist.

### `_popular_names()`

Reads names from both the local file (if found) and the global file, deduped. Used only for tab completion — origin does not matter here.

---

## Section 2: `pls` display (`cmd-list.zsh`)

### New flags

| Flag | Behaviour |
|------|-----------|
| `-l` | Show only entries from the local file (error if no local file found) |
| `-g` | Show only entries from `$POPULAR_COMMANDS_FILE` |
| _(none)_ | Show both files; local entries shown first within their name group |

### Visual marking

- **Local entries** — name printed in magenta with `*` prefix: `* gs`
- **Global entries** — name printed in green as today: `gs`
- **Same name in both** — both rows shown (local first, global below), making the shadow explicit

### Header line

```
Popular Commands  12 saved  · local: /path/to/project/.popular_commands
```

With `-l`:
```
Popular Commands  local only  · /path/to/project/.popular_commands
```

With `-g`:
```
Popular Commands  global only
```

---

## Section 3: `padd` and `premove` (`cmd-add.zsh`, `cmd-io.zsh`)

### `padd --local`

New flag parsed in the same option loop as `--confirm` and `-t`. When set, writes to `$PWD/.popular_commands` (always — does not walk up). Confirmation message: `Saved 'gs' [local]`.

### `premove` scope

New `--local` and `--global` flags.

**Without flags:**
1. Walk up from `$PWD` to find a local file
2. If the name exists in that local file → remove from local only, print `Removed 'gs' (local)`
3. Otherwise → remove from `$POPULAR_COMMANDS_FILE`, print `Removed 'gs'`

**`--local`:** Only look in the local file; error if no local file is found or the name is not in it.

**`--global`:** Only look in `$POPULAR_COMMANDS_FILE`.

`_popular_secrets_remove_for_command` is called only when removing from global (secrets are always stored globally).

---

## Section 4: Completion (`completion.zsh`)

- **`padd`** — add `--local` to the option list at position 2 and in the fallthrough case
- **`premove`** — add `--local` and `--global` as options at position 2, fall through to name completion
- **Name completion for `p`, `pcp`, `pedit`, `premove`** — no change needed; `_popular_names()` already merges both files per Section 1
- **`_popular_all_tags()`** — update to read from the local file as well, so `pls -t <tab>` surfaces local tags

---

## Files Changed

| File | Change |
|------|--------|
| `lib/popular/store.zsh` | Add `_popular_find_local_file()`; update `_popular_get_command`, `_popular_get_flags`, `_popular_get_tags`, `_popular_names`, `_popular_save_entry` |
| `lib/popular/cmd-list.zsh` | Add `-l`/`-g` flags; read both files; mark local entries |
| `lib/popular/cmd-add.zsh` | Add `--local` flag to `padd` |
| `lib/popular/cmd-io.zsh` | Add `--local`/`--global` flags to `premove` |
| `lib/popular/completion.zsh` | Add `--local` to `padd` completion; add `--local`/`--global` to `premove` completion |
| `lib/popular/cmd-help.zsh` | Update `_popular_help_padd`, `_popular_help_premove`, `_popular_help_pls` |

---

## Out of Scope

- `paddh` — always writes to global; `--local` flag not added (history-save to local is a separate concern)
- `pedit` — no local/global distinction; user edits the file directly
- `pexport` / `pimport` — operate on the global file only
- `psecret` — secrets are always global
- `pcli` — inherits all changes via the updated public functions
