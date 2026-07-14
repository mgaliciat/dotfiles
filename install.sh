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
# Themes custom (sampling de wallpapers, paletas propias). OJO: Ghostty
# busca themes en ~/.config/ghostty/themes/ (path XDG), NO en el mismo
# Application Support donde vive el config — son dirs distintos. Si los
# pones en Application Support, Ghostty los ignora y tira "theme not found".
# Symlink del dir entero para que nuevos themes se expongan automáticamente.
# Esto también expone la familia del "tema del stack": los themes nuevos
# en ghostty/themes, nvim/lua/themes y tmux/themes viajan gratis con los
# symlinks de dir padre — no hay que linkearlos uno por uno.
if [[ -d "$DOTFILES/ghostty/themes" ]]; then
  mkdir -p "$HOME/.config/ghostty"
  link "$DOTFILES/ghostty/themes"       "$HOME/.config/ghostty/themes"
fi
link "$DOTFILES/git/.gitignore_global"  "$HOME/.gitignore_global"
link "$DOTFILES/nvim"                   "$HOME/.config/nvim"
link "$DOTFILES/tmux"                   "$HOME/.config/tmux"
link "$DOTFILES/lazygit/config.yml"     "$HOME/.config/lazygit/config.yml"

# ─── tema del stack ───────────────────────────────────────────
# Nada que hacer acá. La selección del tema es un valor directo en cada
# config versionado (Ghostty `theme =`, nvim `vim.g.theme`, el `source`
# de paleta en tmux.conf) y llega con el clone/pull; los symlinks de dir
# de arriba exponen las paletas sin trabajo extra. Cambiar el tema de
# TODAS las máquinas = editar esas 3 líneas + commit + pull.

# Caps Lock → Option: System Settings → Keyboard → Keyboard Shortcuts →
# Modifier Keys → Caps Lock = Option ⌥. Es per-device y per-máquina, no
# versionable; por eso vive en UI y no en el repo. Karabiner-Elements quedó
# descartado por incompatibilidad con MacBook built-in + layout Latin American
# (swappeaba <> con |° porque su virtual HID solo soporta ansi/iso genéricos).

# ~/.gitconfig NO se symlinkea — cada máquina lo mantiene 100% propio
# (credenciales, 1Password vaults, signing keys son per-máquina).

# Claude Code: TODO per-máquina, no versionado. settings.json NO se symlinkea
# (es 100% propio de cada host, como ~/.gitconfig): permisos/UI divergen por
# máquina y arrastraba estado personal a un repo público.
#
# skills/ tampoco se symlinkea (desde jul-2026). ~/.claude/skills es el path
# REAL donde Claude Code lee las skills del usuario, así que el symlink sí
# funcionaba — pero apuntaba al repo, y su contenido (skill `learned` que
# escribe Claude, `codebase-memory` que reescribe el binario en cada install)
# es 100% per-máquina: nunca se versionó, vivía gitignoreado. Cero beneficio,
# y un `git add -f` o un .gitignore aflojado filtraba estado personal a un
# repo público. Hoy es un dir real; el binario codebase-memory-mcp lo crea si
# no existe.
#
# memory/ NO se symlinkea, por un motivo DISTINTO: Claude Code deriva el
# project-id del path REAL del directorio (ej. trabajando en ~/dotfiles usa
# ...projects/-Users-foo-dotfiles/memory), así que ahí el symlink apuntaba al
# path equivocado y quedaba ignorado. La memoria es per-proyecto y la maneja
# Claude Code solo.

# ─── dependencias (Homebrew) ──────────────────────────────────
# Auto-instala lo que falte. Idempotente: re-runs detectan instalados y skipean.
# Si no hay brew, muestra cómo instalarlo y termina sin fallar el script.
# Va ANTES de los bloques de settings.json de más abajo: esos usan jq
# (instalado acá) — si corrieran primero, en una máquina fresca se
# skipearían en silencio y recién aplicarían en la segunda corrida.
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
    gomi                  # `rm` con papelera + restore interactivo (alias `gm`)
    zoxide
    fzf
    jq                    # requerido por tmux-claude-session-manager (parsea `claude agents --json`)
    git-delta
    pyenv
    neovim
    tree-sitter-cli       # parser generator que usa el branch `main` de nvim-treesitter
    tmux
    lazygit
    rtk                   # proxy CLI que reduce tokens en Claude Code — ver sección rtk más abajo
  )
  REQUIRED_CASKS=(
    ghostty
    # Fonts referenciadas por ghostty/config.ghostty.
    # PlemolJP Console NF = primary (estilo craftzdog, bilingüe JP/EN
    # con Nerd Font integrado). iA Writer Mono y Monaspace quedan como
    # fallback chain. Ioskeley salió porque PlemolJP NF ya trae íconos.
    font-plemol-jp-nf
    font-ia-writer-mono
    font-monaspace
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

# ─── Claude Code ──────────────────────────────────────────────
# Tres mecanismos, uno por archivo, partidos por QUIÉN escribe en
# settings.json: nosotros con jq (settings.sh), el binario externo en su
# propio comando de setup (binaries.sh), o la CLI de plugins (plugins.sh).
# El detalle completo — y qué mecanismo usar para agregar algo nuevo —
# está en claude/install/README.md.
#
# El orden es load-bearing: settings.sh symlinkea ~/.claude/CLAUDE.md, y
# `rtk init` (binaries.sh) le agrega una línea @RTK.md — queremos que caiga
# sobre el archivo versionado a través del symlink, no sobre uno suelto.
# Van DESPUÉS del bloque de Homebrew: settings.sh necesita jq.
source "$DOTFILES/claude/install/settings.sh"
source "$DOTFILES/claude/install/binaries.sh"
source "$DOTFILES/claude/install/plugins.sh"

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

# Si hay tmux server corriendo, recargá el config para aplicar los
# cambios en sesiones activas sin tener que entrar al server a
# mano. Si no hay server, skip — la próxima sesión nueva ya leerá
# el config fresco. Guarda `tmux info` para no romper si tmux no
# está instalado todavía (primera corrida en máquina nueva).
if command -v tmux >/dev/null 2>&1 && tmux info >/dev/null 2>&1; then
  # Sin 2>/dev/null: si el config tiene un error de sintaxis queremos verlo,
  # no tragarlo en silencio (el `tmux info` ya garantiza que hay server).
  if tmux source-file "$HOME/.config/tmux/tmux.conf"; then
    echo "✓ tmux config recargado en sesiones activas"
  fi
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
echo "   1. Si tu máquina tiene credenciales/env vars propias: crear ~/.zshenv.local"
echo "   2. Si tu máquina tiene aliases/funciones propias: crear ~/.zshrc.local"
echo "   3. Abrir un shell nuevo: exec zsh"
