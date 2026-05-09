# Templates

Templates let you turn a saved command into a small reusable command generator.

## Placeholder syntax

Names use letters, digits, `_`, and `-`.

- **`{{name}}`** — supply values with **`--name=value`** or **`--name value`** when you run `p`.
- **`[[name]]`** — supply values as **positional** arguments after the bookmark name, in order of each **distinct** `[[name]]` by **first appearance** in the template. Repeating `[[name]]` still uses a single value.

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

## Quotes and special characters

Pass the command to `padd` inside **single quotes** when you need double quotes or operators inside the saved text, for example `padd msg 'git commit -m "wip"'`. The script escapes `\`, `|`, and newlines in the stored command so pipes and multiline snippets survive the `name|command` format. For hand-edited files, write `\|` for a literal pipe character in the command.

## Multi-variable example

```zsh
padd open-model 'my-tool generate --entity_class={{class}} --env={{env}}'
p open-model --class='my.app.models.User' --env=dev
```

## Completion

After `p <name>`, completion offers **`--name=`** only for placeholders written as **`{{name}}`**. `[[name]]` slots are filled from positional arguments, so they do not get `--` suggestions.

Other completion hooks from `popular.zsh` include saved names for `p` / `premove`, file paths for `pexport` and `pimport`, and name suggestions where applicable. Run `phelp` for the full command list.
