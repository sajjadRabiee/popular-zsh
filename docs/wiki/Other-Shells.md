# Using popular.zsh from other shells

`popular.zsh` is a zsh-native tool, but its store is a plain text file and every command is run through a `zsh` process—so users of **bash**, **fish**, **nushell**, and other shells can use it as long as `zsh` is installed.

> **Auto-configured by the installer:** The one-line curl installer detects your shell via `$SHELL` and writes the right snippet below automatically. If you already ran it, your config is set up — just reload your shell. The sections here are for manual installation or customisation. Override detection with `POPULAR_SHELL=bash` (or `fish`, `nu`) before the curl command.

## Prerequisite: install zsh

| Platform | Command |
|----------|---------|
| macOS | Ships with the OS. Upgrade: `brew install zsh` |
| Debian / Ubuntu | `sudo apt install zsh` |
| Fedora / RHEL | `sudo dnf install zsh` |
| Arch | `sudo pacman -S zsh` |
| Alpine | `apk add zsh` |
| Windows (WSL) | Install a Linux distro in WSL, then use the table above |

You do **not** need to change your default shell. `popular.zsh` only requires that `zsh` is somewhere on your `PATH`.

---

## Bash

Add the following to `~/.bashrc` (or `~/.bash_profile` for login shells):

```bash
# popular.zsh wrappers for bash
_p_zsh() {
  local cmd="$1"; shift
  zsh -c "source ~/.popular-zsh/popular.zsh 2>/dev/null && $cmd \"\$@\"" -- "$@"
}

p()       { _p_zsh p       "$@"; }
padd()    { _p_zsh padd    "$@"; }
paddh()   { _p_zsh paddh   "$@"; }
pls()     { _p_zsh pls     "$@"; }
premove() { _p_zsh premove "$@"; }
pedit()   { _p_zsh pedit   "$@"; }
pexport() { _p_zsh pexport "$@"; }
pimport() { _p_zsh pimport "$@"; }
psecret() { _p_zsh psecret "$@"; }
pupdate() { zsh -c "source ~/.popular-zsh/popular.zsh 2>/dev/null && pupdate"; }
phelp()   { zsh -c "source ~/.popular-zsh/popular.zsh 2>/dev/null && phelp";   }
pcli()    { zsh -i -c "source ~/.popular-zsh/popular.zsh 2>/dev/null && pcli"; }
```

Reload: `source ~/.bashrc`

### Limitation

Each wrapper call runs in its own short-lived `zsh` process. Commands that `cd` into a directory or `export` a variable will **not** affect your current bash session. For a persistent working environment, use `pcli` — it opens an interactive zsh sub-shell with the full popular experience.

---

## Fish

Add functions to `~/.config/fish/config.fish`:

```fish
# popular.zsh wrappers for fish
function _p_zsh
    set --local cmd $argv[1]
    set --erase argv[1]
    zsh -c "source ~/.popular-zsh/popular.zsh 2>/dev/null && $cmd \"\$@\"" -- $argv
end

function p;       _p_zsh p       $argv; end
function padd;    _p_zsh padd    $argv; end
function paddh;   _p_zsh paddh   $argv; end
function pls;     _p_zsh pls     $argv; end
function premove; _p_zsh premove $argv; end
function pedit;   _p_zsh pedit   $argv; end
function pexport; _p_zsh pexport $argv; end
function pimport; _p_zsh pimport $argv; end
function psecret; _p_zsh psecret $argv; end
function pupdate
    zsh -c "source ~/.popular-zsh/popular.zsh 2>/dev/null && pupdate"
end
function phelp
    zsh -c "source ~/.popular-zsh/popular.zsh 2>/dev/null && phelp"
end
function pcli
    zsh -i -c "source ~/.popular-zsh/popular.zsh 2>/dev/null && pcli"
end
```

Reload: `source ~/.config/fish/config.fish`

Tab completion for saved names is not available through these wrappers (fish and zsh completions are separate systems), but you get it automatically inside `pcli`.

---

## Nushell

Add definitions to your `config.nu` (`$nu.config-path`):

```nu
# popular.zsh wrappers for nushell
def p [...rest: string] { zsh -c $"source ~/.popular-zsh/popular.zsh 2>/dev/null && p ($rest | str join ' ')" }
def padd [...rest: string] { zsh -c $"source ~/.popular-zsh/popular.zsh 2>/dev/null && padd ($rest | str join ' ')" }
def paddh [...rest: string] { zsh -c $"source ~/.popular-zsh/popular.zsh 2>/dev/null && paddh ($rest | str join ' ')" }
def pls [...rest: string] { zsh -c $"source ~/.popular-zsh/popular.zsh 2>/dev/null && pls ($rest | str join ' ')" }
def premove [name: string] { zsh -c $"source ~/.popular-zsh/popular.zsh 2>/dev/null && premove ($name)" }
def pedit [...rest: string] { zsh -c $"source ~/.popular-zsh/popular.zsh 2>/dev/null && pedit ($rest | str join ' ')" }
def pexport [...rest: string] { zsh -c $"source ~/.popular-zsh/popular.zsh 2>/dev/null && pexport ($rest | str join ' ')" }
def pimport [...rest: string] { zsh -c $"source ~/.popular-zsh/popular.zsh 2>/dev/null && pimport ($rest | str join ' ')" }
def psecret [...rest: string] { zsh -c $"source ~/.popular-zsh/popular.zsh 2>/dev/null && psecret ($rest | str join ' ')" }
def pupdate [] { zsh -c "source ~/.popular-zsh/popular.zsh 2>/dev/null && pupdate" }
def phelp [] { zsh -c "source ~/.popular-zsh/popular.zsh 2>/dev/null && phelp" }
def pcli [] { zsh -i -c "source ~/.popular-zsh/popular.zsh 2>/dev/null && pcli" }
```

---

## Interactive session with `pcli` (any shell)

`pcli` opens a full interactive zsh sub-shell. It is the easiest path for any non-zsh user who wants the complete popular experience — saved names work as first-class commands, short aliases (`add`, `list`, `bye`, …) are active, and tab completion works.

From bash, fish, nushell, or any POSIX shell:

```sh
# If popular.zsh is sourced in ~/.zshrc (the installer does this):
zsh          # starts zsh → .zshrc loads → popular.zsh is available
pcli         # enter the popular sub-shell

# Or in one line without modifying your .zshrc:
zsh -i -c "source ~/.popular-zsh/popular.zsh && pcli"
```

Type `bye` (or press `Ctrl-D`) to return to your original shell.

---

## Shared store across shells

All shells read and write the **same** backing file (`~/.popular_commands` by default). Commands you save from bash are immediately visible in fish, zsh, or anywhere else.

To use a non-default path, set the variable **before** calling the wrapper:

```bash
# bash / POSIX sh
export POPULAR_COMMANDS_FILE="$HOME/.config/popular/commands"
export POPULAR_SECRETS_FILE="$HOME/.config/popular/secrets"
```

```fish
# fish
set -x POPULAR_COMMANDS_FILE ~/.config/popular/commands
set -x POPULAR_SECRETS_FILE  ~/.config/popular/secrets
```

The `zsh` sub-process inherits these environment variables automatically.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `zsh: command not found` | `zsh` is not installed | Install it (see table above) |
| Wrapper shows no output | Wrong path to `popular.zsh` | Check `~/.popular-zsh/popular.zsh` exists; re-run the installer |
| `cd` in a saved command has no effect | Expected — runs in a sub-process | Use `pcli` for an interactive session |
| Secrets not found | `POPULAR_SECRETS_FILE` not exported | Export the variable before calling the wrapper |
| No tab completion | Wrappers are shell functions, not zsh builtins | Use `pcli` for full tab completion |
