# Templates

Templates let you turn a saved command into a small reusable command generator.

## Placeholder syntax

Names use letters, digits, `_`, and `-`.

- **`{{name}}`** — supply values with **`--name=value`** or **`--name value`** when you run `p`.
- **`[[name]]`** — supply values as **positional** arguments after the bookmark name, in order of each **distinct** `[[name]]` by **first appearance** in the template. Repeating `[[name]]` still uses a single value.
- **`{{name:default}}`** and **`[[name:default]]`** — defaults live **inside the saved command text** (no extra file). Omitting that argument uses `default`; empty default is allowed (`{{msg:}}`). Override anytime with `--name=…` or a positional. The default portion cannot contain `}` or `]` (use templates without inline defaults if you need those characters in the value).
- **`<<name>>`** — **secrets**. Values are **not** stored in the command file. Set them with `psecret` or `psecret -g`. When you run `p`, **global** secrets are resolved **first**, then per-command secrets. `pexport` leaves `<<name>>` in place so shared backups stay free of secrets.

## Typed parameters

Append a type keyword after `:` instead of a default to validate the value before the command runs. The same syntax works for both `{{curly}}` and `[[bracket]]` slots.

| Syntax | Type | Validation |
|--------|------|------------|
| `{{name:int}}` / `[[name:int]]` | Integer | Rejects any value that is not a whole number (negative integers are allowed) |
| `{{name:path}}` / `[[name:path]]` | Path | Rejects the value if it does not exist on disk (`-e` check — files and directories both pass) |
| `{{name:enum=a\|b\|c}}` / `[[name:enum=a\|b\|c]]` | Enum | Rejects any value not in the `\|`-separated list; tab completion offers each choice |

Type keywords (`int`, `path`, `enum=…`) are recognised by the parser. Any other suffix after `:` is treated as a default value, so existing `{{name:default}}` templates are unaffected.

## Confirmation prompt

Mark a command as dangerous at save time with `--confirm`. When you run it with `p`, you are asked to confirm before the command executes. Anything other than `y` or `Y` aborts without running.

```zsh
padd --confirm drop-db "psql -c 'DROP DATABASE prod'"
p drop-db
# → psql -c 'DROP DATABASE prod'
# ⚠ Are you sure? [y/N] y   ← runs
# ⚠ Are you sure? [y/N] n   ← Aborted.
```

`paddh` supports `--confirm` the same way: `paddh --confirm -1 wipe`.

`pls` shows a `⚠ confirm` badge next to any guarded command. The flag is preserved when you edit the command text with `pedit` — only a fresh `padd` (without `--confirm`) removes it. `pcp` never prompts — copying to the clipboard is non-destructive.

## Examples

Bracket (positional) server:

```zsh
padd serve 'python3 -m http.server [[port]]'
p serve 8000
```

Curly (long-option) server:

```zsh
padd serve2 'python3 -m http.server {{port}}'
p serve2 --port=8000
```

Secret placeholder (share the bookmark text without sharing the token):

```zsh
padd hook 'curl -sf -H "Authorization: Bearer <<token>>" https://api.example.com/ping'
print -r 'secret-token-here' | psecret -g token
p hook
```

Integer — rejects non-numeric input:

```zsh
padd serve 'python3 -m http.server {{port:int}}'
p serve --port=8000        # ok
p serve --port=abc         # error: '--port' expects an integer, got 'abc'
```

Path — rejects missing files or directories:

```zsh
padd deploy 'kubectl apply -f {{manifest:path}}'
p deploy --manifest=./k8s/app.yaml    # ok if file exists
p deploy --manifest=./missing.yaml   # error: '--manifest' path does not exist: ./missing.yaml
```

Enum — tab-completes choices, rejects anything outside the list:

```zsh
padd release 'kubectl rollout restart deploy/app -n {{env:enum=dev|staging|prod}}'
p release --env=staging    # ok
p release --env=qa         # error: '--env' must be one of: dev, staging, prod — got 'qa'
```

## Quotes and special characters

Pass the command to `padd` inside **single quotes** when you need double quotes or operators inside the saved text, for example `padd msg 'git commit -m "wip"'`. The script escapes `\`, `|`, tab, and newlines in the stored command so pipes and multiline snippets survive the `name|command` format. For hand-edited files, write `\|` for a literal pipe character in the command.

## Multi-variable example

```zsh
padd open-model 'my-tool generate --entity_class={{class}} --env={{env}}'
p open-model --class='my.app.models.User' --env=dev
```

## Completion

After `p <name>`, completion offers **`--name=`** or a full **`--name=default`** when the template uses **`{{name:default}}`**. Plain **`{{name}}`** still completes to **`--name=`**. `[[name]]` slots are filled from positional arguments, so they do not get `--` suggestions.

For **enum** slots, completion expands into one entry per allowed value — so `{{env:enum=dev|staging|prod}}` produces `--env=dev`, `--env=staging`, and `--env=prod` as separate completions.

Other completion hooks include saved names for `p` / `premove` / `pls` (filter words), file paths for `pexport` and `pimport`, `psecret` targets and keys, and related helpers. Run `phelp` for the full command list.

Inside `pcli`, all completion works the same way. Saved names also complete as first-word commands (no `p` prefix), so `gs<TAB>` suggests your `gs` bookmark alongside regular executables.
