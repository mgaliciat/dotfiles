# tmux cheatsheet

Comandos relevantes para **esta config**. `prefix` = `Ctrl+t`.

Convención: `prefix x` = presionás `Ctrl+t`, soltás, después `x`.

---

## ⭐ Lo más importante (los popups — chord único sin prefix)

| Atajo | Acción |
|---|---|
| `Alt+c` | **Claude Code en popup 90%** — sesión "default" persistente por proyecto |
| `Alt+C` | **Claude YOLO** — igual que `Alt+c` pero con `--dangerously-skip-permissions` (sesión separada) ⚠️ |
| `Alt+u` | **Picker central de sesiones Claude** (plugin session-manager) — TODAS las sesiones, estado live working/waiting/idle + preview |
| `Alt+y` | **Launcher Claude por directorio** (plugin session-manager) |
| `Alt+d` | **Cerrar popup Claude** (detach seguro — solo si estás dentro de sesión `claude*`) |
| `Alt+g` | **lazygit en popup 90%** — git UI flotante en el cwd |
| `Alt+Enter` | Shell rápida en popup 90% — para comandos one-off sin ocupar pane |
| `prefix b` | **Toggle statusline** on/off (default: OFF, sin distracción) |

**Cuándo usar `Alt+C` (YOLO) vs `Alt+c` (normal):**
- `Alt+c` → workflow diario. Claude pide confirmación antes de cada bash/edit. Más seguro.
- `Alt+C` → refactors masivos, exploración rápida, repos sandbox. Claude ejecuta todo sin preguntar. **Solo en repos versionados o que podés tirar.**
- Las sesiones son distintas (`claude-<hash>` vs `claude-yolo-<hash>`) → no se mezcla el contexto.

**Cuándo usar `Alt+u`/`Alt+y` (plugin) vs `Alt+c`/`Alt+C`:**
- `Alt+c`/`Alt+C` → te dan la sesión "default" del proyecto. Una sola.
- `Alt+u` → picker central: lista TODAS las sesiones Claude del server (de todos los proyectos) con estado live (working/waiting/idle, vía `claude agents --json`) y preview. Reemplazó al viejo selector `Alt+s`.
- `Alt+y` → launcher por directorio del plugin. Para un mismo dir resuelve a la **misma** sesión `claude-<hash>` que `Alt+c` (mismo algoritmo md5) — se comparten, no se duplican.

**Cómo funciona el popup de Claude:**
1. `cd ~/proyectos/foo` → `Alt+c` → se crea sesión `claude-<md5>` con Claude corriendo.
2. Cerrás el popup con `Alt+d` (detach) → Claude sigue vivo en background.
3. Volvés más tarde a `~/proyectos/foo` → `Alt+c` → reattacheás la **misma** sesión con todo el contexto.
4. Cambias a `~/proyectos/bar` → `Alt+c` → sesión DISTINTA (diferente md5).
5. ¿Perdiste el hilo de qué Claude anda dónde? → `Alt+u` → picker con estado live de todas.

**Convención de nombres de sesión:**
- `claude-<hash>` → la default que abren `Alt+c` / `Alt+y` (comparten hash)
- `claude-yolo-<hash>` → la default YOLO que abre `Alt+C`

Para listar sesiones de Claude activas: `tmux ls | grep claude` (o `Alt+u`).
Para matar una sesión específica: `tmux kill-session -t claude-<hash>`.

---

## Sesiones (persistencia — la razón principal de tmux)

| Atajo / Comando | Acción |
|---|---|
| `tmux new -s nombre` | Crear sesión con nombre |
| `tmux ls` | Listar sesiones activas |
| `tmux a` o `tmux attach` | Attachear a la última sesión |
| `tmux a -t nombre` | Attachear a sesión específica |
| `prefix d` | **Detach** — salís de tmux, la sesión sigue viva |
| `prefix s` | Selector de sesiones (con preview) |
| `prefix $` | Renombrar sesión actual |
| `tmux kill-session -t nombre` | Matar una sesión |
| `tmux kill-server` | Matar TODO tmux (cuidado) |

**Workflow típico:**
1. `tmux new -s laburo` → empezás a trabajar.
2. Cerrás Ghostty (sin querer o intencional) → la sesión persiste.
3. Abrís Ghostty de nuevo → `tmux a -t laburo` → todo como estaba.
4. Reboot completo → `tmux-resurrect` restaura panes + comandos (auto via `tmux-continuum`).

---

## Windows (tabs dentro de la sesión)

| Atajo | Acción |
|---|---|
| `prefix c` | Crear nueva window |
| `prefix ,` | Renombrar window actual |
| `prefix &` | Cerrar window (pide confirmación) |
| `prefix n` / `prefix p` | Siguiente / anterior window |
| `prefix <num>` | Ir a window N (`prefix 1`, `prefix 2`, ...) |
| `prefix w` | Selector de windows con preview |
| `C-S-Left` / `C-S-Right` | Mover window en orden (sin prefix, instantáneo) |
| `prefix f` | Buscar en todas las windows por texto |

---

## Panes (splits)

| Atajo | Acción |
|---|---|
| `prefix \|` | Split vertical (cwd preservado) |
| `prefix -` | Split horizontal (cwd preservado) |
| `prefix h/j/k/l` | Navegar pane izq/abajo/arriba/der |
| `prefix H/J/K/L` | Resize pane (via tmux-pain-control) |
| `prefix z` | Zoom in/out al pane actual (toggle fullscreen) |
| `prefix x` | Cerrar pane actual (con confirmación) |
| `prefix e` | Cerrar TODOS los panes de la window (sin confirm — cuidado) |
| `prefix {` / `prefix }` | Swap pane con anterior / siguiente |
| `prefix q` | Mostrar números de pane (después `<num>` para ir) |
| `prefix !` | Convertir pane actual en window propia |
| `prefix Space` | Rotar layout (even-horizontal, tiled, etc.) |

---

## Copy mode (modo vi)

Entrás con `prefix [`. Salís con `q`.

| Atajo (dentro de copy mode) | Acción |
|---|---|
| `h j k l` | Navegar |
| `w` / `b` | Próxima / anterior palabra |
| `g` / `G` | Inicio / fin del buffer |
| `/` / `?` | Buscar adelante / atrás |
| `n` / `N` | Siguiente / anterior match |
| `v` | Empezar selección |
| `y` | **Copiar al clipboard del sistema** (via pbcopy) |
| `Enter` | Copiar y salir |

**Para pegar** lo copiado (en cualquier pane): `prefix ]`.

---

## Config

| Atajo / Comando | Acción |
|---|---|
| `prefix r` | **Recargar config** (sin matar sesión) |
| `prefix o` | Abrir `pane_current_path` en Finder |
| `prefix g` | **Layout IDE** — arma 5 panes (principal + 2 columnas + terminal + sidebar); no lanza apps, solo el layout |
| `prefix ?` | Listar TODOS los keybindings (`q` para salir) |
| `prefix t` | Reloj en pane fullscreen (estético) |

---

## Plugins (tpm)

Editás la lista en `tmux/tmux.conf` (sección `# ─── plugins`) y:

| Atajo | Acción |
|---|---|
| `prefix I` (mayúscula) | **Instalar** plugins nuevos |
| `prefix U` (mayúscula) | **Actualizar** plugins |
| `prefix alt+u` | Desinstalar plugins removidos del config |

Plugins actuales:
- `tmux-pain-control` — `prefix h/j/k/l` navegar, `prefix H/J/K/L` resize
- `tmux-resurrect` — `prefix Ctrl+s` save, `prefix Ctrl+r` restore (sobrevive reboots)
- `tmux-continuum` — auto-save de resurrect cada 15 min + auto-restore al iniciar
- `tmux-claude-session-manager` — picker/launcher de sesiones Claude (rebindeado a `Alt+u` / `Alt+y`, ver arriba)

---

## Mouse

Habilitado por default. Podés:
- **Click** en pane → selecciona
- **Click** en window (statusline) → selecciona
- **Drag** en pane border → resize
- **Scroll wheel** → entra a copy mode y scrolleás
- **Drag** sobre texto → selección visual (suelta = copy)

Si te molesta: en `tmux.conf` cambiá `set-option -g mouse on` → `off`.

---

## Tips

- **`prefix` se siente lento al principio** — después de 1 día se vuelve automático.
- **`prefix d` (detach) es tu amigo.** Cualquier sesión que querés "pausar" se detachea. Volvés con `tmux a -t <nombre>`.
- **Cada proyecto, su sesión.** Convención útil: `tmux new -s nombre-proyecto` cuando empezás. Después `tmux ls` te muestra contexto.
- **Para no perder hacks:** todo lo que toques en runtime (split, layout) se pierde al matar sesión salvo que `tmux-resurrect` lo guarde. `prefix Ctrl+s` para forzar save.
- **Si un atajo no funciona:** `prefix ?` muestra todo lo binded. `:list-keys` también.
- **Para salir de tmux completamente sin matar:** `prefix d`. NUNCA cierres la terminal con sesiones activas que no querés perder — siempre detacheá primero.
