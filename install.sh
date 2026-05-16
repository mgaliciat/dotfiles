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

# Skills y memorias de Claude no se versionan (contenido personal/per-máquina).
# Si existen localmente, se symlinkean igual para mantener el workflow.
if [[ -d "$DOTFILES/claude/skills" ]]; then
  link "$DOTFILES/claude/skills"        "$HOME/.claude/skills"
fi
if [[ -d "$DOTFILES/claude/memory" ]]; then
  link "$DOTFILES/claude/memory"        "$HOME/.claude/projects/-Users-$(whoami | tr '.' '-')/memory"
fi

# ─── identidad git por-máquina ────────────────────────────────
# git/.gitconfig hace [include] de ~/.gitconfig.local — la identidad
# (name/email/signingkey) vive ahí, no en el repo público.
# Si no existe, prompt interactivo. Idempotente.
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  echo ""
  echo "Configurando ~/.gitconfig.local (identidad git por-máquina, no versionada)..."
  read -rp "  Git user.name: " git_name
  read -rp "  Git user.email: " git_email
  read -rp "  SSH signing key public (vacío para skip signing): " git_signing
  {
    echo "; ~/.gitconfig.local — identidad por-máquina (no versionado)"
    echo ""
    echo "[user]"
    echo "	name = $git_name"
    echo "	email = $git_email"
    [[ -n "$git_signing" ]] && echo "	signingkey = $git_signing"
    if [[ -n "$git_signing" && -x "/Applications/1Password.app/Contents/MacOS/op-ssh-sign" ]]; then
      echo ""
      echo "[gpg]"
      echo "	format = ssh"
      echo "[gpg \"ssh\"]"
      echo "	program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign"
      echo "[commit]"
      echo "	gpgsign = true"
    fi
  } > "$HOME/.gitconfig.local"
  echo "✓ ~/.gitconfig.local creado"
fi

# macOS file associations — abrir config.ghostty en VS Code (no TextEdit).
# .ghostty no tiene UTI registrada, así que macOS cae a TextEdit por default.
# Idempotente: chequea si la entrada ya existe antes de agregarla.
if [[ -d "/Applications/Visual Studio Code.app" ]]; then
  if ! defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null \
       | grep -q 'LSHandlerContentTag = ghostty'; then
    defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add \
      '{LSHandlerContentTag = "ghostty"; LSHandlerContentTagClass = "public.filename-extension"; LSHandlerRoleAll = "com.microsoft.vscode";}'
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
      -r -domain local -domain system -domain user >/dev/null
    killall lsd 2>/dev/null || true
    echo "✓ VS Code registered as default app for .ghostty files"
  fi
fi

echo ""
echo "✅ Done. Next steps:"
echo "   1. Create ~/.zshenv.local with your secrets."
echo "   2. brew install starship zsh-syntax-highlighting zsh-autosuggestions"
echo "      brew install eza bat fd ripgrep zoxide fzf git-delta"
echo "      brew install --cask ghostty"
