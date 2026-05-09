# Examples

## Git shortcuts

```zsh
padd gs git status
padd gp git pull
p gs
```

## Local server

Positional port (`[[port]]`):

```zsh
padd serve 'python3 -m http.server [[port]]'
p serve 3000
```

Long-option port (`{{port}}`):

```zsh
padd serveo 'python3 -m http.server {{port}}'
p serveo --port=3000
```

## Docker

```zsh
padd up 'docker compose up -d'
padd down 'docker compose down'
p up
```

## Project commands

```zsh
padd test 'npm test'
padd lint 'npm run lint'
p test
```

## History (`paddh`)

After you run a long command, bookmark it by history index instead of retyping:

```zsh
history | tail
paddh 523 deploy-staging
paddh -1 last-cmd
```

## Backup and sync (`pexport` / `pimport`)

```zsh
pexport ~/Desktop/popular-commands.backup
pimport ~/Desktop/popular-commands.backup
```

Replace everything from a file (use with care):

```zsh
pimport -r ~/Desktop/popular-commands.backup
```
