# popular.zsh
# A tiny zsh helper for saving and reusing your favorite commands.

: "${POPULAR_COMMANDS_FILE:=$HOME/.popular_commands}"
: "${POPULAR_SECRETS_FILE:=${POPULAR_COMMANDS_FILE}.secrets}"

autoload -Uz colors
colors

_POPULAR_INSTALL_DIR="${0:A:h}"
source "$_POPULAR_INSTALL_DIR/lib/popular/ui.zsh"
source "$_POPULAR_INSTALL_DIR/lib/popular/store.zsh"
source "$_POPULAR_INSTALL_DIR/lib/popular/template.zsh"
source "$_POPULAR_INSTALL_DIR/lib/popular/secrets.zsh"
source "$_POPULAR_INSTALL_DIR/lib/popular/cmd-add.zsh"
source "$_POPULAR_INSTALL_DIR/lib/popular/cmd-run.zsh"
source "$_POPULAR_INSTALL_DIR/lib/popular/cmd-list.zsh"
source "$_POPULAR_INSTALL_DIR/lib/popular/cmd-io.zsh"
source "$_POPULAR_INSTALL_DIR/lib/popular/cmd-edit.zsh"
source "$_POPULAR_INSTALL_DIR/lib/popular/completion.zsh"
