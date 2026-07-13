# CLAUDE.md (user-level)

Preferencias que aplican a **todos** los proyectos, no solo a este repo de dotfiles — a diferencia de un `CLAUDE.md` de proyecto puntual, esto viaja con vos a cualquier máquina/repo. Versionado y symlinkeado por `install.sh` a `~/.claude/CLAUDE.md`, mismo trato que `claude/statusline.sh` (ver `CLAUDE.md` de este repo, sección "per-máquina split").

@RTK.md

## Herramientas que instala este dotfiles

### rtk — github.com/rtk-ai/rtk

Proxy CLI que reescribe comandos Bash comunes (`git status`, `cargo test`, `npm test`, etc.) a su equivalente `rtk`, con output filtrado/comprimido para ahorrar tokens de contexto. **No requiere acción tuya** — el hook `PreToolUse` (`rtk hook claude`) lo hace transparente en cada llamada Bash. Referencia de comandos meta en `@RTK.md` (arriba) — p.ej. `rtk gain` para ver el ahorro acumulado.

### codebase-memory-mcp — github.com/DeusData/codebase-memory-mcp

Servidor MCP que indexa el código de cada proyecto en un grafo de conocimiento persistente. **Preferí sus tools por sobre Grep/Glob/Read crudo** para cualquier exploración estructural de código:

- `search_graph` / `search_code` en vez de grep para encontrar funciones, clases, rutas
- `trace_path` para call chains (quién llama a qué, data flow, cross-service)
- `get_code_snippet` para leer una función/clase puntual sin abrir el archivo entero
- `get_architecture` para overview de un proyecto (lenguajes, entry points, hotspots, capas, clusters)
- `query_graph` para patrones Cypher complejos (dead code, alta complejidad, etc.)
- `list_projects` para ver qué proyectos ya están indexados (con su `root_path` absoluto) y consultarlos sin estar parado en esa carpeta
- Si un proyecto no está indexado todavía, corré `index_repository` primero

Grep/Glob/Read siguen sirviendo para texto plano, configs, y archivos no-código.

También instala la skill `codebase-memory` (se activa sola con triggers tipo "explore the codebase", "who calls this function", "dead code", etc. — no hace falta invocarla a mano). Trae decision matrix, workflows de exploración/tracing, y ejemplos de Cypher para `query_graph` — más detalle que esta lista. Usala cuando el trigger aplique.
