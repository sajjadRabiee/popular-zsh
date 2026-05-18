# popular.zsh

Tiny `zsh` shortcuts for saving, running, and templating your most-used commands — with optional **secret placeholders** kept out of shared exports.

## Quick start

```zsh
curl -fsSL https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main/install.sh | zsh
source ~/.zshrc

padd gs git status    # save a command
p gs                  # run it
pls                   # browse all saved commands
```

## Wiki pages

| Page | What's inside |
|------|--------------|
| [Installation](Installation.md) | One-line install, manual setup, custom paths, bootstrapping from a pack |
| [Command Reference](Command-Reference.md) | Every command with flags, options, and examples |
| [Templates](Templates.md) | `{{name}}`, `[[name]]`, `<<secret>>` placeholder syntax and defaults |
| [Examples](Examples.md) | Real-world patterns: git, docker, secrets, history, packs |
| [Command Packs](Command-Packs.md) | Publish and import community packs with `pimport -R` |
| [Other Shells](Other-Shells.md) | Bash, fish, nushell wrappers and troubleshooting |

## Project links

- [README](../../README.md) — project overview and quick reference
- [SECURITY.md](../../SECURITY.md) — threat model and vulnerability reporting
- [CONTRIBUTING.md](../../CONTRIBUTING.md) — local setup and contribution guide
