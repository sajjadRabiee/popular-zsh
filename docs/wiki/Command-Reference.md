# Command Reference

## `padd`

Save a command:

```zsh
padd gs git status
```

## `paddh`

Save a command line from zsh history by event number (the number shown in the first column of `history`). Only works in an interactive shell.

```zsh
paddh 233           # default name h233
paddh 233 gs        # save event 233 as gs
paddh -1            # previous command relative to this line (default name h-1)
```

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

## `pls`

Show a polished list of saved commands with template option hints and secret hints. With arguments, only bookmarks whose **name** contains the needle (substring, case-insensitive) are shown; multiple words form one needle string.

```zsh
pls
pls git
```

## `premove`

Delete a saved command and remove any **per-command** secret rows for that name (global secrets are unchanged).

```zsh
premove gs
```

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
pimport ~/backup.popular.txt      # merge (same names are overwritten)
pimport -r ~/backup.popular.txt    # replace entire store
```

Invalid lines (no `|` separator, empty name) are skipped with a warning.

If the imported lines use **`<<secret>>`** placeholders and some values are still missing, **on a TTY** you are asked whether to save new secrets **globally** (`[g]`, default) or **separately per command** (`[s]`). Global mode lists the distinct keys from the file, then prompts once per key that does not yet have a **global** row. Non-interactive runs print hints to use `psecret` instead.

## `psecret`

Store a value for a `<<key>>` placeholder (stdin or hidden prompt). Values are **encrypted at rest** with AES-256-CBC (openssl, PBKDF2) under a master password you set the first time you use secrets in a session.

```zsh
print -r 'value' | psecret mycmd api-token   # only for bookmark mycmd
print -r 'value' | psecret -g api-token      # global (preferred when running p)
psecret -g username                          # prompt if stdin is a TTY
```

On first use in a session, you will be prompted for your master password. The password is cached in memory for the rest of that shell session and is never written to disk. Run `plock` to clear it.

Keys must match letters, digits, `_`, or `-`. The reserved bucket name `__global__` is internal; use `-g` / `--global` instead of typing it as a command name.

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

Edit the whole backing file (same `name|command` format as on disk), or edit **only one** bookmark’s command text in a scratch buffer:

```zsh
pedit              # opens ~/.popular_commands (or $POPULAR_COMMANDS_FILE)
pedit serve        # opens just the saved command for “serve”
```

Uses **`$EDITOR`**, or **vim** if `EDITOR` is unset. If the editor exits non-zero, changes are not saved. Saving an empty buffer is rejected (use `premove` to delete).

## `pupdate`

Re-download `popular.zsh`, `install.sh`, and every file under `lib/popular/` from GitHub into the same directory as your sourced `popular.zsh` (requires `curl` and the usual `lib/popular/` layout).

```zsh
pupdate
```

Uses **`POPULAR_REPO_BASE`** if set (default: `https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main`). Reload after updating:

```zsh
source ~/.popular-zsh/popular.zsh
```

## `pcli`

Drop into a sub-shell where your saved command names work **directly**—no `p` prefix needed. Your normal `PS1` is untouched; a `[p]` badge appears on the right so you always know you're inside the popular session. The following short aliases are active inside `pcli`:

| Alias    | Full command |
|----------|-------------|
| `add`    | `padd`      |
| `addh`   | `paddh`     |
| `list`   | `pls`       |
| `remove` | `premove`   |
| `edit`   | `pedit`     |
| `update` | `pupdate`   |
| `secret` | `psecret`   |
| `save`   | `pexport`   |
| `load`   | `pimport`   |
| `help`   | `phelp`     |
| `bye`    | `exit`      |

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
