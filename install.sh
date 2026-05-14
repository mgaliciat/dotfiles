#!/usr/bin/env bash
# Symlinks dotfiles into their expected locations.
# Idempotent: backs up existing files before linking.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d_%H%M%S)"

link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    echo "→ backing up existing $dst to $dst.backup.$TS"
    mv "$dst" "$dst.backup.$TS"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "✓ $dst → $src"
}

link "$DOTFILES/zsh/.zshrc"             "$HOME/.zshrc"
link "$DOTFILES/zsh/.zshenv"            "$HOME/.zshenv"
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/ghostty/config.ghostty" "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
link "$DOTFILES/git/.gitconfig"         "$HOME/.gitconfig"
link "$DOTFILES/git/.gitignore_global"  "$HOME/.gitignore_global"
link "$DOTFILES/claude/settings.json"   "$HOME/.claude/settings.json"
link "$DOTFILES/claude/skills"          "$HOME/.claude/skills"
link "$DOTFILES/claude/memory"          "$HOME/.claude/projects/-Users-$(whoami | tr '.' '-')/memory"

echo ""
echo "✅ Done. Next steps:"
echo "   1. Create ~/.zshenv.local with your secrets."
echo "   2. brew install starship zsh-syntax-highlighting zsh-autosuggestions"
echo "      brew install eza bat fd ripgrep zoxide fzf git-delta"
echo "      brew install --cask ghostty"
