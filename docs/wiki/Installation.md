# Installation

## Requirements

- **zsh** (macOS ships it; Linux: `apt install zsh` or `brew install zsh`)
- **openssl** — required for secret encryption (AES-256-CBC). Available by default on macOS; on Linux: `apt install openssl` or `brew install openssl`.
- `curl` — for the one-line install and `pupdate`

## One-line install

```zsh
curl -fsSL https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main/install.sh | zsh
```

This downloads the bootstrap script and all modules into:

```text
~/.popular-zsh/popular.zsh
~/.popular-zsh/lib/popular/ui.zsh
~/.popular-zsh/lib/popular/store.zsh
~/.popular-zsh/lib/popular/template.zsh
~/.popular-zsh/lib/popular/secrets.zsh
~/.popular-zsh/lib/popular/cmd-add.zsh
~/.popular-zsh/lib/popular/cmd-run.zsh
~/.popular-zsh/lib/popular/cmd-list.zsh
~/.popular-zsh/lib/popular/cmd-io.zsh
~/.popular-zsh/lib/popular/cmd-edit.zsh
~/.popular-zsh/lib/popular/cmd-cli.zsh
~/.popular-zsh/lib/popular/completion.zsh
```

And injects the right integration for your shell: a `source` line into `~/.zshrc` for **zsh**, wrapper functions into `~/.bashrc` for **bash**, into `~/.config/fish/config.fish` for **fish**, or `def` wrappers into `~/.config/nushell/config.nu` for **nushell**.

Override the GitHub raw root (branch layout) with:

```zsh
POPULAR_REPO_BASE="https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main" \
curl -fsSL "$POPULAR_REPO_BASE/install.sh" | zsh
```

(`install.sh` uses `POPULAR_REPO_BASE` internally with that default.)

## Manual install

Clone the repo so `popular.zsh` and `lib/popular/` stay together, then add:

```zsh
source /absolute/path/to/repo/popular.zsh
```

Reload your shell:

```zsh
source ~/.zshrc
```

## Custom install directory

You can override the default install directory:

```zsh
POPULAR_INSTALL_DIR="$HOME/.config/popular-zsh" \
curl -fsSL https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main/install.sh | zsh
```

## Command and secrets files

By default, saved commands live in:

```zsh
~/.popular_commands
```

Secrets default to:

```zsh
${POPULAR_COMMANDS_FILE}.secrets
```

You can change either:

```zsh
export POPULAR_COMMANDS_FILE=/path/to/your/file
export POPULAR_SECRETS_FILE=/path/to/your/secrets
```

The command file is plain text (`name|command` per line). You can copy it, version it, or round-trip it with `pexport` and `pimport`. **`pexport` does not include the secrets file** — share exports that use `<<placeholders>>` safely after filling secrets only on machines that need them.

Secret values are **encrypted at rest** with AES-256-CBC (openssl, PBKDF2). A master password is prompted on first use in each shell session and cached in memory. If you have an existing v1 plain-text secrets file, run `psecret-migrate` once to re-encrypt it.

## Project-local command files

If a `.popular_commands` file exists in `$PWD` or any ancestor directory, `p` checks it first — it takes priority over the global store for commands with the same name. Use `padd --local` to create one in the current directory.

```zsh
cd ~/projects/myapp
padd --local build 'npm run build'
git add .popular_commands   # commit alongside your code
```

`pls` shows both files together; local entries are marked with `*` in magenta. Use `pls -l` or `pls -g` to filter to one scope. `premove` defaults to local-first removal; `--local` / `--global` flags let you be explicit.

## Bootstrapping commands after install

After installing, you can populate your store immediately from a [command pack](Command-Packs.md):

```zsh
pimport -R sajjadRabiee/popular-zsh-pack   # 1000+ everyday commands
```

Or restore from your own backup:

```zsh
pimport ~/popular-backup.txt
```

`curl` must be on your `PATH` for remote import.
