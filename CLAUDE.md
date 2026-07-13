# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Personal dotfiles primarily para macOS (Ghostty + Homebrew) con un subset portable que funciona en Linux/WSL2 (zsh, Starship, nvim, tmux, lazygit, git). El repo holds el **portable / shared layer**; cualquier cosa per-máquina (identity, secrets, settings que divergen across machines) es intentionally not versioned. Understand este split antes de suggesting changes — el wrong "improvement" puede leak personal state al public repo.

## Commands

- `./install.sh` — entry point macOS. Idempotente: backs up existing files (`.backup.<timestamp>`) antes de symlinkear. Re-run después de `git pull`. Auto-instala Homebrew deps + casks (incluye fonts), registra VS Code como default para `.ghostty` files.
- `./install-linux.sh` — entry point para Ubuntu/Debian/WSL2. Hace los mismos symlinks (subset portable — skip ghostty, themes) + apt install para lo nativo + cargo install para lo missing (starship, zoxide, delta, tree-sitter, eza). Detecta WSL2 y muestra hints específicos.
- `exec zsh` — reload shell después de editar `zsh/` files. Ghostty reloads su own config automatically on save; Starship reads `~/.config/starship.toml` on every prompt render.

There is no test suite, lint, or build. Changes are validated by running them.

## Architecture: the "per-máquina" split

The defining decision in this repo. Some things are versioned (shared across machines), some are **deliberately not** (each Mac keeps its own):

| Versioned (in repo)         | Per-máquina (gitignored or unlinked)         |
|-----------------------------|----------------------------------------------|
| `zsh/.zshrc`                | `~/.zshrc.local` (sourced at end)            |
| `zsh/.zshenv`               | `~/.zshenv.local` (sourced at end — secrets) |
| `git/.gitconfig`            | `~/.gitconfig.local` (`[include]` at end → wins on conflicts) |
| `git/.gitignore_global`     | `~/.gitconfig` itself (not symlinked at all) |
| `starship/starship.toml`    |                                              |
| `ghostty/config.ghostty`    |                                              |
| `install.sh`                | `claude/settings.json` (untracked, NO symlinkeado) |
|                             | `claude/memory/` (untracked)                 |
|                             | `claude/skills/` (untracked)                 |
|                             | Caps Lock → Option (System Settings UI)      |

`claude/settings.json` es **100% per-máquina y NO se versiona ni se symlinkea** — mismo trato que `~/.gitconfig`. Los permisos y prefs de UI divergen por host, y al symlinkearlo a un repo **público** terminaba arrastrando estado personal (p.ej. `enabledPlugins`/`extraKnownMarketplaces` de marketplaces privados que `/plugin` escribe ahí por default). Cada máquina mantiene su propio `~/.claude/settings.json` real e independiente; este repo no lo toca. Si querés una base de arranque, copiala a mano — pero no la pongas en el repo.

**Excepción controlada — limpieza convergente de hooks obsoletos.** `install.sh` (y `install-linux.sh`) SÍ tocan el `settings.json` real, pero **sin symlinkear ni clobberear**: hasta jul-2026, `tmux-claude-session-manager` leía estado vía 4 hooks (`UserPromptSubmit`/`Notification`/`PreToolUse`/`Stop` → `scripts/state.sh`) que estos installers mergeaban ahí con `jq`. El plugin migró a leer `claude agents --json` directo — **sin hooks** — y borró `state.sh` upstream, así que esos hooks viejos ahora fallan (exit 127) en cada evento. El installer los **limpia de forma convergente** (guard `jq -e ... any(test("…/state.sh"))`, escritura atómica `mktemp` + `mv`): si una máquina todavía los tiene mergeados de una corrida vieja, el próximo `install.sh` los saca sin tocar el resto de `.hooks`. Este bloque es temporal — una vez que todas las máquinas corrieron el `install.sh` nuevo, se puede eliminar.

**Excepción controlada — permisos base.** `install.sh` también agrega `permissions.allow`/`permissions.deny` al `settings.json` real, con la misma lógica additive-only que `statusLine` (guard `jq -e '.permissions.allow'` / `.permissions.deny`, solo escribe si la key todavía no existe — si armaste tu propia lista a mano en esa máquina, no se toca). Lista curada según la doc oficial (code.claude.com/docs/en/permissions): los comandos Bash read-only (`git status`, `diff`, `log`, `ls`, `cat`, `grep`, `find`, etc.) ya no piden confirmación por default, así que `allow` solo cubre lo que sigue generando fricción real — `git add`/`git commit`, y build/test tooling común (`npm run/test`, `cargo build/test`, `go test`, `make`, `docker ps/images` de solo lectura). `deny` bloquea las formas literales más comunes de lo destructivo (`rm -rf *`, `git push --force*`, `sudo *`), que aplica incluso bajo `bypassPermissions`/`auto` mode — pero es best-effort, no una garantía: patrones Bash con wildcard no cubren variantes como `rm -fr`/`rm -r -f` o `git push -f`/`git push origin +main` (ver warning de la doc oficial sobre "Bash permission patterns that try to constrain command arguments are fragile"). Si necesitás un bloqueo real de esas variantes, la vía documentada es un PreToolUse hook, no más strings. Si querés una lista distinta, editala a mano en `~/.claude/settings.json` — el installer nunca la pisa una vez que existe.

**Excepción controlada — status line.** `claude/statusline.sh` (script de la status line: modelo, cwd, git branch, barra de uso de contexto) es genérico y sin estado personal, así que **sí se versiona y symlinkea** con `link()` como cualquier config normal — a diferencia de `settings.json`. Su *activación* (el campo `"statusLine"` en `settings.json`) es lo per-máquina: el installer lo agrega con `jq` solo si **no existe ya** (`jq -e '.statusLine'` como guard) — no pisa una config propia que hayas armado a mano en esa máquina, y no repite el trabajo en re-runs.

`install.sh` symlinks `claude/skills` sólo si existe localmente — es intencionalmente per-máquina (ausente del repo) para que cada máquina tenga estado Claude independiente. No lo commitees. `claude/memory/` **ya NO se symlinkea**: Claude Code deriva el project-id del path real del directorio (trabajando en `~/dotfiles` usa `~/.claude/projects/-Users-m-galicia-dotfiles/memory/`), así que un symlink a un path adivinado quedaba ignorado — la memoria es per-proyecto y la maneja Claude Code solo. Same para `git/.gitconfig` — only the global ignore file is versioned from `git/`.

The override-at-end pattern is load-bearing: in `.zshrc`, `.zshenv`, and `.gitconfig`, the `*.local` source/include is **the last line** so per-máquina values win over repo defaults. Don't move them.

## Tema del stack

El look de la terminal es **un solo tema que abarca tres capas** (Ghostty + nvim + tmux); starship se adapta solo vía nombres ANSI. Un id canónico vale igual en las tres. La selección es un **valor directo, versionado, en cada config** — no hay switcher ni puntero. Cambiás el look editando **tres líneas** (una por capa) y commiteando; un `git pull` lo propaga a las otras máquinas.

- **Las tres líneas de selección** (fuente de verdad, todas versionadas): Ghostty `theme = <id>` en `ghostty/config.ghostty`; nvim `vim.g.theme = "<id>"` en `nvim/lua/config/options.lua`; tmux `source ~/.config/tmux/themes/<id>.conf` en `tmux/tmux.conf`. Las tres tienen que apuntar al **mismo id** o las capas quedan desincronizadas. No hay fallback ni override-at-end: lo que dice la línea es lo que se ve.
- **Por qué directo y no por script.** Hubo un `scripts/theme <id>` que escribía tres punteros (`themes/current` etc.). Se **eliminó**: una vez que la selección pasó a versionarse, el puntero quedó redundante con el `theme =` del config (ambos viajaban por git, el puntero solo ganaba por last-wins) y agregaba indirección sin beneficio. Si buscás en el historial `scripts/theme`, es esto — no lo revivas.
- **Familia canónica (10):** `dark-2026` (clon de "Dark 2026", el theme oscuro por default de VS Code desde 1.113 — hex de `extensions/theme-defaults/themes/2026-dark.json` en microsoft/vscode), `light-2026` (companion claro — clon de "2026 Light", `extensions/theme-defaults/themes/2026-light.json`), `carbon` (minimal true-black, high contrast, acento Claude orange), `solarized-osaka` (**activo**; deep-ocean craftzdog — el id es el nombre completo del plugin en las TRES capas; "osaka" es solo el apodo informal), `xcode-oled` (true black #000 + syntax de Xcode "Default (Dark)" — hex literales del plist `Default (Dark).xccolortheme` de Apple, verificados contra dos copias independientes; los ports a VS Code **no** son fieles y no sirven de fuente. Reemplazó a `oled-neon`), `anthropic-dark`, `anthropic-warm`, `prism-night`, `paper`, `solarized-light` (Solarized Light canónico). Sub-sabores del plugin osaka (solo nvim, no entradas de la matriz): `solarized-osaka-day`, `solarized-osaka-moon`, `solarized-osaka-storm`. `obsidian` sigue siendo theme nvim válido pero queda **fuera** de la matriz (solo nvim).
- **Definiciones versionadas.** Cada tema tiene su paleta en `ghostty/themes/<id>`, `nvim/lua/themes/<id>.lua` (excepto osaka, que es el plugin `solarized-osaka.nvim`) y `tmux/themes/<id>.conf`. Llegan por los symlinks de dir (`~/.config/{ghostty/themes,nvim,tmux}` → repo), así que un `git pull` las entrega sin re-correr `install.sh`.
- **osaka es la fuente de verdad de su propia paleta.** Los hex salen del plugin (`require("solarized-osaka.colors").setup()`, extraíbles con nvim headless) y se hornean a mano en el theme Ghostty y la paleta tmux. El ANSI de Ghostty es espejo **literal** del `M.terminal()` del plugin (`theme.lua`) — mapeo plano (brights == normales, sin orange/violet en ANSI, blanco = fg), para que el shell y un `:terminal` en nvim se vean idénticos; NO la convención Solarized-clásica. tmux, en cambio, es una derivación semántica propia (`@thm_*`): no existe un tema tmux osaka upstream que espejar. Si el plugin cambia su paleta, re-extraé y re-sincronizá esos espejos.
- **Reload:** al cambiar las líneas, Ghostty recarga su config al guardar; nvim aplica **al reabrir**; tmux con `prefix + r` (o al reiniciar el server). En Linux/WSL2 sin Ghostty, simplemente no editás esa línea.
- **Agregar un tema a la familia** = crear sus 3 definiciones (ghostty/nvim/tmux, todas espejo del mismo palette). Activarlo = apuntar las 3 líneas de selección a su id. Agregar SOLO a nvim (fuera de la matriz, estilo `obsidian`) = solo el `.lua`.

## zsh design constraints

- **No framework** (no Oh My Zsh, no zinit, no zplug). Startup target: <50ms. Adding a plugin manager is a regression, not an upgrade.
- **Plugin source order is mandatory** in `zsh/.zshrc`: autosuggestions → syntax-highlighting → history-substring-search. Invertir highlighting↔history-substring rompe en silencio el highlighting sobre matches de history. (fzf-tab se probó y se quitó: la lista interactiva de fzf al tabular no gustó — Tab usa el menú nativo `menu select`. No reintroducirlo.)
- **`pyenv` is lazy-loaded** via a shim function that self-replaces on first call. Eager `pyenv init` adds ~40ms. Other tools (`zoxide`, `fzf`) are eager because they're cheap.
- **`.zshenv` vs `.zshrc`**: env vars and `PATH` that subprocesses (Docker, Claude Code, scripts) need go in `.zshenv`. Aliases, prompt, plugins, UI go in `.zshrc`. Don't move PATH setup into `.zshrc` — non-interactive shells won't see it.
- **Plugin loading es cross-platform vía discovery dinámico.** El `_load_zsh_plugin` en `.zshrc` probe varios paths en orden (macOS brew → linuxbrew → apt `/usr/share` → manual `~/.zsh/plugins`). Esto permite el mismo `.zshrc` symlinkeado en mac y Linux/WSL2 sin tocar. NO volver a hardcodear `/opt/homebrew/share/...` por más limpio que se vea — rompés Linux.
- **PATH en `.zshenv` es condicional.** Cada bloque (brew mac, linuxbrew, cargo) se prepende sólo si el dir existe. Cargo paths sólo aparecen en Linux/WSL2 donde los Rust tools (starship, eza, zoxide, delta) suelen instalarse así.

## Style and conventions

- **Comments explain WHY, not WHAT.** The existing files have many comments documenting non-obvious decisions: lazy-load rationale, plugin ordering footguns, why `~/.gitconfig` isn't symlinked, macOS UTI quirks for `.ghostty`. Match this density when editing — terse code with no comments is *less* in-style here than well-commented code.
- **Section headers** use box-drawing: `# ─── name ──────────────────────` in zsh/toml; `; ─── name ─────` in `.gitconfig`. Keep them.
- **Bilingual is fine.** Prose comments mix Spanish and English freely (mostly Spanish). Code identifiers stay in English. Match the surrounding file.
- **Commit messages** are lowercase, prefixed with one of: `add:`, `feat:`, `fix:`, `chore:`, `refactor:`, `tweak:`. Short (<70 char), often Spanish. Examples from `git log`: `add: zsh helper functions (mkcd, port, server, gco, docker shortcuts)`, `chore: untrack git/.gitconfig — 100% per-máquina`, `tweak: disable CRT vignette`.
- **Color palette** ("Anthropic Warm"): `#d97757` Claude orange, `#c8553d` terracota, `#87a96b` oliva, `#b08968` tierra, `#d9a441` ámbar. Used consistently in Starship and Ghostty. Reuse these instead of inventing new hex codes.

## tmux design constraints

- **Prefix: `C-t`** (no el default `C-b`, que colisiona con vim "page back"). Se cambia en `tmux/tmux.conf` (2 líneas: `unbind C-b` + `set-option -g prefix C-t`).
- **`escape-time 10` es CRÍTICO para nvim.** Default es 500ms — sin override, presionar `<Esc>` en nvim dentro de tmux tiene delay perceptible. No subirlo.
- **`focus-events on` es obligatorio.** Sin esto, gitsigns no detecta cambios externos al buffer y nvim no auto-reloadea archivos modificados afuera.
- **Estructura modular: 5 archivos**, idéntica al patrón de craftzdog. `tmux.conf` carga `macos.conf` (condicional Darwin), la paleta del tema (`source themes/<id>.conf`, la línea de selección), `theme.conf`, `statusline.conf`, `utility.conf`. `theme.conf`/`statusline.conf` son ahora **solo estructura** (no hex) — los colores salen de `themes/<id>.conf` vía user-options `@thm_*`. Si vas a tweakear un COLOR, andá a `tmux/themes/<id>.conf`; si es ESTRUCTURA (segmentos, separadores), a `theme.conf`/`statusline.conf`.
- **tpm bootstrap vive en `install.sh`**, no en `tmux.conf`. Plugins listados en `tmux.conf` se instalan con `prefix + I` (mayúscula) la primera vez. tpm clonado en `~/.config/tmux/plugins/tpm/` por el installer (idempotente). **Footgun: tpm re-bindea `prefix + I`/`prefix + U` incondicionalmente en su `run` (última línea del config)** — cualquier `bind I` propio definido antes queda clobbereado en silencio en cada arranque (pasó con el layout IDE, que vivió muerto en `I` hasta jul-2026; hoy está en `prefix + g` → `scripts/ide`). Binds propios: o en otra tecla, o después del `run` de tpm (patrón `unbind y`/`unbind u`).
- **`tmux-claude-session-manager` (craftzdog) — picker de sesiones Claude.** Declarado en `tmux.conf` (`@plugin`), instalado por tpm (`prefix + I`) como el resto — ya no se pre-clona (era solo para ordenar el merge de hooks viejo, ver más abajo). El plugin bindea sus comandos en la tabla **prefix** (prefix+y launcher, prefix+u picker), pero los **rebindeamos a chord único `Alt+y`/`Alt+u`** para que matcheen el resto de popups de `utility.conf`: los `bind -n M-y/M-u` (que llaman a los scripts `launch.sh`/`list.sh` del plugin) viven en `utility.conf`, y los de prefix se desactivan con `unbind y`/`unbind u` en `tmux.conf` **después** del `run` de tpm (sino el plugin los re-bindea encima). Entonces: `Alt+u` = picker central de TODAS las sesiones Claude (estado live working/waiting/idle + preview), `Alt+y` = launcher por directorio. **Desde jul-2026 (v1.0+) el estado live sale directo de `claude agents --json`** (requiere Claude Code ≥ 2.1.139 + `jq`) — el plugin borró `scripts/state.sh` y el mecanismo de hooks en `settings.json` (ver "limpieza convergente de hooks obsoletos" arriba); cero setup, no hay hooks que instalar ni mantener. Identifica cada agente por su **proceso** (pid → tty → pane), no por sesión tmux, así que varios Claudes en el mismo proyecto aparecen como filas separadas. Convive **sin conflicto** con el popup casero `Alt+c`: el `session_hash()` del plugin está hecho a propósito para igualar `echo path | md5sum | cut -c1-8` — el mismo algoritmo del `Alt+c` —, así que para un mismo dir `Alt+c` y `Alt+y` resuelven a la **misma** sesión `claude-<hash>` y la comparten (no se duplican). El `Alt+u` del plugin **reemplazó al viejo `Alt+s`** (selector per-proyecto, ya retirado junto con `scripts/tmux-claude`): el picker es un superset (todas las sesiones, estado live, preview). El picker matchea por prefijo `claude-`, así que también lista las sesiones que creó `Alt+c`. El `Alt+C` YOLO sí es sesión aparte (prefijo `claude-yolo-`).
- **Paleta tmux vía user-options `@thm_*`.** tmux SÍ tiene variables: cada `tmux/themes/<id>.conf` setea `@thm_bg/@thm_fg/@thm_accent/…` y la estructura (`theme.conf`/`statusline.conf`) los consume. Style options con `set -gF` (hornea el hex al sourcear, porque NO son formatos y no expanden en draw); format options (`status-left`, `window-status-*-format`) con `set -g` y `#{@thm_*}` inline (expanden en draw, conviven con `#S`/`%H:%M`). Si invertís eso, o ves `fg=#{@thm_x}` literal en un border, es que usaste el flag equivocado.
- **El tema es cross-stack, NO por-herramienta — ver sección "Tema del stack".** Ghostty, nvim y tmux comparten un id de tema. Para cambiar el look editás las **tres** líneas de selección (Ghostty `theme =`, nvim `vim.g.theme`, tmux `source themes/<id>.conf`) al mismo id — si tocás solo una, quedan desincronizados. Starship se adapta solo (ANSI).
- **`utility.conf` tiene los popups por proyecto (todos chord único sin prefix, `bind -n M-…`).** `Alt+c` abre Claude Code en una sesión tmux dedicada por directorio (md5 del path = session ID) — cerrás el popup, Claude sigue vivo en background; reabrir desde otro pane del mismo proyecto te devuelve la misma sesión con su contexto. `Alt+g` para lazygit, `Alt+Enter` shell rápida, `Alt+y`/`Alt+u` los del plugin (ver bullet anterior). Todos a 90% con marco redondeado temático (popup-border-* en `theme.conf`).

## nvim design constraints

- **Modular custom, no distro.** Sin LazyVim / NvChad / AstroNvim. Plugin manager: `lazy.nvim` (NO Packer, deprecado). Estructura: `init.lua` carga `lua/config/*` (options, keymaps, autocmds, lazy bootstrap), y `lua/config/lazy.lua` auto-importa todo `lua/plugins/*.lua` — agregar un plugin = agregar un archivo, sin tocar índices.
- **Mason no contamina brew.** LSPs/formatters/linters se instalan en `~/.local/share/nvim/mason/`. NO los duplicas en `REQUIRED_FORMULAE` de `install.sh`. La excepción son toolchains base (go, php, node) que el sistema necesita para que mason pueda usar sus servers.
- **Rust va aparte vía `rustaceanvim`.** No lo metas al loop de `mason-lspconfig` ni a `lspconfig`. Tiene su propio `plugins/rust.lua` que se autoregistra al abrir un buffer `.rs`. Inlay hints, runnables y debug son mejores que con la config genérica de `rust_analyzer`.
- **Completion: `blink.cmp`, no `nvim-cmp`.** Más rápido (escrito en Rust, binarios precompilados vía `version = "*"`), API más simple. Si ves docs viejas de `cmp-nvim-lsp` / `cmp-buffer` / `cmp-path` — no las apliques, blink las reemplaza todas.
- **Conventions por filetype viven en `autocmds.lua`**, no en options globales: Go usa tabs reales (gofmt los inserta), PHP/Rust 4 espacios, markdown activa wrap+spell. Si agregas un lenguaje nuevo con convención propia, agrégalo ahí.
- **Format on save selectivo.** `plugins/conform.lua` solo formatea on-save lenguajes con formatter canónico (go, rust, lua). Para los discutibles (markdown, sql, php) usa `<leader>cf` manual — evita pelearse con estilos de proyecto.
- **`signcolumn = "yes"` siempre.** Evita el layout shift cuando aparece un sign de LSP/git mid-edit. No lo cambies a `"auto"`.

## Tool-specific gotchas

- **Ghostty config does NOT allow inline comments** on the same line as a value (`key = val  # comment` breaks). Comments go on their own line.
- **Starship `$` is a variable sigil.** A literal `$` in a format string needs `\$` (in TOML double-quoted, write `\\$`). Same for `[` and `]` → `\\[`, `\\]`.
- **`.ghostty` files have no macOS UTI**, so without intervention `⌘,` opens them in TextEdit. `install.sh` registers VS Code via `defaults write` on `LaunchServices`; the block is idempotent (checks before writing).
- **`bat` is aliased to `cat`** — `\cat` invokes the real one when bypassing aliases is needed (e.g., for piping into tools that choke on bat output).
- **nvim `init.lua` order is load-bearing**: `options` → `keymaps` (setea `<leader>`) → `lazy` (lee `mapleader` al registrar `keys`) → `autocmds`. No los reordenes.
- **`mapleader` debe estar seteado ANTES de `require("lazy")`** o los `keys = {}` de cada plugin se registran con leader vacío. Por eso vive al inicio de `lua/config/keymaps.lua`, que se carga antes de `lua/config/lazy.lua`.
- **Caps Lock → Option vive en macOS nativo, no en el repo.** System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys → Caps Lock = Option. Karabiner-Elements se intentó pero rompía las teclas `<>` y `|°` en MacBook built-in con layout Latin American (su virtual HID solo soporta `ansi`/`iso`/`jis` genéricos — ninguno mapea ISO-LA, por lo que se swappean esas dos teclas). Si en el futuro necesitás remaps más complejos que macOS nativo no soporte (multi-key chords, layer toggles), evaluar Hammerspoon o Karabiner con per-device override antes de versionarlo.

## Cross-references to other Claude state

The user's auto-memory (per-proyecto, manejada por Claude Code en `~/.claude/projects/<id-del-path>/memory/`; ya no se symlinkea desde el repo) contains durable preferences and project context. Two memories particularly relevant here:

- **Docker-only dev workflow** — host-side runtime managers (mise, nvm, pyenv outside Docker) have low ROI. Runtimes live in Dockerfiles. Don't suggest uninstalling host node/npm — Claude Code itself is installed via global npm.
- **Ghostty config gotchas** — already encoded above (no inline comments; `audible-bell` is not a valid key — use `bell-features`).

When suggesting changes, check those memories first if behavior seems surprising.
