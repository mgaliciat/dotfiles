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
# Skip: ghostty y sus themes (GUI macOS-only). El resto del repo es
# el subset portable y se linkea igual que en mac.
link "$DOTFILES/zsh/.zshrc"             "$HOME/.zshrc"
link "$DOTFILES/zsh/.zshenv"            "$HOME/.zshenv"
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/git/.gitignore_global"  "$HOME/.gitignore_global"
link "$DOTFILES/nvim"                   "$HOME/.config/nvim"
link "$DOTFILES/tmux"                   "$HOME/.config/tmux"
link "$DOTFILES/lazygit/config.yml"     "$HOME/.config/lazygit/config.yml"

# ─── tema del stack ───────────────────────────────────────────
# Nada que hacer acá. Mismo motivo que en install.sh: paletas Y selección
# activa viajan versionadas y llegan por los symlinks de dir de arriba
# (acá solo nvim + tmux; sin ghostty en Linux/WSL2).

# ~/.gitconfig NO se symlinkea — per-máquina, igual que en mac.

# Claude Code per-máquina (mismo patrón que install.sh).
# settings.json NO se symlinkea (100% per-máquina, como ~/.gitconfig).
# memory/ tampoco: Claude Code la maneja per-proyecto derivando el path real
# del directorio, así que un symlink adivinado quedaba ignorado.
if [[ -d "$DOTFILES/claude/skills" ]]; then
  link "$DOTFILES/claude/skills"        "$HOME/.claude/skills"
fi

# ─── apt packages ──────────────────────────────────────────────
# Lo que apt tiene out-of-the-box en Ubuntu 24.04 / Debian 12.
# Lazygit y nvim modernos NO están — esos van por GitHub releases / AppImage.
# Va ANTES de los bloques de settings.json de más abajo: esos usan jq
# (instalado acá) — si corrieran primero, en una máquina fresca se
# skipearían en silencio y recién aplicarían en la segunda corrida.
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
    jq                            # requerido por tmux-claude-session-manager (parsea `claude agents --json`)
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

# fd: el paquete apt es fd-find y su binario se llama `fdfind`. El .zshrc
# (compartido con mac) espera `fd` — symlink en ~/.local/bin (ya en PATH
# vía .zshenv) para que fd/alias find funcionen igual en ambos.
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  echo "✓ symlink fd → fdfind en ~/.local/bin"
fi

# ─── status line + CLAUDE.md user-level de Claude Code (espejo de install.sh) ───
# Scripts/prosa genéricos versionados; la activación en settings.json
# solo se agrega si no existe ya (no pisa una config propia de la máquina).
link "$DOTFILES/claude/statusline.sh" "$HOME/.claude/statusline.sh"

# Va ANTES de la sección rtk de más abajo: rtk init --global le agrega
# una línea `@RTK.md` si falta, y queremos que esa escritura caiga sobre
# el archivo versionado (a través del symlink), no sobre uno suelto.
link "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

SETTINGS="$HOME/.claude/settings.json"
if command -v jq >/dev/null 2>&1; then
  mkdir -p "$(dirname "$SETTINGS")"
  [[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"
  if jq -e '.statusLine' "$SETTINGS" >/dev/null 2>&1; then
    echo "✓ statusLine ya configurado en settings.json — no se toca"
  else
    SETTINGS_TMP="$(mktemp)"
    if jq '.statusLine = {"type": "command", "command": "~/.claude/statusline.sh"}' "$SETTINGS" > "$SETTINGS_TMP"; then
      mv "$SETTINGS_TMP" "$SETTINGS"
      echo "✓ statusLine agregado a settings.json"
    else
      rm -f "$SETTINGS_TMP"
      echo "⚠️  no se pudo agregar statusLine — settings.json quedó intacto"
    fi
  fi
fi

# ─── permisos base de Claude Code (espejo de install.sh) ──────
# Igual que statusLine: excepción controlada, additive-only. Solo agrega
# permissions.allow/deny si esas keys NO existen ya en settings.json — si
# armaste tu propia lista a mano en esta máquina, no se toca. Lista curada
# a partir de la doc oficial (https://code.claude.com/docs/en/permissions):
# comandos read-only de Bash (git status/diff/log, ls, cat, grep, find,
# pwd, head, tail, wc, which, diff, stat, du, cd...) ya no piden
# confirmación por default. El allow cubre lo que sigue generando
# fricción real: writes de git, build/test tooling (npm, cargo, go, make,
# gradle/kotlinc/ktlint) y reemplazos modernos de esos read-only clásicos
# (rg, fd, eza, bat, fzf, jq, tree, delta — todos instalados por este
# script, ver APT_PACKAGES/cargo/GH-release más abajo). El deny bloquea
# lo obviamente destructivo incluso bajo bypassPermissions/auto.
SETTINGS="$HOME/.claude/settings.json"
if command -v jq >/dev/null 2>&1; then
  mkdir -p "$(dirname "$SETTINGS")"
  [[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"

  if jq -e '.permissions.allow' "$SETTINGS" >/dev/null 2>&1; then
    echo "✓ permissions.allow ya configurado en settings.json — no se toca"
  else
    SETTINGS_TMP="$(mktemp)"
    if jq '.permissions //= {} | .permissions.allow = [
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(npm run *)",
      "Bash(npm test *)",
      "Bash(cargo build *)",
      "Bash(cargo test *)",
      "Bash(make *)",
      "Bash(docker ps *)",
      "Bash(docker images *)",
      "Bash(go build *)",
      "Bash(go test *)",
      "Bash(go vet *)",
      "Bash(go mod *)",
      "Bash(go run *)",
      "Bash(gofmt *)",
      "Bash(kotlinc *)",
      "Bash(ktlint *)",
      "Bash(./gradlew build)",
      "Bash(./gradlew test)",
      "Bash(./gradlew clean)",
      "Bash(gradle build)",
      "Bash(gradle test)",
      "Bash(fzf *)",
      "Bash(rg *)",
      "Bash(fd *)",
      "Bash(eza *)",
      "Bash(bat *)",
      "Bash(jq *)",
      "Bash(tree *)",
      "Bash(delta *)"
    ]' "$SETTINGS" > "$SETTINGS_TMP"; then
      mv "$SETTINGS_TMP" "$SETTINGS"
      echo "✓ permissions.allow agregado a settings.json"
    else
      rm -f "$SETTINGS_TMP"
      echo "⚠️  no se pudo agregar permissions.allow — settings.json quedó intacto"
    fi
  fi

  if jq -e '.permissions.deny' "$SETTINGS" >/dev/null 2>&1; then
    echo "✓ permissions.deny ya configurado en settings.json — no se toca"
  else
    SETTINGS_TMP="$(mktemp)"
    if jq '.permissions //= {} | .permissions.deny = [
      "Bash(rm -rf *)",
      "Bash(git push --force*)",
      "Bash(sudo *)"
    ]' "$SETTINGS" > "$SETTINGS_TMP"; then
      mv "$SETTINGS_TMP" "$SETTINGS"
      echo "✓ permissions.deny agregado a settings.json"
    else
      rm -f "$SETTINGS_TMP"
      echo "⚠️  no se pudo agregar permissions.deny — settings.json quedó intacto"
    fi
  fi
fi

# ─── rtk (proxy CLI que reduce tokens) ────────────────────────
# Mismo comportamiento que install.sh (mac) — ver ese script para el
# razonamiento completo. Sin Homebrew acá: usamos el curl installer
# oficial de rtk (baja a ~/.local/bin, mismo patrón que starship/zoxide
# más abajo). Solo instala si falta el binario; `rtk init --global
# --auto-patch` es idempotente (no duplica el hook en re-runs).
if ! command -v rtk >/dev/null 2>&1; then
  echo ""
  echo "→ Instalando rtk (curl installer oficial)"
  curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh \
    || echo "⚠️  rtk install falló"
fi

if command -v rtk >/dev/null 2>&1; then
  if rtk init --global --auto-patch >/dev/null 2>&1 </dev/null; then
    echo "✓ rtk hook de Claude Code configurado (o ya estaba)"
  else
    echo "⚠️  rtk init --global falló — revisar a mano (rtk init --global -v)"
  fi
fi

# ─── codebase-memory-mcp (MCP server de grafo de código) ──────
# Mismo comportamiento que install.sh (mac) — sin Homebrew acá tampoco,
# así que usamos el install.sh oficial del proyecto (curl | bash), que
# ya detecta el binario Linux (arm64/amd64) solo. Sin --ui (headless,
# default del propio installer). Solo instala si falta el binario
# (~260MB, no hace falta re-descargar en cada corrida).
if ! command -v codebase-memory-mcp >/dev/null 2>&1; then
  echo ""
  echo "→ Instalando codebase-memory-mcp"
  curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash \
    || echo "⚠️  codebase-memory-mcp install falló"
fi

if command -v codebase-memory-mcp >/dev/null 2>&1; then
  codebase-memory-mcp config set auto_index true >/dev/null 2>&1
  echo "✓ codebase-memory-mcp: auto_index=true"
fi

# Limpieza convergente (espejo de install.sh): el binario hace su propio
# fopen(~/.zshrc, "a") y agrega `export PATH=...` si no encuentra un
# match TEXTUAL exacto (src/cli/cli.c, cbm_detect_shell_rc). Nuestro PATH
# vive en zsh/.zshenv con `$HOME`, así que ese chequeo naive nunca lo
# reconoce y re-agrega su línea con el path de esta máquina hardcodeado.
# Como ~/.zshrc es symlink a este repo, ensucia el archivo versionado.
ZSHRC="$HOME/.zshrc"
if [[ -f "$ZSHRC" ]] && grep -qF "# Added by codebase-memory-mcp install" "$ZSHRC"; then
  ZSHRC_TMP="$(mktemp)"
  if awk '
    /^# Added by codebase-memory-mcp install$/ { skip = 2; next }
    skip > 0 { skip--; next }
    { print }
  ' "$ZSHRC" > "$ZSHRC_TMP"; then
    mv "$ZSHRC_TMP" "$ZSHRC"
    echo "✓ línea de PATH que codebase-memory-mcp agregó a .zshrc limpiada (ya cubierto por .zshenv)"
  else
    rm -f "$ZSHRC_TMP"
    echo "⚠️  no se pudo limpiar .zshrc — revisar a mano"
  fi
fi

# ─── tpm (Tmux Plugin Manager) ────────────────────────────────
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  echo "→ Clonando tpm en $TPM_DIR"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
  echo "✓ tpm instalado. Dentro de tmux: prefix + I para instalar plugins"
fi

# ─── tmux-claude-session-manager ──────────────────────────────
# Espejo de install.sh: el plugin lee estado vía `claude agents --json`
# (sin hooks), así que ya no hace falta pre-clonarlo — tpm lo clona con
# prefix+I como al resto.
#
# Migración: versiones viejas de este installer mergeaban 4 hooks
# (UserPromptSubmit/Notification/PreToolUse/Stop → scripts/state.sh) en
# ~/.claude/settings.json. El plugin borró state.sh, así que esos hooks
# ahora fallan (exit 127) en cada evento. Convergente: los limpiamos acá
# si están, en cualquier máquina que todavía los tenga.
SETTINGS="$HOME/.claude/settings.json"
if command -v jq >/dev/null 2>&1 && [[ -f "$SETTINGS" ]] \
   && jq -e '[.. | strings] | any(test("tmux-claude-session-manager/scripts/state.sh"))' "$SETTINGS" >/dev/null 2>&1; then
  SETTINGS_TMP="$(mktemp)"
  if jq '.hooks |= (to_entries
          | map(.value |= map(select(
              (.hooks // []) | any(.command? // "" | test("tmux-claude-session-manager/scripts/state.sh")) | not
            )))
          | map(select((.value | length) > 0))
          | from_entries)' "$SETTINGS" > "$SETTINGS_TMP"; then
    mv "$SETTINGS_TMP" "$SETTINGS"
    echo "✓ hooks obsoletos de claude-session-manager (state.sh) limpiados de settings.json"
  else
    rm -f "$SETTINGS_TMP"
    echo "⚠️  limpieza de hooks obsoletos falló — settings.json quedó intacto"
  fi
fi

# Si hay tmux server corriendo, recargá el config para aplicar los
# cambios en sesiones activas sin tener que entrar al server a
# mano. Si no hay server (típico en WSL2 fresh login), skip — la
# próxima sesión nueva ya leerá el config fresco. Guarda `tmux info`
# para no romper si tmux no está instalado todavía.
if command -v tmux >/dev/null 2>&1 && tmux info >/dev/null 2>&1; then
  # Sin 2>/dev/null: un error de sintaxis en el config debe ser visible,
  # no tragarse en silencio (`tmux info` ya garantiza que hay server).
  if tmux source-file "$HOME/.config/tmux/tmux.conf"; then
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

# eza — fallback si `command -v eza` falla tras apt (apt no lo traía —
# típico en Ubuntu < 23.10 — o el install falló por otra razón).
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
