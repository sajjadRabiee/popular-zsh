# Contributing to popular.zsh

Thanks for helping improve this project. This guide covers how to set up a local copy, what to watch when changing code, and how we prefer contributions to arrive.

## Prerequisites

- **zsh** as your shell (the project is zsh-only).
- Familiarity with running an interactive zsh for manual checks (`padd`, `p`, `pimport`, and so on).

## Getting started

1. Clone the repository (or work from your fork).
2. Source the **repository directory** from your shell so both `popular.zsh` and `lib/popular/` resolve correctly:

   ```zsh
   source /absolute/path/to/clone/popular.zsh
   ```

3. Reload or open a new terminal tab after edits to pick up changes.

Avoid relying on the curl installer while developing; use a direct `source` of your clone so you exercise your branch.

## Project layout

- [`popular.zsh`](popular.zsh) — entrypoint; sets defaults for `POPULAR_COMMANDS_FILE` / `POPULAR_SECRETS_FILE` and sources modules under `lib/popular/`.
- [`lib/popular/*.zsh`](lib/popular/) — UI, store encoding, templates, secrets, commands, completion.
- [`install.sh`](install.sh) — downloads tracked files from GitHub raw URLs into `POPULAR_INSTALL_DIR`.

### Keeping install and update in sync

If you add, remove, or rename a sourced module:

- Update `POPULAR_MODULE_PATHS` in [`install.sh`](install.sh).
- Update `_popular_upstream_paths` in [`lib/popular/cmd-update.zsh`](lib/popular/cmd-update.zsh).

Both lists must refer to the same set of paths, or installs and `pupdate` will drift.

## Style and conventions

- Match existing naming (`_popular_*` for internals, short user-facing command names).
- Prefer small, focused changes; avoid unrelated refactors in the same pull request.
- Shell options: respect patterns already used in nearby files (`set -euo pipefail` where the script already uses it).
- User-visible messages go through `_popular_info`, `_popular_warn`, or `_popular_note` where applicable.

## Testing (manual)

There is no automated test harness yet. Before submitting a change, please smoke-test paths your edit touches, for example:

- Save and run: `padd`, `p`, `paddh` (interactive shell only).
- List / edit / remove: `pls`, `pedit`, `premove`.
- Import / export: `pexport`, `pimport`, `pimport -r` with a small fixture file.
- Secrets: `psecret`, `psecret -g`, then `p` on a command that uses `<<key>>`.
- Completion: trigger tab completion for `p`, `pls`, `psecret`, etc., if you touch [`lib/popular/completion.zsh`](lib/popular/completion.zsh).
- Sub-shell: run `pcli`, execute a saved command by name, use the short aliases (`list`, `add`, `bye`), and verify tab completion works inside the session.

Use a **scratch** `POPULAR_COMMANDS_FILE` (and matching secrets path) while testing so you do not overwrite your real shortcuts:

```zsh
export POPULAR_COMMANDS_FILE=/tmp/popular_test_commands
export POPULAR_SECRETS_FILE=/tmp/popular_test_commands.secrets
source /path/to/clone/popular.zsh
```

## Documentation

- If you add or change user-facing behavior, update [`README.md`](README.md) and, when appropriate, [`docs/wiki/`](docs/wiki/).
- If the change affects trust boundaries or safety expectations, update [`SECURITY.md`](SECURITY.md).

## Pull requests

1. Open a PR with a clear description of **what** changed and **why**.
2. Mention any manual tests you ran.
3. Keep commits readable; squash or split if it helps reviewers.

## Reporting security issues

Please do **not** open a public issue for undisclosed security problems. See [`SECURITY.md`](SECURITY.md) for how to report them responsibly.

## Code of conduct

Be respectful and constructive in issues and pull requests. Assume good intent and focus feedback on the work.
