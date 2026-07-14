# shellcheck shell=bash
# ─── Claude Code: binarios externos que se auto-registran ───
#
# Mecanismo 2 de 3 (ver claude/install/README.md). Instalamos el binario y
# corremos SU comando de setup — el binario escribe en ~/.claude/ (hooks,
# MCP server, skills) y maneja su propia idempotencia. Nosotros no tocamos
# settings.json acá; eso es mecanismo 1 (settings.sh).
#
# Sourceado por install.sh e install-linux.sh — NO ejecutable suelto.
# Va DESPUÉS de settings.sh: ese symlinkea ~/.claude/CLAUDE.md, y `rtk init`
# le agrega una línea @RTK.md — queremos que caiga sobre el archivo versionado.

# ─── rtk (proxy CLI que reduce tokens) ────────────────────────
# Agrega un hook PreToolUse (matcher Bash → "rtk hook claude") que reescribe
# comandos comunes (git status, cargo test, npm test...) a su equivalente rtk,
# con output filtrado/comprimido: menos tokens de contexto. También crea
# ~/.claude/RTK.md (referencia de comandos, per-máquina, no versionada).
#
# En mac el binario ya viene por Homebrew (REQUIRED_FORMULAE); en Linux no hay
# formula, así que cae al curl installer oficial. El guard `command -v` unifica
# los dos casos: si brew ya lo puso, el curl ni se intenta.
#
# `</dev/null` NO es cosmético: sin eso el comando se colgaba en una terminal
# real esperando un prompt interactivo invisible (probablemente el trust de
# filters.toml). --auto-patch solo evita el prompt de "¿parchear settings.json?",
# no ese otro. stdin cerrado → EOF → el comando sigue con su default.
# Doc: https://github.com/rtk-ai/rtk
if ! command -v rtk >/dev/null 2>&1; then
  echo ""
  echo "→ Instalando rtk (curl installer oficial)"
  curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh \
    || echo "⚠️  rtk install falló"
fi

if command -v rtk >/dev/null 2>&1; then
  # Idempotencia: la maneja el propio rtk (verificado corriéndolo dos veces —
  # la segunda detecta el hook existente y no lo duplica), no jq nuestro.
  if rtk init --global --auto-patch >/dev/null 2>&1 </dev/null; then
    echo "✓ rtk hook de Claude Code configurado (o ya estaba)"
  else
    echo "⚠️  rtk init --global falló — revisar a mano (rtk init --global -v)"
  fi
fi

# ─── codebase-memory-mcp (MCP server de grafo de código) ──────
# Indexa el codebase en un grafo persistente — 14 tools (search_graph,
# trace_path, get_architecture...), 158 lenguajes vía tree-sitter. Sin formula
# de Homebrew, así que va por el install.sh oficial del proyecto en las dos
# plataformas. Variante SIN --ui (headless, default del propio installer): el
# consumidor es el agente vía MCP tools, no un humano navegando el grafo 3D en
# localhost:9749 — así no abre un puerto HTTP local de más.
# Doc: https://github.com/DeusData/codebase-memory-mcp
#
# El binario pesa ~260MB: solo lo bajamos si falta.
if ! command -v codebase-memory-mcp >/dev/null 2>&1; then
  echo ""
  echo "→ Instalando codebase-memory-mcp"
  curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash \
    || echo "⚠️  codebase-memory-mcp install falló"
fi

# `install -y` corre SIEMPRE — sin guard, y eso es load-bearing. Es el comando
# que escribe TODO el estado en ~/.claude/: MCP server + hooks (PreToolUse en
# Grep/Glob, SessionStart, SubagentStart) para cada agente detectado, y la skill
# `codebase-memory` en ~/.claude/skills/. Si vive bajo el guard del binario (o
# sea, implícito dentro del curl de arriba), un ~/.claude borrado a mano no se
# reconstruye NUNCA: el binario sigue en PATH → guard en falso → cero re-registro,
# y ./install.sh parece correr bien. El estado del binario y el de ~/.claude son
# independientes. Si volvés a ver la skill `codebase-memory` desaparecida después
# de un install.sh, alguien re-metió esto adentro del `if`.
# Es idempotente (verificado con --dry-run: detecta config existente, no duplica).
if command -v codebase-memory-mcp >/dev/null 2>&1; then
  codebase-memory-mcp install -y >/dev/null 2>&1 \
    && echo "✓ codebase-memory-mcp: MCP server + hooks + skill registrados" \
    || echo "⚠️  codebase-memory-mcp install -y falló"
  # auto_index: barato e idempotente, se fuerza en cada corrida para que
  # proyectos nuevos se indexen solos al conectar.
  codebase-memory-mcp config set auto_index true >/dev/null 2>&1
  echo "✓ codebase-memory-mcp: auto_index=true"
fi

# ── limpieza convergente: la línea que el binario mete en ~/.zshrc ──
# El binario (src/cli/cli.c, cbm_detect_shell_rc) hace su propio
# fopen(~/.zshrc, "a") y agrega `export PATH=...` si no encuentra un match
# TEXTUAL exacto. Nuestro PATH vive en zsh/.zshenv con `$HOME` (no el path
# absoluto expandido), así que ese chequeo naive nunca lo reconoce y siempre
# re-agrega su línea, con el path de ESTA máquina hardcodeado. Como ~/.zshrc es
# symlink al repo, eso ensucia el archivo VERSIONADO — y como `install -y` corre
# en cada corrida, reaparece siempre. Va DESPUÉS del install -y: al revés, el
# binario re-ensuciaría el archivo y `git status` quedaría sucio tras cada run.
#
# Dos detalles que NO son cosméticos (los dos se rompían en silencio):
#  - El binario escribe TRES líneas: una EN BLANCO, el marker, y el export. Un
#    `skip = 2` desde el marker deja la vacía huérfana y el diff seguía con un `+`.
#    El awk difiere los blancos (pending) y los descarta si lo que sigue es el marker.
#  - Escribe con `cat >`, NUNCA con `mv`: ~/.zshrc es un SYMLINK al repo. `mv`
#    reemplaza el symlink por un archivo regular (rompe el dotfile Y deja la línea
#    sucia intacta en el repo — escribiste al lado, no adentro). La redirección
#    sigue el symlink y limpia el archivo real. Es la diferencia con settings.sh,
#    donde mktemp + mv sí es correcto porque settings.json es un archivo real.
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
    cat "$ZSHRC_TMP" > "$ZSHRC"
    rm -f "$ZSHRC_TMP"
    echo "✓ línea de PATH que codebase-memory-mcp agregó a .zshrc limpiada (ya cubierto por .zshenv)"
  else
    rm -f "$ZSHRC_TMP"
    echo "⚠️  no se pudo limpiar .zshrc — revisar a mano"
  fi
fi
