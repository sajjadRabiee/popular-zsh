# Installation

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

The command file is plain text (`name|command` per line). You can copy it, version it, or round-trip it with `pexport` and `pimport`. **`pexport` does not include the secrets file**—share exports that use `<<placeholders>>` safely after filling secrets only on machines that need them.
