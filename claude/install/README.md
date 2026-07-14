# claude/install/ — cómo se configura Claude Code

Todo lo que este repo le hace a `~/.claude/` vive acá, partido por **quién escribe
en `settings.json`**. Esa es la línea divisoria — no "qué instala", sino quién es el
autor de la escritura, porque de eso depende quién maneja la idempotencia y dónde
buscar cuando algo se rompe.

Los tres archivos se **sourcean** desde los installers de bash (`install.sh`,
`install-linux.sh` — los dos sourcean los tres); no son ejecutables sueltos. Asumen
`link()`, `$DOTFILES` y `$TS` del padre, y que `jq` ya está instalado (los installers
corren su bloque de deps antes).

| | Archivo | Quién escribe en `settings.json` | Idempotencia |
|---|---|---|---|
| **1** | `settings.sh` | **Nosotros**, con `jq` | Guard nuestro: solo si la key no existe |
| **2** | `binaries.sh` | El **binario externo**, en su comando de setup | La maneja el binario |
| **3** | `plugins.sh` | La **CLI de Claude Code** (`claude plugin`) | La maneja la CLI |

**1 — `settings.sh`.** Lo único que escribimos a mano: `statusLine`, `permissions.allow/deny`,
y la limpieza convergente de los hooks obsoletos de `tmux-claude-session-manager`. Additive-only,
con guard: si la key ya existe en esa máquina, no se toca. También symlinkea las dos piezas
versionadas de `claude/` (`statusline.sh`, `CLAUDE.md` user-level).

**2 — `binaries.sh`.** Instalás el binario (brew / curl) y corrés *su* comando de setup, que es
el que escribe hooks, MCP servers y skills en `~/.claude/`. Hoy: `rtk` (hook `PreToolUse` que
comprime output de Bash) y `codebase-memory-mcp` (MCP server + hooks + la skill `codebase-memory`).

**3 — `plugins.sh`.** Un `marketplace add` + un `install` y la CLI hace el resto (incluido
escribir `extraKnownMarketplaces` / `enabledPlugins`). Es el camino más barato para agregar
skills o hooks nuevos. Hoy: `ponytail` (6 skills bundled) y `andrej-karpathy-skills`.
Cuidado en el port de Windows: el bloque de plugins tiene que ir **después** de que el script
escriba su `settings.json`, o le pisás lo que la CLI acaba de poner ahí.

## Para agregar algo nuevo

Existe como plugin de marketplace → mecanismo 3, dos líneas en `plugins.sh`.
Es un binario o MCP suelto → mecanismo 2. Mecanismo 1 solo cuando no hay nadie más
que lo escriba.

## Orden

`settings.sh` → `binaries.sh` → `plugins.sh`, y es load-bearing: `settings.sh` symlinkea
`~/.claude/CLAUDE.md`, y `rtk init` (en `binaries.sh`) le agrega una línea `@RTK.md` — queremos
que esa escritura caiga sobre el archivo versionado a través del symlink, no sobre uno suelto.

## Qué NO está acá

`settings.json` mismo (per-máquina, no versionado — ver `CLAUDE.md` del repo),
`~/.claude/skills/` (per-máquina, dir real), `~/.claude/projects/*/memory/` (la maneja
Claude Code sola).

`install-windows.ps1` **no** puede sourcear estos scripts (PowerShell), así que replica los
tres mecanismos a mano. Si cambiás algo acá, chequeá si aplica allá — es la única copia que
queda, y no hay nada que la mantenga en sync automáticamente.
