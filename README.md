# popular.zsh

[![GitHub Pages](https://img.shields.io/badge/docs-GitHub%20Pages-blue?style=flat-square)](https://sajjadrabiee.github.io/popular-zsh/)

![popular.zsh — bookmark, template, and run commands in zsh](docs/assets/popular.svg)

![demo](docs/assets/demo.gif)

Tiny `zsh` shortcuts for saving, running, and templating your most-used commands — with optional **secret placeholders** kept out of shared exports.

## Install

```zsh
curl -fsSL https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main/install.sh | zsh
```

Then reload: `source ~/.zshrc`

The installer detects your shell and writes the right integration automatically (zsh `source` line, bash/fish/nushell wrappers). See [Installation](docs/wiki/Installation.md) for manual setup, custom directory, and other shell details.

## Quick start

```zsh
padd gs git status          # save a command
p gs                        # run it

padd serve 'python3 -m http.server [[port]]'
p serve 8000                # positional template

padd ci 'curl -u "<<user>>:<<token>>" https://api.example.com'
psecret -g user             # store secret encrypted (AES-256-CBC, never exported)
p ci
```

Or bootstrap from 1 000+ ready-made commands:

```zsh
pimport -R sajjadRabiee/popular-zsh-pack
```

## Commands

| Command | What it does |
|---------|-------------|
| `padd <name> <cmd...>` | Save a command |
| `paddh <history#> [name]` | Save a line from shell history |
| `p <name> [args...]` | Run a saved command |
| `pcp <name> [args...]` | Expand a saved command and copy it to the clipboard |
| `pls [needle]` | List saved commands |
| `premove <name>` | Delete a command (and its per-command secrets) |
| `pexport [file\|-]` | Export commands to a file or stdout — never includes secrets |
| `pimport [-r] [-R] <file\|repo>` | Import / merge commands from a file or GitHub repo |
| `psecret [-g] <key>` | Store a secret (encrypted at rest) |
| `psecret-reset` | Re-key all secrets under a new master password, or wipe them |
| `plock` | Clear cached master password from the current session |
| `psecret-migrate` | Upgrade a v1 plain-text secrets file to v2 encrypted format |
| `pedit [name]` | Edit the whole store or one command in `$EDITOR` |
| `pcli` | Interactive sub-shell where saved names work without the `p` prefix |
| `pupdate` | Re-download all files from GitHub in place |
| `phelp` | Built-in command reference in the terminal |

→ [Full command reference](docs/wiki/Command-Reference.md)

## Storage

Saved commands live in `~/.popular_commands` — one `name|command` per line, plain text, easy to version or back up. Secrets are AES-256-CBC encrypted in a **separate** file; `pexport` never includes them.

Override either path:

```zsh
export POPULAR_COMMANDS_FILE=/path/to/commands
export POPULAR_SECRETS_FILE=/path/to/secrets
```

## Docs

- [Installation](docs/wiki/Installation.md) — one-line install, manual setup, custom paths, bootstrapping
- [Command Reference](docs/wiki/Command-Reference.md) — every command with flags and options
- [Templates](docs/wiki/Templates.md) — `{{name}}`, `[[name]]`, `<<secret>>` placeholder syntax
- [Examples](docs/wiki/Examples.md) — git, docker, secrets, history, packs
- [Command Packs](docs/wiki/Command-Packs.md) — publish and import community packs
- [Other Shells](docs/wiki/Other-Shells.md) — bash, fish, nushell wrappers and troubleshooting

## Security

`p` runs commands with `eval` after template expansion — treat your commands file and `pimport` sources like code you trust. Secrets use AES-256-CBC under a session-cached master password; run `plock` when stepping away. See [SECURITY.md](SECURITY.md) for the full threat model and vulnerability reporting.

## Why popular.zsh?

There are bigger tools for shell history, snippets, and command search. popular.zsh is for when you want something much smaller:

- a plain text file you can read, copy, and version
- fast repeatable commands with lightweight templates
- optional secrets beside the store — never leaked in exports
- community packs: `pimport -R owner/repo` bootstraps a team in seconds

That simplicity is the feature.

## Contributing

Bug reports, docs fixes, and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for local setup, the install/`pupdate` path-sync rule, and manual testing steps.
