#!/usr/bin/env zsh

set -euo pipefail

REPO_BASE="${POPULAR_REPO_BASE:-https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main}"
INSTALL_DIR="${POPULAR_INSTALL_DIR:-$HOME/.popular-zsh}"
TARGET_FILE="$INSTALL_DIR/popular.zsh"
ZSHRC_FILE="${ZDOTDIR:-$HOME}/.zshrc"

typeset -a POPULAR_MODULE_PATHS=(
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
  lib/popular/completion.zsh
)

mkdir -p "$INSTALL_DIR/lib/popular"

for rel in "${POPULAR_MODULE_PATHS[@]}"; do
  out="$INSTALL_DIR/$rel"
  mkdir -p "${out:h}"
  curl -fsSL "$REPO_BASE/$rel" -o "$out"
done

if ! grep -Fq "source $TARGET_FILE" "$ZSHRC_FILE" 2>/dev/null; then
  {
    echo
    echo "# popular.zsh"
    echo "source $TARGET_FILE"
  } >> "$ZSHRC_FILE"
fi

echo "Installed to $TARGET_FILE"
echo "Reload your shell with:"
echo "  source \"$ZSHRC_FILE\""
