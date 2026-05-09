#!/usr/bin/env zsh

set -euo pipefail

REPO_URL="${POPULAR_REPO_URL:-https://raw.githubusercontent.com/sajjadRabiee/popular-zsh/main/popular.zsh}"
INSTALL_DIR="${POPULAR_INSTALL_DIR:-$HOME/.popular-zsh}"
TARGET_FILE="$INSTALL_DIR/popular.zsh"
ZSHRC_FILE="${ZDOTDIR:-$HOME}/.zshrc"

mkdir -p "$INSTALL_DIR"
curl -fsSL "$REPO_URL" -o "$TARGET_FILE"

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
