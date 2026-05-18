# lib/popular/cmd-help.zsh
# Per-command --help panels.  Each public function calls its counterpart
# when invoked with --help or -h.

_popular_help_p() {
  _popular_help_open "p" "run a saved command"
  _popular_usage_row "p <name> [args…]" "Expand {{opt}}, [[pos]], <<secret>> placeholders then exec"
  _popular_help_examples
  _popular_usage_example_line "p gs"
  _popular_usage_example_line "p serve 8000"
  _popular_usage_example_line "p hit localhost --port=8080"
  _popular_help_close
}

_popular_help_padd() {
  _popular_help_open "padd" "save a command by name"
  _popular_usage_row "padd <name> <command…>" "Save or replace a command"
  _popular_help_examples
  _popular_usage_example_line "padd gs git status"
  _popular_usage_example_line "padd serve 'python3 -m http.server [[port]]'"
  _popular_usage_example_line "padd hook 'curl -H \"Auth: Bearer <<token>>\" \$URL'"
  _popular_help_close
}

_popular_help_paddh() {
  _popular_help_open "paddh" "save a command from shell history"
  _popular_usage_row "paddh <history#> [name]" "Save event # (from \`history\`); name defaults to h<#>"
  _popular_usage_row "" "Negative numbers count back: -1 = previous command"
  _popular_help_examples
  _popular_usage_example_line "paddh 523 deploy-staging"
  _popular_usage_example_line "paddh -1          # save previous command as h-1"
  _popular_help_close
}

_popular_help_pls() {
  _popular_help_open "pls" "list saved commands"
  _popular_usage_row "pls [needle…]" "List all commands; optional case-insensitive substring filter"
  _popular_help_examples
  _popular_usage_example_line "pls"
  _popular_usage_example_line "pls git     # show only names containing 'git'"
  _popular_help_close
}

_popular_help_premove() {
  _popular_help_open "premove" "delete a saved command"
  _popular_usage_row "premove <name>" "Remove <name> and its associated secrets"
  _popular_help_examples
  _popular_usage_example_line "premove gs"
  _popular_help_close
}

_popular_help_pedit() {
  _popular_help_open "pedit" "edit a saved command in \$EDITOR"
  _popular_usage_row "pedit [name]" "Edit <name>'s text; omit to open the full store"
  _popular_help_examples
  _popular_usage_example_line "pedit gs       # edit one command"
  _popular_usage_example_line "pedit          # open full store in \$EDITOR"
  _popular_help_close
}

_popular_help_pexport() {
  _popular_help_open "pexport" "export commands to a file (secrets never included)"
  _popular_usage_row "pexport [file|-]" "Write commands to <file>; - or omitted → stdout"
  _popular_help_examples
  _popular_usage_example_line "pexport ~/my-commands.txt"
  _popular_usage_example_line "pexport -         # stdout"
  _popular_help_close
}

_popular_help_pimport() {
  _popular_help_open "pimport" "import commands from a file or remote repo"
  _popular_usage_row "pimport [-r] [-R] <file|repo>" "Merge (or replace) commands into the store"
  _popular_usage_row "-r / --replace" "Replace the entire store instead of merging"
  _popular_usage_row "-R / --remote"  "Fetch from a URL or owner/repo shorthand (requires curl)"
  _popular_help_examples
  _popular_usage_example_line "pimport ~/my-commands.txt"
  _popular_usage_example_line "pimport -r ~/team-commands.txt"
  _popular_usage_example_line "pimport -R alice/popular-git-pack"
  _popular_usage_example_line "pimport -R alice/popular-git-pack:dev"
  _popular_usage_example_line "pimport -r -R alice/popular-git-pack   # replace with remote pack"
  _popular_help_close
}

_popular_help_psecret() {
  _popular_help_open "psecret" "store an AES-256 encrypted secret"
  _popular_usage_row "psecret -g <key>" "Global <<key>>; used first by \`p\` for any command"
  _popular_usage_row "psecret <name> <key>" "Scoped <<key>> for <name>; fallback when no global"
  _popular_usage_row "-g / --global" "Store at global scope"
  _popular_help_examples
  _popular_usage_example_line "psecret -g token"
  _popular_usage_example_line "psecret deploy api-key"
  _popular_usage_example_line "echo mysecret | psecret -g token   # from stdin"
  _popular_help_close
}

_popular_help_plock() {
  _popular_help_open "plock" "clear the cached master password"
  _popular_usage_row "plock" "Wipe the master password from this session; next secret access re-prompts"
  _popular_help_close
}

_popular_help_pcli() {
  _popular_help_open "pcli" "interactive popular sub-shell"
  _popular_usage_row "pcli" "Sub-shell where saved names run directly (no \`p\` prefix); \`bye\` to exit"
  _popular_usage_sep
  local ip="  Aliases inside pcli" ic="  ${fg[yellow]}Aliases inside pcli${reset_color}"
  _popular_box_inner_line "$ip" "$ic"
  _popular_usage_sep
  _popular_usage_row "add / addh / list / remove" "→ padd / paddh / pls / premove"
  _popular_usage_row "edit / secret / secret-reset" "→ pedit / psecret / psecret-reset"
  _popular_usage_row "save / load / help / bye" "→ pexport / pimport / phelp / exit"
  _popular_help_close
}

_popular_help_pupdate() {
  _popular_help_open "pupdate" "update popular.zsh from GitHub"
  _popular_usage_row "pupdate" "Download all modules from \$POPULAR_REPO_BASE and re-source"
  _popular_usage_row "POPULAR_REPO_BASE" "Override the base URL (default: GitHub main branch)"
  _popular_help_close
}

_popular_help_psecret_migrate() {
  _popular_help_open "psecret-migrate" "encrypt a v1 plain-text secrets file"
  _popular_usage_row "psecret-migrate" "Re-encrypt all secrets with AES-256-CBC; keeps .bak until removed"
  _popular_help_close
}

_popular_help_psecret_reset() {
  _popular_help_open "psecret-reset" "change master password or wipe secrets when lost"
  _popular_usage_row "psecret-reset" "Asks whether you have the old password, then:"
  _popular_usage_row "  yes → rekey" "Verify old password, re-encrypt all secrets with new one"
  _popular_usage_row "  no  → wipe" "Warn + confirm, wipe secrets file, set new password"
  _popular_help_close
}
