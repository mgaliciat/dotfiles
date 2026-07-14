# shellcheck shell=bash
# ─── Claude Code: plugins de marketplace ───
#
# Mecanismo 3 de 3 (ver claude/install/README.md). Nada de binarios ni de jq:
# la CLI de Claude Code hace todo el trabajo (clona el marketplace, instala el
# plugin, escribe extraKnownMarketplaces + enabledPlugins en settings.json).
# Es el camino más barato para agregar skills/hooks nuevos — dos líneas.
#
# Sourceado por install.sh — NO ejecutable suelto.
# `claude plugin` es la misma CLI cross-platform, así que sourcearlo desde
# install-linux.sh / install-windows.ps1 sería mecánico si hace falta.

# $1 = URL del marketplace, $2 = plugin@marketplace, $3 = nombre humano.
#
# URL https:// COMPLETA, nunca el shorthand `owner/repo`: el shorthand clona por
# SSH (git@github.com:...) y falla en una máquina fresca sin llave SSH registrada
# en GitHub (verificado comparando el log de clone de ambas formas).
#
# `</dev/null` en los dos comandos: corriendo install.sh en una terminal real uno
# de ellos quedó colgado esperando un prompt interactivo invisible. stdin cerrado
# → EOF → el comando sigue con su default (mismo fix que rtk en binaries.sh).
#
# Idempotencia: la maneja la propia CLI (verificado corriendo ambos comandos dos
# veces seguidas — la segunda detecta "already on disk" / "already installed", no
# falla ni duplica), así que los invocamos en cada corrida sin guard.
_claude_plugin_install() {
  local url="$1" plugin="$2" label="$3"

  if claude plugin marketplace add "$url" >/dev/null 2>&1 </dev/null; then
    echo "✓ $label: marketplace agregado (o ya estaba)"
  else
    echo "⚠️  no se pudo agregar el marketplace de $label — revisar a mano"
  fi

  # Scope `-s user`: activo en TODOS los proyectos, no solo este repo.
  if claude plugin install "$plugin" -s user >/dev/null 2>&1 </dev/null; then
    echo "✓ $label: plugin instalado (o ya estaba)"
  else
    echo "⚠️  no se pudo instalar $label — revisar a mano (claude plugin install $plugin)"
  fi
}

if ! command -v claude >/dev/null 2>&1; then
  echo "ℹ️  claude no detectado en PATH — saltando plugins"
  return 0 2>/dev/null || exit 0
fi

# ── ponytail — "lazy senior dev" ──
# Un solo `install` trae el plugin Y sus 6 skills bundled (ponytail,
# ponytail-review, ponytail-audit, ponytail-debt, ponytail-gain, ponytail-help)
# — no hay paso separado para las skills. Queda activo en TODAS las sesiones
# (ruleset inyectado siempre): `/ponytail off` lo apaga por sesión,
# PONYTAIL_DEFAULT_MODE=off por default. ~983 tokens always-on.
# Doc: https://github.com/DietrichGebert/ponytail
if ! command -v node >/dev/null 2>&1; then
  # Los hooks del plugin son Node.js. Sin node instala igual, pero la activación
  # automática queda muda en vez de tirar error en cada prompt (comportamiento
  # documentado por el proyecto). No lo forzamos como dependencia dura.
  echo "ℹ️  node no detectado — ponytail se instala igual, pero sus hooks de activación automática van a quedar mudos hasta que node esté en PATH"
fi
_claude_plugin_install \
  "https://github.com/DietrichGebert/ponytail" \
  "ponytail@ponytail" \
  "ponytail"

# ── andrej-karpathy-skills — guidelines de comportamiento ──
# Pensar antes de codear, simplicidad, cambios quirúrgicos, ejecución goal-driven
# con tests. Más liviano que ponytail: 1 skill, sin hooks, sin node (~103 tokens).
# Overlap intencional con ponytail en "no sobre-construyas" — distinto énfasis
# (proceso/comunicación vs. líneas de código concretas) y el costo extra de tener
# los dos activos es marginal.
#
# Los nombres marketplace/plugin salen de .claude-plugin/marketplace.json del repo,
# NO del README: el README todavía apunta a forrestchang/andrej-karpathy-skills, el
# nombre de antes de transferirlo a multica-ai (GitHub redirige, pero usamos el actual).
# Doc: https://github.com/multica-ai/andrej-karpathy-skills
_claude_plugin_install \
  "https://github.com/multica-ai/andrej-karpathy-skills" \
  "andrej-karpathy-skills@karpathy-skills" \
  "andrej-karpathy-skills"
