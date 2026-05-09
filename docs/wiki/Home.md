# popular.zsh Wiki

Welcome to the wiki for `popular.zsh`.

`popular.zsh` is a tiny helper for `zsh` that lets you save, run, and template frequently used commands with a small set of memorable shortcuts.

## What it gives you

- `padd` to save commands
- `paddh` to save a command from history by event number
- `p` to run commands
- `pls` to browse saved commands
- `premove` to remove entries
- `pexport` and `pimport` to export or merge saved commands
- `pedit` / `pedit <name>` to edit the whole file or one command (default editor: vim)
- `phelp` for formatted help in the terminal
- tab completion for saved names (`p`, `premove`, `pedit`, `pls` filters)
- tab completion for template options like `--port=` or `--class=`

## Quick Start

Install it:

```zsh
curl -fsSL https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main/install.sh | zsh
```

Save something:

```zsh
padd gs git status
```

Run it:

```zsh
p gs
```

Use a template:

```zsh
padd serve 'python3 -m http.server {{port}}'
p serve --port=8000
```

## Wiki Pages

- [Installation](Installation.md)
- [Command Reference](Command-Reference.md)
- [Templates](Templates.md)
- [Examples](Examples.md)
- [Why popular.zsh?](Why-popular.zsh.md)
