# Templates

Templates let you turn a saved command into a small reusable command generator.

## Placeholder syntax

Use placeholders inside saved commands:

```zsh
{{port}}
{{class}}
{{env}}
```

Each placeholder becomes a required runtime option.

## Example

Save a template:

```zsh
padd serve 'python3 -m http.server {{port}}'
```

Run it:

```zsh
p serve --port=8000
```

## Multi-variable example

```zsh
padd open-model 'my-tool generate --entity_class={{class}} --env={{env}}'
p open-model --class='my.app.models.User' --env=dev
```

## Completion

Template options show up in completion after the command name:

```zsh
p serve <TAB>
```

That suggests:

```zsh
--port=
```
