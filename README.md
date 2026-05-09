# popular.zsh

Tiny `zsh` shortcuts for saving, running, and templating your most-used commands.

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

After this repo is pushed to GitHub, you will be able to install it with:

```zsh
curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/install.sh | zsh
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
padd pricing-test ./bin/digikala-pricing/cli.sh supernova:pricing:test:command
p pricing-test
```

Save a templated command:

```zsh
padd pcatmap './bin/digikala-pricing/cli.sh supernova:entity:create:schema:from:entities get-only-one --entity_class={{class}}'
```

Run it with a variable:

```zsh
p pcatmap --class='Digikala\Supernova\Digikala\Nagini\Entity\Category\CategoryMappingEntity'
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
padd db-change './bin/digikala-admin/cli.sh supernova:switch:db:config:command {{env}} sajjad.rabiee YOUR_PASSWORD'
p db-change --env=prod
```

## Completion

If `compinit` is available, the script enables completion automatically:

- `p <TAB>` suggests saved command names
- `premove <TAB>` suggests saved command names
- `p pcatmap <TAB>` suggests template options like `--class=`

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
