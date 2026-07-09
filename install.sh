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
# Esto también expone la familia del "tema del stack" (scripts/theme): los
# themes nuevos en ghostty/themes, nvim/lua/themes y tmux/themes viajan
# gratis con los symlinks de dir padre — no hay que linkearlos uno por uno.
# El puntero de selección (themes/current) también viaja versionado dentro
# de ese dir, así que un `git pull` propaga el tema sin re-correr esto.
if [[ -d "$DOTFILES/ghostty/themes" ]]; then
  mkdir -p "$HOME/.config/ghostty"
  link "$DOTFILES/ghostty/themes"       "$HOME/.config/ghostty/themes"
fi
link "$DOTFILES/git/.gitignore_global"  "$HOME/.gitignore_global"
link "$DOTFILES/nvim"                   "$HOME/.config/nvim"
link "$DOTFILES/tmux"                   "$HOME/.config/tmux"
link "$DOTFILES/lazygit/config.yml"     "$HOME/.config/lazygit/config.yml"

# ─── tema del stack ───────────────────────────────────────────
# Nada que hacer acá. Tanto las DEFINICIONES de paleta como la SELECCIÓN
# activa (los punteros ghostty/themes/current, nvim/lua/theme-current,
# tmux/theme-current.conf) están versionadas y llegan con el clone/pull;
# los symlinks de dir de arriba las exponen sin trabajo extra. Cambiar el
# tema de TODAS las máquinas = `scripts/theme <id>` + commit + pull.

# Caps Lock → Option: System Settings → Keyboard → Keyboard Shortcuts →
# Modifier Keys → Caps Lock = Option ⌥. Es per-device y per-máquina, no
# versionable; por eso vive en UI y no en el repo. Karabiner-Elements quedó
# descartado por incompatibilidad con MacBook built-in + layout Latin American
# (swappeaba <> con |° porque su virtual HID solo soporta ansi/iso genéricos).

# ~/.gitconfig NO se symlinkea — cada máquina lo mantiene 100% propio
# (credenciales, 1Password vaults, signing keys son per-máquina).

# Claude Code: TODO per-máquina, no versionado. settings.json NO se symlinkea
# (es 100% propio de cada host, como ~/.gitconfig): permisos/UI divergen por
# máquina y arrastraba estado personal a un repo público. skills/ se symlinkea
# sólo si existe localmente, así cada máquina mantiene su propio ~/.claude/*
# sin interferencia.
#
# memory/ NO se symlinkea: Claude Code deriva el project-id del path REAL del
# directorio (ej. trabajando en ~/dotfiles usa ...projects/-Users-foo-dotfiles/
# memory), así que un symlink a un path adivinado quedaba ignorado. La memoria
# es per-proyecto y la maneja Claude Code solo.
if [[ -d "$DOTFILES/claude/skills" ]]; then
  link "$DOTFILES/claude/skills"        "$HOME/.claude/skills"
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

# ─── tmux-claude-session-manager + hooks de estado ────────────
# El plugin (picker prefix+u) lo declara tmux.conf y lo instalaría tpm con
# prefix+I, pero lo pre-clonamos acá para que scripts/state.sh exista ANTES de
# mergear los hooks — sino los hooks llamarían a un script inexistente (exit 127)
# hasta que corras prefix+I. Idempotente; tpm lo detecta ya clonado en su path.
CLAUDE_TMUX_DIR="$HOME/.config/tmux/plugins/tmux-claude-session-manager"
if [[ ! -d "$CLAUDE_TMUX_DIR" ]]; then
  echo "→ Clonando tmux-claude-session-manager en $CLAUDE_TMUX_DIR"
  git clone --depth 1 https://github.com/craftzdog/tmux-claude-session-manager "$CLAUDE_TMUX_DIR"
fi

# Los hooks de estado (working/waiting/idle) viven en ~/.claude/settings.json,
# que es per-máquina y NO se symlinkea (ver nota de Claude Code arriba). En vez
# de symlinkear, MERGEAMOS el fragmento versionado de forma aditiva e idempotente
# con jq: preserva el resto del settings.json y cualquier .hooks que ya tengas.
# Gated a que existan jq + state.sh + el fragmento.
SETTINGS="$HOME/.claude/settings.json"
HOOKS_FRAGMENT="$DOTFILES/claude/claude-session-hooks.json"
if command -v jq >/dev/null 2>&1 && [[ -f "$CLAUDE_TMUX_DIR/scripts/state.sh" && -f "$HOOKS_FRAGMENT" ]]; then
  mkdir -p "$(dirname "$SETTINGS")"
  [[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"
  if jq -e '[.. | strings] | any(test("tmux-claude-session-manager/scripts/state.sh"))' "$SETTINGS" >/dev/null 2>&1; then
    echo "✓ hooks claude-session-manager ya presentes en settings.json"
  else
    HOOKS_TMP="$(mktemp)"
    # Append por-evento (preserva .hooks existentes); escritura atómica tmp+mv
    # para no dejar el settings.json corrupto si jq falla a mitad.
    if jq --slurpfile frag "$HOOKS_FRAGMENT" '
          reduce ($frag[0].hooks | to_entries[]) as $e (.;
            .hooks[$e.key] = ((.hooks[$e.key] // []) + $e.value))
        ' "$SETTINGS" > "$HOOKS_TMP"; then
      mv "$HOOKS_TMP" "$SETTINGS"
      echo "✓ hooks claude-session-manager mergeados en settings.json (per-máquina)"
    else
      rm -f "$HOOKS_TMP"
      echo "⚠️  merge de hooks falló — settings.json quedó intacto"
    fi
  fi
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
    gomi                  # `rm` con papelera + restore interactivo (alias `gm`)
    zoxide
    fzf
    jq                    # merge idempotente de los hooks de claude-session-manager en settings.json
    git-delta
    pyenv
    neovim
    tree-sitter-cli       # parser generator que usa el branch `main` de nvim-treesitter
    tmux
    lazygit
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

echo ""
echo "✅ Done. Next steps:"
echo "   1. Si tu máquina tiene credenciales/env vars propias: crear ~/.zshenv.local"
echo "   2. Si tu máquina tiene aliases/funciones propias: crear ~/.zshrc.local"
echo "   3. Abrir un shell nuevo: exec zsh"
