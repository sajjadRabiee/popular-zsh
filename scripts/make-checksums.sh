#!/usr/bin/env sh
# Run from the repo root before each release to regenerate checksums.sha256.
# Does NOT include checksums.sha256 itself (that would be circular).
set -eu

cd "$(dirname "$0")/.."

FILES="
popular.zsh
install.sh
lib/popular/ui.zsh
lib/popular/store.zsh
lib/popular/template.zsh
lib/popular/secrets.zsh
lib/popular/cmd-add.zsh
lib/popular/cmd-run.zsh
lib/popular/cmd-list.zsh
lib/popular/cmd-io.zsh
lib/popular/cmd-edit.zsh
lib/popular/cmd-update.zsh
lib/popular/cmd-cli.zsh
lib/popular/cmd-help.zsh
lib/popular/completion.zsh
"

if command -v sha256sum >/dev/null 2>&1; then
  # shellcheck disable=SC2086
  sha256sum $FILES > checksums.sha256
elif command -v shasum >/dev/null 2>&1; then
  # shellcheck disable=SC2086
  shasum -a 256 $FILES > checksums.sha256
else
  echo "error: neither sha256sum nor shasum found" >&2
  exit 1
fi

echo "checksums.sha256 updated."
