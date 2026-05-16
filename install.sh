#!/usr/bin/env bash
# Symlinks dotfiles into their expected locations.
# Idempotent: backs up existing files before linking.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d_%H%M%S)"

# Captura identidad git existente ANTES de symlinkear ~/.gitconfig.
# Así si la máquina ya tenía nombre/email configurado (ej. Mac de trabajo)
# lo preservamos en ~/.gitconfig.local sin preguntar al usuario.
EXISTING_GIT_NAME="$(git config --global user.name 2>/dev/null || true)"
EXISTING_GIT_EMAIL="$(git config --global user.email 2>/dev/null || true)"
EXISTING_GIT_SIGNING="$(git config --global user.signingkey 2>/dev/null || true)"

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

# ─── identidad git por-máquina ────────────────────────────────
# git/.gitconfig hace [include] de ~/.gitconfig.local — la identidad
# (name/email/signingkey) vive ahí, no en el repo público.
#
# Si .local no existe pero la máquina ya tenía identidad git configurada
# (capturada arriba antes del symlink), la heredamos sin preguntar.
# Si tampoco había identidad previa, prompt interactivo.
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  if [[ -n "$EXISTING_GIT_NAME" && -n "$EXISTING_GIT_EMAIL" ]]; then
    git_name="$EXISTING_GIT_NAME"
    git_email="$EXISTING_GIT_EMAIL"
    git_signing="$EXISTING_GIT_SIGNING"
    echo "✓ Identidad git existente preservada en ~/.gitconfig.local ($git_email)"
  else
    echo ""
    echo "Configurando ~/.gitconfig.local (identidad git por-máquina, no versionada)..."
    read -rp "  Git user.name: " git_name
    read -rp "  Git user.email: " git_email
    read -rp "  SSH signing key public (vacío para skip signing): " git_signing
  fi
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
