#!/usr/bin/env zsh

set -euo pipefail

REPO_URL="${POPULAR_REPO_URL:-}"
INSTALL_DIR="${POPULAR_INSTALL_DIR:-$HOME/.popular-zsh}"
TARGET_FILE="$INSTALL_DIR/popular.zsh"
ZSHRC_FILE="${ZDOTDIR:-$HOME}/.zshrc"

if [[ -z "$REPO_URL" ]]; then
  echo "Set POPULAR_REPO_URL before running install.sh."
  echo "Example:"
  echo "  POPULAR_REPO_URL=https://raw.githubusercontent.com/USERNAME/REPO/main/popular.zsh curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/install.sh | zsh"
  exit 1
fi

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
