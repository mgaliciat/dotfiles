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

# ─── status line de Claude Code ───────────────────────────────
# El script (claude/statusline.sh) es genérico — sin estado personal —
# así que SÍ se versiona y symlinkea, a diferencia de settings.json.
# Muestra modelo, directorio, git branch y una barra de uso de contexto
# coloreada (verde/amarillo/rojo).
link "$DOTFILES/claude/statusline.sh" "$HOME/.claude/statusline.sh"

# ─── CLAUDE.md user-level de Claude Code ──────────────────────
# claude/CLAUDE.md son preferencias que aplican a TODOS los proyectos
# (no solo este repo) — a diferencia de settings.json, es prosa sin
# estado sensible per-máquina, así que SÍ se versiona y symlinkea. Va
# ANTES de la sección de rtk más abajo: rtk init --global le agrega una
# línea `@RTK.md` si falta — queremos que esa escritura caiga sobre el
# archivo versionado (a través del symlink), no sobre un archivo suelto.
link "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# La activación (campo "statusLine" en settings.json) SÍ es per-máquina:
# solo la agregamos si no existe ya, para no pisar una config propia que
# hayas armado a mano en esa máquina. Si ya está — sea esta u otra — no
# tocamos nada.
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

# ─── permisos base de Claude Code ─────────────────────────────
# Igual que statusLine: excepción controlada, additive-only. Solo agrega
# permissions.allow/deny si esas keys NO existen ya en settings.json — si
# armaste tu propia lista a mano en esta máquina, no se toca. Lista curada
# a partir de la doc oficial (https://code.claude.com/docs/en/permissions)
# y best practices de la comunidad: comandos read-only de Bash reconocidos
# por Claude Code (git status/diff/log, ls, cat, grep, find, pwd, head,
# tail, wc, which, diff, stat, du, cd...) YA NO piden confirmación por
# default, así que no hace falta listarlos acá. El allow cubre lo que sigue
# generando fricción real: writes de git, build/test tooling (npm, cargo,
# go, make, gradle/kotlinc/ktlint) y reemplazos modernos de esos read-only
# clásicos que Claude SÍ sigue confirmando por no estar en esa lista interna
# (rg, fd, eza, bat, fzf, jq, tree, delta — todo Homebrew formulae de este
# mismo repo, ver REQUIRED_FORMULAE más abajo). El deny bloquea lo
# obviamente destructivo incluso bajo bypassPermissions/auto.
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
# Instala el hook PreToolUse (matcher Bash -> "rtk hook claude") que
# reescribe comandos comunes (git status, cargo test, etc.) a su
# equivalente rtk con output comprimido, reduciendo tokens de contexto.
# A diferencia de los bloques statusLine/permissions de arriba, acá NO
# manejamos la idempotencia con jq propio: `rtk init --global --auto-patch`
# ya detecta si el hook está y no lo duplica (verificado corriéndolo dos
# veces seguidas), así que alcanza con invocarlo en cada run. También crea
# ~/.claude/RTK.md (referencia de comandos) y agrega una línea @RTK.md a
# ~/.claude/CLAUDE.md — el CLAUDE.md GLOBAL de Claude Code, no este repo.
# Doc: https://github.com/rtk-ai/rtk
if command -v rtk >/dev/null 2>&1; then
  if rtk init --global --auto-patch >/dev/null 2>&1 </dev/null; then
    echo "✓ rtk hook de Claude Code configurado (o ya estaba)"
  else
    echo "⚠️  rtk init --global falló — revisar a mano (rtk init --global -v)"
  fi
fi

# ─── codebase-memory-mcp (MCP server de grafo de código) ──────
# Servidor MCP que indexa el codebase en un grafo de conocimiento
# persistente — 14 tools (search_graph, trace_path, get_architecture,
# search_code, etc.), 158 lenguajes vía tree-sitter. Sin binario en
# Homebrew todavía, así que usamos el install.sh oficial del proyecto
# (curl | bash), igual que hacemos con tpm vía git clone de un repo
# externo. Sin flag --global como rtk: acá `install -y` YA registra el
# MCP server + hooks a nivel de agente (~/.claude/.mcp.json,
# ~/.claude.json) para TODOS los proyectos por default — no hay modo
# per-proyecto que elegir. Variante SIN --ui (headless, default del
# propio installer): el consumidor acá es el agente vía MCP tools, no
# un humano navegando el grafo 3D en localhost:9749 — mantiene el
# binario liviano y no abre un puerto HTTP local sin necesidad. Instala
# solo si falta el binario (~260MB, no hace falta re-descargar en cada
# corrida); `install -y` del propio script ya es idempotente (detecta
# agentes, no duplica hooks/MCP entries — verificado con --dry-run).
# auto_index=true SIEMPRE se fuerza (barato, idempotente) para que
# proyectos nuevos se indexen solos al conectar. Doc:
# https://github.com/DeusData/codebase-memory-mcp
if ! command -v codebase-memory-mcp >/dev/null 2>&1; then
  echo ""
  echo "→ Instalando codebase-memory-mcp"
  curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash
fi

# `install -y` corre SIEMPRE, no solo cuando bajamos el binario: es lo que
# registra el MCP server + hooks + la skill `codebase-memory` en ~/.claude/.
# Si vivía solo dentro del curl de arriba, un ~/.claude borrado a mano no se
# reconstruía nunca (el binario seguía presente → guard en falso → cero
# reinstall). Es idempotente (verificado con --dry-run: detecta config
# existente y no duplica), así que re-correrlo es barato.
if command -v codebase-memory-mcp >/dev/null 2>&1; then
  codebase-memory-mcp install -y >/dev/null 2>&1 \
    && echo "✓ codebase-memory-mcp: MCP server + hooks + skill registrados" \
    || echo "⚠️  codebase-memory-mcp install -y falló"
  codebase-memory-mcp config set auto_index true >/dev/null 2>&1
  echo "✓ codebase-memory-mcp: auto_index=true"
fi

# Limpieza convergente: el binario (no el curl installer de arriba) hace
# su propio fopen(~/.zshrc, "a") y agrega `export PATH=...` si no
# encuentra un match TEXTUAL exacto en el archivo (src/cli/cli.c,
# cbm_detect_shell_rc). Nuestro PATH vive en zsh/.zshenv con `$HOME`
# (no el path absoluto expandido), así que ese chequeo naive nunca lo
# reconoce y siempre re-agrega su línea — con el path de ESTA máquina
# hardcodeado. Como ~/.zshrc es symlink a este repo, eso ensucia el
# archivo versionado — y como `install -y` corre en CADA corrida (ver
# arriba), reaparece siempre, no solo en una máquina nueva. Va DESPUÉS
# del install -y: al revés, el binario re-ensuciaría el archivo y
# `git status` quedaría sucio tras cada ./install.sh.
#
# El binario escribe 3 líneas: una EN BLANCO, el marker, y el export.
# El awk difiere los blancos (pending) y los descarta si lo que sigue es
# el marker — sin eso quedaba un `+` de línea vacía en el diff del repo.
ZSHRC="$HOME/.zshrc"
if [[ -f "$ZSHRC" ]] && grep -qF "# Added by codebase-memory-mcp install" "$ZSHRC"; then
  ZSHRC_TMP="$(mktemp)"
  if awk '
    /^# Added by codebase-memory-mcp install$/ { skip = 2; pending = 0; next }
    skip > 0 { skip--; next }
    /^$/ { pending++; next }
    { while (pending-- > 0) print ""; pending = 0; print }
    END { while (pending-- > 0) print "" }
  ' "$ZSHRC" > "$ZSHRC_TMP"; then
    # `cat >` y NO `mv`: ~/.zshrc es un SYMLINK al repo. `mv` reemplaza el
    # symlink por un archivo regular (rompe el dotfile y deja la línea sucia
    # en el repo); la redirección escribe A TRAVÉS del symlink, que es lo que
    # queremos — limpiar el archivo versionado.
    cat "$ZSHRC_TMP" > "$ZSHRC"
    rm -f "$ZSHRC_TMP"
    echo "✓ línea de PATH que codebase-memory-mcp agregó a .zshrc limpiada (ya cubierto por .zshenv)"
  else
    rm -f "$ZSHRC_TMP"
    echo "⚠️  no se pudo limpiar .zshrc — revisar a mano"
  fi
fi

# ─── ponytail (plugin de Claude Code — "lazy senior dev" skill) ──
# A diferencia de rtk/codebase-memory-mcp, este NO es un binario — es un
# plugin real de marketplace (DietrichGebert/ponytail). Se instala 100%
# con la CLI de plugins de Claude Code, que ya es idempotente por sí
# misma (verificado corriendo ambos comandos dos veces seguidas: la
# segunda detecta "already on disk" / "already installed" y no falla ni
# duplica), así que alcanza con invocarla en cada corrida. Un solo
# `install` trae el plugin Y sus 6 skills bundled (ponytail,
# ponytail-review, ponytail-audit, ponytail-debt, ponytail-gain,
# ponytail-help) — no hay paso separado para las skills. Requiere `node`
# en PATH (hooks del plugin son Node.js) — si falta, el plugin igual
# instala pero la activación automática queda muda en vez de tirar error
# en cada prompt (comportamiento documentado por el propio proyecto, no
# lo forzamos acá). Scope `-s user`: activo en todos los proyectos, no
# solo este repo. URL https:// completa, NO el shorthand `owner/repo`:
# el shorthand clona por SSH (`git@github.com:...`) — en una máquina
# fresca sin llave SSH registrada en GitHub esto falla; la URL https
# clona por HTTPS y no requiere auth para un repo público (verificado:
# `marketplace add owner/repo` mostró "Cloning via SSH", `marketplace add
# https://...` mostró "Cloning repository: https://..."). Doc:
# https://github.com/DietrichGebert/ponytail
if command -v claude >/dev/null 2>&1; then
  if ! command -v node >/dev/null 2>&1; then
    echo "ℹ️  node no detectado — ponytail se instala igual, pero sus hooks de activación automática van a quedar mudos hasta que node esté en PATH"
  fi

  if claude plugin marketplace add https://github.com/DietrichGebert/ponytail >/dev/null 2>&1 </dev/null; then
    echo "✓ ponytail marketplace agregado (o ya estaba)"
  else
    echo "⚠️  no se pudo agregar el marketplace de ponytail — revisar a mano"
  fi

  if claude plugin install ponytail@ponytail -s user >/dev/null 2>&1 </dev/null; then
    echo "✓ ponytail plugin + skills instalados (o ya estaba)"
  else
    echo "⚠️  no se pudo instalar ponytail — revisar a mano (claude plugin install ponytail@ponytail)"
  fi
fi

# ─── andrej-karpathy-skills (plugin de Claude Code — guidelines) ──
# Mismo mecanismo que ponytail (plugin de marketplace, no binario) —
# multica-ai/andrej-karpathy-skills. Guidelines de comportamiento
# (pensar antes de codear, simplicidad, cambios quirúrgicos, ejecución
# goal-driven con tests) — más liviano que ponytail: 1 skill, sin hooks,
# sin dependencia de node (~103 tokens always-on vs ~983 de ponytail).
# Overlap intencional con ponytail en "no sobre-construyas" — distinto
# énfasis (esto es sobre proceso/comunicación, ponytail sobre líneas de
# código) y el costo extra es marginal. Nombre marketplace/plugin
# (`karpathy-skills` / `andrej-karpathy-skills`) sacado directo de
# .claude-plugin/marketplace.json del repo — el README todavía linkea al
# nombre viejo del repo (forrestchang/...) de antes de que lo transfirieran
# a multica-ai; usamos el nombre actual. Idempotente (mismo patrón que
# ponytail, verificado corriendo ambos comandos dos veces seguidas). URL
# https:// completa, no shorthand — mismo motivo que ponytail (shorthand
# clona por SSH, falla en máquina fresca sin llave GitHub).
# Doc: https://github.com/multica-ai/andrej-karpathy-skills
if command -v claude >/dev/null 2>&1; then
  if claude plugin marketplace add https://github.com/multica-ai/andrej-karpathy-skills >/dev/null 2>&1 </dev/null; then
    echo "✓ andrej-karpathy-skills marketplace agregado (o ya estaba)"
  else
    echo "⚠️  no se pudo agregar el marketplace de andrej-karpathy-skills — revisar a mano"
  fi

  if claude plugin install andrej-karpathy-skills@karpathy-skills -s user >/dev/null 2>&1 </dev/null; then
    echo "✓ andrej-karpathy-skills plugin instalado (o ya estaba)"
  else
    echo "⚠️  no se pudo instalar andrej-karpathy-skills — revisar a mano (claude plugin install andrej-karpathy-skills@karpathy-skills)"
  fi
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

# ─── tmux-claude-session-manager ──────────────────────────────
# Picker de sesiones Claude (prefix+u / Alt+u), declarado como @plugin en
# tmux.conf — tpm lo clona con prefix+I como al resto. Desde que el plugin
# pasó a leer estado vía `claude agents --json` (sin hooks), ya no hace falta
# pre-clonarlo acá.
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
