# Command Reference

Every command accepts `--help` or `-h` for a formatted in-terminal reference.

---

## `padd`

Save a command:

```zsh
padd gs git status
padd serve 'python3 -m http.server [[port]]'
padd --local run 'npm test'   # writes to $PWD/.popular_commands
```

| Flag | Description |
|------|-------------|
| `--local` | Write to `$PWD/.popular_commands` instead of the global store |
| `--confirm` | Prompt `Are you sure? [y/N]` when the command is run with `p` |
| `-t / --tags <tag,…>` | Attach comma-separated tags; filter with `pls -t` |

## `paddh`

Save a command line from zsh history by event number (the number shown in the first column of `history`). Only works in an interactive shell.

```zsh
paddh 233                    # default name h233
paddh 233 gs                 # save event 233 as gs
paddh -1                     # previous command (default name h-1)
paddh --local -1 run-tests   # save to project-local file
```

| Flag | Description |
|------|-------------|
| `--local` | Write to `$PWD/.popular_commands` instead of the global store |
| `--confirm` | Prompt `Are you sure? [y/N]` when the command is run with `p` |

## `p`

Run a saved command:

```zsh
p gs
```

Run a templated command:

- **`[[name]]`** in the saved command → pass values as positionals, e.g. `p serve 8000`.
- **`{{name}}`** → pass `--name=value`, e.g. `p serve --port=8000`.
- **`<<name>>`** → filled from `POPULAR_SECRETS_FILE`: **global** values (`psecret -g`) are tried first, then per-command (`psecret <cmd> <key>`).

```zsh
p serve 8000
p other --port=8000
```

## `pcp`

Same expansion logic as `p` — resolves templates and secrets — but instead of executing the result, copies it to the clipboard and prints `Copied.`

```zsh
pcp gs
pcp serve 8000
pcp other --port=8000
```

Uses `pbcopy` on macOS, `wl-copy` on Wayland, or `xclip -sel clip` on X11.

Useful when you need to paste the fully-expanded command into a remote SSH session, a chat window, or any other context where you can't run it locally.

## `pls`

Show a polished list of saved commands with template option hints and secret hints. With arguments, only bookmarks whose **name** contains the needle (substring, case-insensitive) are shown; multiple words form one needle string.

When a project-local `.popular_commands` file is found (by walking up from `$PWD`), both files are shown together. Local entries appear with a `*` prefix in magenta.

```zsh
pls                # show all (local + global)
pls -l             # show only local entries
pls -g             # show only global entries
pls git            # filter by name substring
pls -t docker      # filter by tag
pls -l git         # local entries matching 'git'
```

| Flag | Description |
|------|-------------|
| `-l` | Show only entries from the local `.popular_commands` file (error if none found) |
| `-g` | Show only entries from the global store |
| `-t <tag>` | Show only commands that carry this tag (case-insensitive, exact match) |

## `premove`

Delete a saved command. Without flags, removes from the local file if the name is found there; otherwise falls back to the global store. Per-command secrets are removed only when deleting from the global store (secrets are always global).

```zsh
premove gs            # local-first: removes local entry if found, else global
premove --local gs    # only remove from the local file
premove --global gs   # only remove from the global store
```

| Flag | Description |
|------|-------------|
| `--local` | Remove only from the project-local file; error if none found or name absent |
| `--global` | Remove only from the global store |

## `pexport`

Write your saved commands to a file, or print them to stdout. Format is one `name|command` per line (same as the backing file). **Never includes** `POPULAR_SECRETS_FILE`.

```zsh
pexport -
pexport ~/backup.popular.txt
```

With no argument, or with `-`, output goes to stdout.

## `pimport`

Merge commands from a file, or replace the whole store.

```zsh
pimport ~/backup.popular.txt       # merge (same names are overwritten)
pimport -r ~/backup.popular.txt    # replace entire store
```

Invalid lines (no `|` separator, empty name) are skipped with a warning.

If the imported lines use **`<<secret>>`** placeholders and some values are still missing, **on a TTY** you are asked whether to save new secrets **globally** (`[g]`, default) or **separately per command** (`[s]`). Global mode lists the distinct keys from the file, then prompts once per key that does not yet have a **global** row. Non-interactive runs print hints to use `psecret` instead.

### Remote import (`--remote` / `-R`)

Fetch a **popular-pack** directly from GitHub (or any raw URL) without downloading manually. Requires `curl`.

```zsh
pimport -R owner/repo                        # fetches owner/repo/main/commands.pop
pimport -R owner/repo:branch                 # specific branch
pimport -R owner/repo/path/to/file.pop       # custom file path
pimport -R https://example.com/cmds.pop      # full URL
pimport -r -R owner/repo                     # replace store with remote pack
```

**popular-pack standard:** a repository with a `commands.pop` file at its root in the standard `name|command` format (the same output as `pexport`). Any git-hosting service works as long as you provide a raw file URL.

## `psecret`

Store a value for a `<<key>>` placeholder (stdin or hidden prompt). Values are **encrypted at rest** with AES-256-CBC (openssl, PBKDF2) under a master password you set the first time you use secrets in a session.

```zsh
print -r 'value' | psecret mycmd api-token   # per-command secret
print -r 'value' | psecret -g api-token      # global (checked first when running p)
psecret -g username                          # prompt if stdin is a TTY
```

On first use in a session, you will be prompted for your master password. The password is cached in memory for the rest of that shell session and is never written to disk. Run `plock` to clear it.

Keys must match letters, digits, `_`, or `-`. The reserved bucket name `__global__` is internal; use `-g` / `--global` instead of typing it as a command name.

## `psecret-reset`

Change the master password for all stored secrets, or wipe the entire secrets file.

```zsh
psecret-reset          # re-encrypt every secret under a new master password
psecret-reset --wipe   # delete the secrets file entirely (irreversible)
```

You will be prompted for the current master password before any changes are made. A `.bak` copy is kept when re-keying until you remove it. Use `plock` after resetting to clear the old cached password.

## `plock`

Clear the cached master password from the current shell session. The next command that reads or writes a secret will prompt for the password again.

```zsh
plock
```

Use this when stepping away from a shared terminal or before handing off your session.

## `psecret-migrate`

Migrate a v1 secrets file (plain-text values) to the v2 AES-256-CBC encrypted format. Run this once after upgrading from an older version of popular.zsh.

```zsh
psecret-migrate
```

You will be prompted for your master password. Each value is re-encrypted and the old file is saved as `<secrets-file>.bak`. Remove the backup once you have verified the migration.

## `pedit`

Edit the whole backing file (same `name|command` format as on disk), or edit **only one** bookmark's command text in a scratch buffer. When editing a named entry, the change is saved back to whichever file (local or global) the entry was found in.

```zsh
pedit              # opens the global store in $EDITOR
pedit --local      # opens the project-local .popular_commands in $EDITOR
pedit serve        # edits just the saved command for "serve" (saves to its source file)
```

| Flag | Description |
|------|-------------|
| `--local` | (no-arg form only) Open the local `.popular_commands` file; error if none found |

Uses **`$EDITOR`**, or **vim** if `EDITOR` is unset. If the editor exits non-zero, changes are not saved. Saving an empty buffer is rejected (use `premove` to delete).

## `pupdate`

Re-download `popular.zsh`, `install.sh`, and every file under `lib/popular/` from GitHub into the same directory as your sourced `popular.zsh` (requires `curl` and the usual `lib/popular/` layout). All updated functions are reloaded automatically — no manual `source` needed.

```zsh
pupdate
pupdate --dir ~/.config/popular-zsh   # override install directory
```

| Flag | Description |
|------|-------------|
| `-d`, `--dir <path>` | Use this directory instead of the auto-detected install path |

If no `--dir` is given and `POPULAR_INSTALL_DIR` is not set, `pupdate` prompts interactively for the path (press Enter to accept the detected default).

Uses **`POPULAR_REPO_BASE`** if set (default: `https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main`).

## `pcli`

Drop into a sub-shell where your saved command names work **directly** — no `p` prefix needed. Your normal `PS1` is untouched; a `[p]` badge appears on the right so you always know you're inside the popular session. The following short aliases are active inside `pcli`:

| Alias | Full command |
|-------|-------------|
| `add` | `padd` |
| `addh` | `paddh` |
| `list` | `pls` |
| `remove` | `premove` |
| `edit` | `pedit` |
| `update` | `pupdate` |
| `secret` | `psecret` |
| `secret-reset` | `psecret-reset` |
| `save` | `pexport` |
| `load` | `pimport` |
| `help` | `phelp` |
| `bye` | `exit` |

Tab completion is fully available inside the sub-shell.

```zsh
pcli
# now inside popular shell:
gs          # runs your saved "gs" command directly
list        # same as pls
bye         # exits back to your normal shell
```

## `phelp`

Show the built-in help (boxed layout, command table, and examples):

```zsh
phelp
```
