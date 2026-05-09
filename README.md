# popular.zsh

Tiny `zsh` shortcuts for saving, running, and templating your most-used commands.

- Preview image: `assets/social-preview.png`
- Wiki docs: `docs/wiki/`
- Launch post: `docs/launch-post.md`

It gives you:

- `padd` to save commands
- `p` to run them
- `pls` to list them in a clean view
- `premove` to remove them
- `pedit` to edit the storage file directly
- tab completion for command names
- tab completion for template options like `--class=`

## Install

### Local

Add this line to your `~/.zshrc`:

```zsh
source /absolute/path/to/popular.zsh
```

Then reload your shell:

```zsh
source ~/.zshrc
```

### Curl install

```zsh
curl -fsSL https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main/install.sh | zsh
```

## Commands

```zsh
padd <name> <command...>
p <name> [options...]
pls
premove <name>
pedit
phelp
```

## Examples

Save and run a simple command:

```zsh
padd gs git status
p gs
```

Save a templated command:

```zsh
padd serve 'python3 -m http.server {{port}}'
```

Run it with a variable:

```zsh
p serve --port=8000
```

## Templates

You can use placeholders inside saved commands:

```zsh
{{class}}
{{env}}
{{module_id}}
```

Each placeholder becomes a runtime option:

- `{{class}}` becomes `--class`
- `{{env}}` becomes `--env`
- `{{module_id}}` becomes `--module_id`

Example:

```zsh
padd open-model 'my-tool generate --entity_class={{class}} --env={{env}}'
p open-model --class='my.app.models.User' --env=dev
```

## Completion

If `compinit` is available, the script enables completion automatically:

- `p <TAB>` suggests saved command names
- `premove <TAB>` suggests saved command names
- `p serve <TAB>` suggests template options like `--port=`

## Storage

Saved commands live in:

```zsh
~/.popular_commands
```

You can override that path with:

```zsh
export POPULAR_COMMANDS_FILE=/path/to/your/file
```

## Project Files

- `popular.zsh`
- `install.sh`
- `docs/launch-post.md`
- `docs/wiki/`
