# shellcheck shell=bash
# ─── Claude Code: lo que escribimos NOSOTROS en settings.json ───
#
# Mecanismo 1 de 3 (ver claude/install/README.md). Acá vive TODO lo que
# este repo escribe a mano en ~/.claude/settings.json con jq — nada más.
# Los otros dos mecanismos (binarios que se auto-registran, plugins de
# marketplace) no tocan el archivo desde acá: lo escriben ellos.
#
# Sourceado por install.sh e install-linux.sh — NO ejecutable suelto:
# asume `link()`, `$DOTFILES` y `$TS` del installer padre, y que jq ya
# está instalado (los installers corren su bloque de deps antes).

SETTINGS="$HOME/.claude/settings.json"

# ── symlinks versionados (esto NO es settings.json, pero es su insumo) ──
# statusline.sh: script genérico, sin estado personal → se versiona.
# CLAUDE.md user-level: prosa, preferencias para TODOS los proyectos.
# El symlink de CLAUDE.md va ANTES de binaries.sh: `rtk init --global` le
# agrega una línea `@RTK.md` si falta, y queremos que esa escritura caiga
# sobre el archivo versionado (a través del symlink), no sobre uno suelto.
link "$DOTFILES/claude/statusline.sh" "$HOME/.claude/statusline.sh"
link "$DOTFILES/claude/CLAUDE.md"     "$HOME/.claude/CLAUDE.md"

# settings.json en sí NO se symlinkea: es 100% per-máquina (como
# ~/.gitconfig). Permisos/UI divergen por host y symlinkearlo a un repo
# público arrastraba estado personal (enabledPlugins, marketplaces).
# Lo que sigue son excepciones controladas: additive-only, con guard.
# Si la key ya existe en esta máquina, no se toca.

if ! command -v jq >/dev/null 2>&1; then
  echo "⚠️  jq no detectado — saltando config de settings.json"
  return 0 2>/dev/null || exit 0
fi

mkdir -p "$(dirname "$SETTINGS")"
[[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"

# Escritura atómica con guard. $1 = key a chequear (jq path), $2 = filtro
# jq a aplicar, $3 = nombre humano para los mensajes. settings.json es un
# archivo REAL (no symlink), así que mktemp + mv es correcto acá — a
# diferencia de la limpieza de ~/.zshrc en binaries.sh, que escribe con
# `cat >` justamente porque ahí sí hay un symlink de por medio.
_settings_set_if_absent() {
  local key="$1" filter="$2" label="$3" tmp
  if jq -e "$key" "$SETTINGS" >/dev/null 2>&1; then
    echo "✓ $label ya configurado en settings.json — no se toca"
    return 0
  fi
  tmp="$(mktemp)"
  if jq "$filter" "$SETTINGS" > "$tmp"; then
    mv "$tmp" "$SETTINGS"
    echo "✓ $label agregado a settings.json"
  else
    rm -f "$tmp"
    echo "⚠️  no se pudo agregar $label — settings.json quedó intacto"
  fi
}

# ── statusLine ──
# El script se versiona (arriba); su ACTIVACIÓN es per-máquina.
_settings_set_if_absent '.statusLine' \
  '.statusLine = {"type": "command", "command": "~/.claude/statusline.sh"}' \
  'statusLine'

# ── permissions.allow / deny ──
# Lista curada según la doc oficial (https://code.claude.com/docs/en/permissions):
# los comandos read-only de Bash (git status/diff/log, ls, cat, grep, find,
# pwd, head, tail, wc, which, stat, du, cd...) YA NO piden confirmación por
# default, así que no hace falta listarlos. El allow cubre lo que sigue
# generando fricción real: writes de git, build/test tooling (npm, cargo, go,
# make, gradle/kotlinc/ktlint) y los reemplazos modernos de esos read-only
# clásicos que Claude SÍ sigue confirmando por no estar en su lista interna
# (rg, fd, eza, bat, fzf, jq, tree, delta — todos instalados por estos mismos
# installers). El deny bloquea lo obviamente destructivo, y aplica incluso
# bajo bypassPermissions/auto — pero es best-effort: los patrones con wildcard
# no cubren variantes (`rm -fr`, `git push -f`). Para un bloqueo real, la vía
# documentada es un PreToolUse hook, no más strings.
_settings_set_if_absent '.permissions.allow' \
  '.permissions //= {} | .permissions.allow = [
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
  ]' \
  'permissions.allow'

_settings_set_if_absent '.permissions.deny' \
  '.permissions //= {} | .permissions.deny = [
    "Bash(rm -rf *)",
    "Bash(git push --force*)",
    "Bash(sudo *)"
  ]' \
  'permissions.deny'

# ── limpieza convergente: hooks obsoletos de tmux-claude-session-manager ──
# Hasta jul-2026 el plugin leía estado vía 4 hooks (UserPromptSubmit /
# Notification / PreToolUse / Stop → scripts/state.sh) que estos installers
# mergeaban acá. El plugin migró a `claude agents --json` (sin hooks) y borró
# state.sh upstream, así que esos hooks ahora fallan (exit 127) en cada evento.
# Los sacamos si están, sin tocar el resto de .hooks. Bloque TEMPORAL: una vez
# que todas las máquinas corrieron esta versión del installer, se puede borrar.
if jq -e '[.. | strings] | any(test("tmux-claude-session-manager/scripts/state.sh"))' "$SETTINGS" >/dev/null 2>&1; then
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
