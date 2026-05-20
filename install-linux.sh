#!/usr/bin/env bash
# Symlinks portable dotfiles + auto-install packages para Ubuntu/Debian.
# Target primario: WSL2 Ubuntu (sin GUI Linux — Windows Terminal afuera).
# Para macOS usar ./install.sh.
#
# Idempotente: backs up existing files antes de symlinkear.
# Strategy: apt para lo que está + cargo install para lo missing.

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

# ─── symlinks (subset portable de install.sh) ─────────────────
# Skip: ghostty (GUI), karabiner (macOS only), themes (eran de Ghostty).
link "$DOTFILES/zsh/.zshrc"             "$HOME/.zshrc"
link "$DOTFILES/zsh/.zshenv"            "$HOME/.zshenv"
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/git/.gitignore_global"  "$HOME/.gitignore_global"
link "$DOTFILES/nvim"                   "$HOME/.config/nvim"
link "$DOTFILES/tmux"                   "$HOME/.config/tmux"
link "$DOTFILES/lazygit/config.yml"     "$HOME/.config/lazygit/config.yml"

# ~/.gitconfig NO se symlinkea — per-máquina, igual que en mac.

# Claude Code per-máquina (mismo patrón que install.sh).
if [[ -f "$DOTFILES/claude/settings.json" ]]; then
  link "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
fi
if [[ -d "$DOTFILES/claude/skills" ]]; then
  link "$DOTFILES/claude/skills"        "$HOME/.claude/skills"
fi
if [[ -d "$DOTFILES/claude/memory" ]]; then
  link "$DOTFILES/claude/memory"        "$HOME/.claude/projects/-home-$(whoami | tr '.' '-')/memory"
fi

# ─── tpm (Tmux Plugin Manager) ────────────────────────────────
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  echo "→ Clonando tpm en $TPM_DIR"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
  echo "✓ tpm instalado. Dentro de tmux: prefix + I para instalar plugins"
fi

# ─── zsh-history-substring-search (no está en apt) ────────────
# El plugin manual va a ~/.zsh/plugins/, que el discovery del .zshrc
# probe como último fallback después de brew/linuxbrew/apt.
HSS_DIR="$HOME/.zsh/plugins/zsh-history-substring-search"
if [[ ! -d "$HSS_DIR" ]]; then
  echo "→ Clonando zsh-history-substring-search"
  git clone --depth 1 https://github.com/zsh-users/zsh-history-substring-search "$HSS_DIR"
fi

# ─── apt packages ──────────────────────────────────────────────
# Lo que apt tiene out-of-the-box en Ubuntu 24.04 / Debian 12.
# Lazygit y nvim modernos NO están — esos van por GitHub releases / AppImage.
if command -v apt-get >/dev/null 2>&1; then
  APT_PACKAGES=(
    zsh
    git
    curl
    unzip
    build-essential
    tmux
    ripgrep
    fd-find                       # binary es 'fdfind' — apt lo nombra así por colisión con otro 'fd'
    bat                           # en Ubuntu 20.04 era 'batcat'; 22.04+ es 'bat'
    fzf
    eza                           # apt 23.10+; en versiones viejas fallará → cargo lo cubre
    zsh-syntax-highlighting
    zsh-autosuggestions
    python3
    python3-pip
  )

  MISSING_APT=()
  for pkg in "${APT_PACKAGES[@]}"; do
    dpkg -s "$pkg" >/dev/null 2>&1 || MISSING_APT+=("$pkg")
  done

  if [[ ${#MISSING_APT[@]} -gt 0 ]]; then
    echo ""
    echo "→ apt packages a instalar: ${MISSING_APT[*]}"
    echo "  (requiere sudo)"
    sudo apt-get update
    # `|| true`: algunos packages pueden no existir en Ubuntu viejo (ej. eza
    # pre-23.10). Continuamos para que cargo los cubra después.
    sudo apt-get install -y "${MISSING_APT[@]}" || \
      echo "⚠️  Algunos packages fallaron — cargo install va a cubrir lo que falta."
  fi
else
  echo "⚠️  apt-get no detectado — saltando instalación de packages."
fi

# ─── starship + zoxide (curl installers oficiales) ─────────────
# Estos NO requieren cargo — bajan el binary precompilado a ~/.local/bin.
# Críticos porque el .zshrc los invoca (eval starship/zoxide init).

if ! command -v starship >/dev/null 2>&1; then
  echo ""
  echo "→ Instalando starship (curl installer oficial)"
  # -y: install sin prompt; -b ~/.local/bin: no requiere sudo
  curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin" \
    || echo "⚠️  starship install falló — el .zshrc va a skipear prompt"
fi

if ! command -v zoxide >/dev/null 2>&1; then
  echo ""
  echo "→ Instalando zoxide (curl installer oficial)"
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash \
    || echo "⚠️  zoxide install falló — el .zshrc va a skipear cd inteligente"
fi

# ─── cargo packages (sólo lo que realmente necesita Rust toolchain) ───
# delta y tree-sitter no tienen curl installer oficial cómodo.
# Si falta cargo, los skipeamos con mensaje claro (no son críticos).
if command -v cargo >/dev/null 2>&1; then
  declare -A CARGO_PACKAGES=(
    [git-delta]=delta             # crate "git-delta" instala binario "delta"
    [tree-sitter-cli]=tree-sitter
  )

  for crate in "${!CARGO_PACKAGES[@]}"; do
    binary="${CARGO_PACKAGES[$crate]}"
    if ! command -v "$binary" >/dev/null 2>&1; then
      echo "→ cargo install $crate"
      cargo install --locked "$crate" || echo "⚠️  $crate falló"
    fi
  done
else
  echo ""
  echo "ℹ️  cargo (Rust toolchain) no detectado — delta + tree-sitter-cli skipeados."
  echo "   Son opcionales (delta = pretty git diffs, tree-sitter = nvim parsers)."
  echo "   Si los querés: instalá rustup y re-corré este script."
  echo "     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
fi

# ─── pyenv (curl installer oficial) ────────────────────────────
# apt no tiene pyenv. El installer oficial setea ~/.pyenv y lo deja
# listo para el lazy-loader del .zshrc.
if [[ ! -d "$HOME/.pyenv" ]]; then
  echo ""
  echo "→ Instalando pyenv (curl installer oficial)"
  curl https://pyenv.run | bash || echo "⚠️  pyenv install falló"
fi

# ─── default shell a zsh ───────────────────────────────────────
if [[ "$(basename "${SHELL:-}")" != "zsh" ]] && command -v zsh >/dev/null 2>&1; then
  echo ""
  echo "→ Cambiando shell default a zsh"
  chsh -s "$(command -v zsh)" || \
    echo "⚠️  chsh falló — corré 'chsh -s \$(which zsh)' a mano (puede pedir password)."
fi

# ─── WSL2-specific helpers (detección heurística) ─────────────
if [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSLENV:-}" ]] || \
   grep -qi microsoft /proc/version 2>/dev/null; then
  echo ""
  echo "ℹ️  WSL2 detectado:"
  echo "   - Fonts: usá las del Windows Terminal (no instales fonts adentro de WSL)."
  echo "   - Ghostty: no aplicable — config se ignora."
  echo "   - Clipboard nvim: instalá win32yank para integración con Windows clipboard:"
  echo "       curl -sLo /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip"
  echo "       mkdir -p ~/.local/bin"
  echo "       unzip -p /tmp/win32yank.zip win32yank.exe > ~/.local/bin/win32yank.exe"
  echo "       chmod +x ~/.local/bin/win32yank.exe"
fi

echo ""
echo "✅ Done. Próximos pasos:"
echo "   1. Credenciales/env vars per-máquina: crear ~/.zshenv.local"
echo "   2. Aliases/funciones per-máquina: crear ~/.zshrc.local"
echo "   3. Abrir shell nuevo: exec zsh"
echo "   4. Adentro de tmux la primera vez: prefix + I para plugins"
echo "   5. neovim apt es viejo — para 0.12+ instalá AppImage:"
echo "        curl -sLo ~/.local/bin/nvim https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
echo "        chmod +x ~/.local/bin/nvim"
echo "   6. lazygit (no en apt): descargá binary de https://github.com/jesseduffield/lazygit/releases"
