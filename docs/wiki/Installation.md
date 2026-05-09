# Installation

## One-line install

```zsh
curl -fsSL https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main/install.sh | zsh
```

This downloads `popular.zsh` into:

```zsh
~/.popular-zsh/popular.zsh
```

And adds this to your `~/.zshrc` if needed:

```zsh
source ~/.popular-zsh/popular.zsh
```

## Manual install

Clone the repo or download `popular.zsh`, then add:

```zsh
source /absolute/path/to/popular.zsh
```

Reload your shell:

```zsh
source ~/.zshrc
```

## Custom install location

You can override the default install directory:

```zsh
POPULAR_INSTALL_DIR="$HOME/.config/popular-zsh" \
curl -fsSL https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main/install.sh | zsh
```

## Custom command file

By default, saved commands live in:

```zsh
~/.popular_commands
```

You can change that with:

```zsh
export POPULAR_COMMANDS_FILE=/path/to/your/file
```

That file is plain text (`name|command` per line). You can copy it, version it, or round-trip it with `pexport` and `pimport` from `popular.zsh`.
