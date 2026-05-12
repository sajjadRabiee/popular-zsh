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

## Secrets (`<<placeholders>>`)

Keep tokens out of the command file so `pexport` stays safe to share:

```zsh
padd notify 'curl -sf -u "<<user>>:<<pass>>" https://hooks.example.com/run'
print -r 'robot' | psecret -g user
print -r 'x1y2z3' | psecret -g pass
p notify
```

Use per-command overrides only when one bookmark needs a different value:

```zsh
psecret staging-hook pass   # prompt or pipe value
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

After import, if the file contains `<<secrets>>`, the shell may ask **global vs per-command** secret setup (TTY only), then guide you through `psecret`.

## Interactive popular shell (`pcli`)

Drop into a sub-shell where every saved command name works directly—no `p` prefix required. Your `PS1` stays intact; a `[p]` badge appears on the right so you always know you're inside the popular session.

```zsh
pcli
# — inside popular shell —
gs               # runs your saved "gs" directly
list             # alias for pls
add deploy 'kubectl rollout restart deploy/api'
deploy           # runs it straight away
bye              # exit back to normal shell
```

Useful when you want to run several bookmarks in a row without typing `p` each time, or when onboarding someone who should not need to learn the `p` prefix.
