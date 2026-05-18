# Command Packs

A **popular-pack** is a Git repository that exposes a `commands.pop` file — the same `name|command` format that `pexport` produces. Anyone can import a pack in one line:

```zsh
pimport -R owner/repo
```

No download, no copy-paste. `pimport` fetches the raw file with `curl`, then runs the normal merge logic against your store.

---

## The popular-pack standard

### Repository structure

```
your-pack-repo/
├── commands.pop    ← required
└── README.md       ← recommended
```

The only hard requirement is `commands.pop` at the **root** of the default branch.

### File format

One command per line:

```
name|command
```

| Part | Rules |
|------|-------|
| `name` | Letters, digits, `-`, `_`. No spaces. No `\|`. Must be unique within the file. |
| `command` | Full shell command. Literal pipe `\|` must be escaped. Backslash → `\\`, tab → `\t`, newline → `\n`. |

Lines with no `\|` separator are skipped with a warning. Empty lines are silently ignored.

**Template placeholders** work exactly like in any saved command:

| Syntax | Meaning |
|--------|---------|
| `[[name]]` | Positional argument: `p cmd value` |
| `{{name}}` | Named flag: `p cmd --name=value` |
| `<<name>>` | Secret placeholder: filled from `POPULAR_SECRETS_FILE` |

### Example `commands.pop`

```
gs|git status
gl|git log --oneline -20
top10cpu|ps aux --sort=-%cpu \| head -10
dps-f|docker ps --filter "name=[[name]]"
psql-conn|psql -h [[host]] -U [[user]] -d [[db]]
deploy|kubectl rollout restart deploy/[[name]]
notify|curl -sf -u "<<user>>:<<pass>>" https://hooks.example.com/run
```

---

## Import shorthands

`pimport -R` accepts four forms:

| Input | Resolves to |
|-------|-------------|
| `owner/repo` | `https://raw.githubusercontent.com/owner/repo/main/commands.pop` |
| `owner/repo:branch` | `https://raw.githubusercontent.com/owner/repo/branch/commands.pop` |
| `owner/repo/path/to/file.pop` | `https://raw.githubusercontent.com/owner/repo/main/path/to/file.pop` |
| `https://example.com/cmds.pop` | used as-is (any raw URL) |

All four can be combined with `-r` (replace mode):

```zsh
pimport -r -R owner/repo          # wipe store, replace with pack
pimport -R owner/repo:dev          # import from a non-default branch
pimport -R owner/repo/extras.pop   # import a file that is not commands.pop
pimport -R https://gist.github.com/user/abc123/raw/cmds.pop
```

Requires `curl` on your `PATH`.

---

## Creating your own pack

### From scratch

1. Create a GitHub repo (public or private).
2. Add `commands.pop` — one `name|command` per line.
3. Share the import one-liner:

```zsh
pimport -R your-username/your-pack
```

### From your existing store

Export your current commands and commit them:

```zsh
pexport > commands.pop
# review, trim secrets/personal data
git add commands.pop && git commit -m "add commands.pop"
git push
```

### Team workflow

Put `commands.pop` in a private monorepo or a dedicated repo. New teammates bootstrap with one command:

```zsh
pimport -R your-org/your-team-pack
```

Existing teammates stay up to date by re-running the same command — `pimport` merges by name (most-recent wins), so updates overwrite stale entries without touching anything else.

---

## Official pack

[`sajjadRabiee/popular-zsh-pack`](https://github.com/sajjadRabiee/popular-zsh-pack) ships 1 000+ everyday commands across 20 categories (git, docker, kubernetes, aws, terraform, python, node, postgres, redis, security, and more):

```zsh
pimport -R sajjadRabiee/popular-zsh-pack
```

---

## Security note

A popular-pack is code — commands are run with `eval` after template expansion. Only import packs from sources you trust. For the same reason, treat your own `commands.pop` like a script: review it before committing, and keep secrets in `psecret` rather than hard-coding them in the command text.
