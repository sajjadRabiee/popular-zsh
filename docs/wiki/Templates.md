# Templates

Templates let you turn a saved command into a small reusable command generator.

## Placeholder syntax

Names use letters, digits, `_`, and `-`.

- **`{{name}}`** — supply values with **`--name=value`** or **`--name value`** when you run `p`.
- **`[[name]]`** — supply values as **positional** arguments after the bookmark name, in order of each **distinct** `[[name]]` by **first appearance** in the template. Repeating `[[name]]` still uses a single value.
- **`{{name:default}}`** and **`[[name:default]]`** — defaults live **inside the saved command text** (no extra file). Omitting that argument uses `default`; empty default is allowed (`{{msg:}}`). Override anytime with `--name=…` or a positional. The default portion cannot contain `}` or `]` (use templates without inline defaults if you need those characters in the value).
- **`<<name>>`** — **secrets**. Values are **not** stored in the command file. Set them with `psecret` or `psecret -g`. When you run `p`, **global** secrets are resolved **first**, then per-command secrets. `pexport` leaves `<<name>>` in place so shared backups stay free of secrets.

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

## Quotes and special characters

Pass the command to `padd` inside **single quotes** when you need double quotes or operators inside the saved text, for example `padd msg 'git commit -m "wip"'`. The script escapes `\`, `|`, tab, and newlines in the stored command so pipes and multiline snippets survive the `name|command` format. For hand-edited files, write `\|` for a literal pipe character in the command.

## Multi-variable example

```zsh
padd open-model 'my-tool generate --entity_class={{class}} --env={{env}}'
p open-model --class='my.app.models.User' --env=dev
```

## Completion

After `p <name>`, completion offers **`--name=`** or a full **`--name=default`** when the template uses **`{{name:default}}`**. Plain **`{{name}}`** still completes to **`--name=`**. `[[name]]` slots are filled from positional arguments, so they do not get `--` suggestions.

Other completion hooks include saved names for `p` / `premove` / `pls` (filter words), file paths for `pexport` and `pimport`, `psecret` targets and keys, and related helpers. Run `phelp` for the full command list.
