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
# Stale `config` (sin extensión) huérfano gana sobre nuestro symlink y
# carga su contenido inline ignorando el theme del dotfiles. Backup
# defensivo antes de linkear config.ghostty.
GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
if [[ -f "$GHOSTTY_DIR/config" && ! -L "$GHOSTTY_DIR/config" ]]; then
  mv "$GHOSTTY_DIR/config" "$GHOSTTY_DIR/config.backup.$TS"
  echo "→ stale ghostty config movido a config.backup.$TS"
fi
link "$DOTFILES/ghostty/config.ghostty" "$GHOSTTY_DIR/config.ghostty"
# Themes viven en ~/.config/ghostty/themes/ (NO en Application Support/themes).
# Ghostty solo busca themes en ~/.config/ghostty/themes/ y en el bundle de la app.
link "$DOTFILES/ghostty/themes"         "$HOME/.config/ghostty/themes"
link "$DOTFILES/git/.gitignore_global"  "$HOME/.gitignore_global"
link "$DOTFILES/nvim"                   "$HOME/.config/nvim"
link "$DOTFILES/tmux"                   "$HOME/.config/tmux"
link "$DOTFILES/lazygit/config.yml"     "$HOME/.config/lazygit/config.yml"

# ~/.gitconfig NO se symlinkea — cada máquina lo mantiene 100% propio
# (credenciales, 1Password vaults, signing keys son per-máquina).

# Claude Code (settings, skills, memorias) — todo per-máquina, no versionado.
# Si existen localmente en dotfiles/claude/, los symlinkeamos. Si no, skip
# y cada máquina mantiene su propio ~/.claude/* sin interferencia.
if [[ -f "$DOTFILES/claude/settings.json" ]]; then
  link "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
fi
if [[ -d "$DOTFILES/claude/skills" ]]; then
  link "$DOTFILES/claude/skills"        "$HOME/.claude/skills"
fi
if [[ -d "$DOTFILES/claude/memory" ]]; then
  link "$DOTFILES/claude/memory"        "$HOME/.claude/projects/-Users-$(whoami | tr '.' '-')/memory"
fi

# ─── tpm (Tmux Plugin Manager) ────────────────────────────────
# Clona tpm en la ubicación que espera nuestro tmux.conf.
# Idempotente: si ya está, skip. Después de instalar, en tmux:
#   prefix + I  → instala los plugins listados en tmux.conf
#   prefix + U  → actualiza
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  echo "→ Clonando tpm en $TPM_DIR"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
  echo "✓ tpm instalado. Dentro de tmux: prefix + I para instalar plugins"
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

# ─── dependencias (Homebrew) ──────────────────────────────────
# Auto-instala lo que falte. Idempotente: re-runs detectan instalados y skipean.
# Si no hay brew, muestra cómo instalarlo y termina sin fallar el script.
if command -v brew >/dev/null 2>&1; then
  REQUIRED_FORMULAE=(
    starship
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-history-substring-search
    eza
    bat
    fd
    ripgrep
    zoxide
    fzf
    git-delta
    pyenv
    neovim
    tmux
    lazygit
  )
  REQUIRED_CASKS=(
    ghostty
  )

  MISSING_FORMULAE=()
  for pkg in "${REQUIRED_FORMULAE[@]}"; do
    brew list --formula "$pkg" >/dev/null 2>&1 || MISSING_FORMULAE+=("$pkg")
  done

  MISSING_CASKS=()
  for pkg in "${REQUIRED_CASKS[@]}"; do
    brew list --cask "$pkg" >/dev/null 2>&1 || MISSING_CASKS+=("$pkg")
  done

  if [[ ${#MISSING_FORMULAE[@]} -gt 0 ]]; then
    echo ""
    echo "→ Instalando formulae faltantes: ${MISSING_FORMULAE[*]}"
    brew install "${MISSING_FORMULAE[@]}"
  fi

  if [[ ${#MISSING_CASKS[@]} -gt 0 ]]; then
    echo ""
    echo "→ Instalando casks faltantes: ${MISSING_CASKS[*]}"
    brew install --cask "${MISSING_CASKS[@]}"
  fi

  if [[ ${#MISSING_FORMULAE[@]} -eq 0 && ${#MISSING_CASKS[@]} -eq 0 ]]; then
    echo "✓ Todas las dependencias de Homebrew ya están instaladas"
  fi
else
  echo ""
  echo "⚠️  Homebrew no detectado — saltando auto-install de dependencias."
  echo "   Para instalarlo:"
  echo "     /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  echo "   Después re-corré: ./install.sh"
fi

echo ""
echo "✅ Done. Next steps:"
echo "   1. Si tu máquina tiene credenciales/env vars propias: crear ~/.zshenv.local"
echo "   2. Si tu máquina tiene aliases/funciones propias: crear ~/.zshrc.local"
echo "   3. Abrir un shell nuevo: exec zsh"
