# popular.zsh: A tiny command launcher for zsh

`popular.zsh` is a small shell helper for people who keep retyping the same commands and want something lighter than a full snippet manager.

It started from a simple idea:

"I want a short command in `zsh` where I can save my popular commands and run them fast."

That became a tiny workflow:

- `padd` to save commands
- `paddh` to grab a line from history by event number
- `p` to run them
- `pls` to browse them
- `premove` to delete them
- `pexport` / `pimport` to move or merge saved commands as plain text
- `pedit` to edit them directly
- `phelp` for a readable command reference in the terminal

Then it grew a little in the right direction:

- clean terminal output
- command-name completion
- template variables like `{{class}}` or `{{port}}`
- option completion like `--class=` and `--port=`

The goal is not to replace your shell history or a large productivity toolkit.
The goal is to make your own repeated commands feel first-class.

## Why this exists

Many command-line tools help you search history, store snippets, or manage notes. Those are useful, but sometimes you want something much smaller:

- a plain text file
- one sourceable script
- predictable behavior
- no heavy setup

`popular.zsh` tries to stay in that sweet spot.

## A quick example

Save a command:

```zsh
padd gs git status
```

Run it:

```zsh
p gs
```

Save a template:

```zsh
padd serve 'python3 -m http.server {{port}}'
```

Run it with an option:

```zsh
p serve --port=8000
```

## Install

```zsh
curl -fsSL https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main/install.sh | zsh
```

## What makes it nice

- You can keep using a normal `~/.popular_commands` file.
- Commands stay transparent and editable.
- Templates are simple enough to remember.
- Autocomplete helps without getting in your way.

If you want a tiny personal command launcher for `zsh`, this is the whole point of the project.
