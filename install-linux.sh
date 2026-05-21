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

# Si hay tmux server corriendo, recargá el config para aplicar los
# cambios en sesiones activas sin tener que entrar al server a
# mano. Si no hay server (típico en WSL2 fresh login), skip — la
# próxima sesión nueva ya leerá el config fresco. Guarda `tmux info`
# para no romper si tmux no está instalado todavía.
if command -v tmux >/dev/null 2>&1 && tmux info >/dev/null 2>&1; then
  if tmux source-file "$HOME/.config/tmux/tmux.conf" 2>/dev/null; then
    echo "✓ tmux config recargado en sesiones activas"
  fi
fi

# ─── zsh-history-substring-search (no está en apt) ────────────
# El plugin manual va a ~/.zsh/plugins/, que el discovery del .zshrc
# probe como último fallback después de brew/linuxbrew/apt.
HSS_DIR="$HOME/.zsh/plugins/zsh-history-substring-search"
if [[ ! -d "$HSS_DIR" ]]; then
  echo "→ Clonando zsh-history-substring-search"
  git clone --depth 1 https://github.com/zsh-users/zsh-history-substring-search "$HSS_DIR"
fi

# ─── fzf-tab (tampoco está en apt) ────────────────────────────
# Mismo patrón que arriba: clone a ~/.zsh/plugins/. El discovery
# del .zshrc lo recoge como fallback. En mac viene como formula
# brew `fzf-tab`, en Linux toca a mano.
FZFTAB_DIR="$HOME/.zsh/plugins/fzf-tab"
if [[ ! -d "$FZFTAB_DIR" ]]; then
  echo "→ Clonando fzf-tab"
  git clone --depth 1 https://github.com/Aloxaf/fzf-tab "$FZFTAB_DIR"
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
    eza                           # apt 23.10+; en versiones viejas falla → fallback GH release abajo
    zsh-syntax-highlighting
    zsh-autosuggestions
    python3
    python3-pip
  )
  # NOTA: 'neovim' NO está en esta lista a propósito — apt tiene v0.6.x,
  # tus plugins (lazy.nvim, blink.cmp, rustaceanvim) necesitan 0.10+.
  # Lo instalamos via GH release tarball abajo.

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
  echo "ℹ️  cargo (Rust toolchain) no detectado — tree-sitter-cli skipeado."
  echo "   (delta se instala via GH release abajo, no requiere cargo)."
  echo "   Para tree-sitter: instalá rustup y re-corré este script."
  echo "     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
fi

# ─── GitHub release binaries (lo que apt no tiene o tiene viejo) ────
# Helpers chicos: detección de arch + fetch del tag latest desde GH API.
_arch_x86_arm() {
  case "$(uname -m)" in
    x86_64)        echo "$1" ;;
    aarch64|arm64) echo "$2" ;;
    *)             echo "" ;;
  esac
}
_gh_latest_tag() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | grep -Po '"tag_name":\s*"v?\K[^"]+' | head -1
}

mkdir -p "$HOME/.local/bin"

# lazygit — no está en apt default. GH release tarball.
if ! command -v lazygit >/dev/null 2>&1; then
  echo ""
  echo "→ Instalando lazygit (GH release)"
  LG_VER=$(_gh_latest_tag jesseduffield/lazygit)
  LG_ARCH=$(_arch_x86_arm x86_64 arm64)
  if [[ -n "$LG_VER" && -n "$LG_ARCH" ]]; then
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_${LG_ARCH}.tar.gz" \
      | tar -xz -C /tmp lazygit && install /tmp/lazygit "$HOME/.local/bin/" && rm /tmp/lazygit \
      || echo "⚠️  lazygit install falló"
  else
    echo "⚠️  No pude resolver versión/arch de lazygit (LG_VER=$LG_VER LG_ARCH=$LG_ARCH)"
  fi
fi

# nvim — apt tiene 0.6.x, tus plugins necesitan 0.10+. Tarball release
# (no AppImage: el tarball no requiere FUSE, más robusto en WSL2).
NVIM_NEEDS_INSTALL=true
if command -v nvim >/dev/null 2>&1; then
  NVIM_VER=$(nvim --version | head -1 | grep -oP 'v\K[0-9]+\.[0-9]+' | head -1)
  NVIM_MAJOR=${NVIM_VER%.*}
  NVIM_MINOR=${NVIM_VER#*.}
  if (( NVIM_MAJOR > 0 )) || (( NVIM_MINOR >= 10 )); then
    NVIM_NEEDS_INSTALL=false
  fi
fi
if $NVIM_NEEDS_INSTALL; then
  echo ""
  echo "→ Instalando nvim 0.10+ (GH release tarball)"
  NVIM_ARCH=$(_arch_x86_arm x86_64 arm64)
  if [[ -n "$NVIM_ARCH" ]]; then
    NVIM_TARBALL="nvim-linux-${NVIM_ARCH}.tar.gz"
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/${NVIM_TARBALL}" -o /tmp/nvim.tar.gz \
      && rm -rf "$HOME/.local/share/nvim-linux" \
      && mkdir -p "$HOME/.local/share/nvim-linux" \
      && tar -xzf /tmp/nvim.tar.gz -C "$HOME/.local/share/nvim-linux" --strip-components=1 \
      && ln -sf "$HOME/.local/share/nvim-linux/bin/nvim" "$HOME/.local/bin/nvim" \
      && rm /tmp/nvim.tar.gz \
      || echo "⚠️  nvim install falló"
  fi
fi

# delta (git-delta) — GH release .deb. Más fácil que tarball y maneja
# dependencies/uninstall via apt. dpkg con sudo.
if ! command -v delta >/dev/null 2>&1; then
  echo ""
  echo "→ Instalando delta (GH release .deb)"
  DELTA_VER=$(_gh_latest_tag dandavison/delta)
  DELTA_ARCH=$(_arch_x86_arm amd64 arm64)
  if [[ -n "$DELTA_VER" && -n "$DELTA_ARCH" ]]; then
    curl -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VER}/git-delta_${DELTA_VER}_${DELTA_ARCH}.deb" -o /tmp/delta.deb \
      && sudo dpkg -i /tmp/delta.deb \
      && rm /tmp/delta.deb \
      || echo "⚠️  delta install falló (probá: sudo apt --fix-broken install)"
  fi
fi

# eza — fallback si apt no lo tuvo (Ubuntu < 23.10).
if ! command -v eza >/dev/null 2>&1; then
  echo ""
  echo "→ Instalando eza (GH release fallback, apt no lo tenía)"
  EZA_VER=$(_gh_latest_tag eza-community/eza)
  EZA_ARCH=$(_arch_x86_arm x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu)
  if [[ -n "$EZA_VER" && -n "$EZA_ARCH" ]]; then
    curl -fsSL "https://github.com/eza-community/eza/releases/download/v${EZA_VER}/eza_${EZA_ARCH}.tar.gz" \
      | tar -xz -C /tmp ./eza && install /tmp/eza "$HOME/.local/bin/" && rm /tmp/eza \
      || echo "⚠️  eza install falló"
  fi
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
echo "   5. Si algún tool sigue faltando: revisá output arriba — los ⚠️"
echo "      marcan installs fallidos. Suelen ser problemas de red o arch"
echo "      no soportada (sólo x86_64 + arm64 implementados)."
