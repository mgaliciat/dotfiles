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

`install.sh` symlinks `claude/skills` y `claude/memory` sólo si existen localmente — son intencionalmente per-máquina (ausentes del repo) para que cada máquina tenga estado Claude independiente. No los commitees. Same para `git/.gitconfig` — only the global ignore file is versioned from `git/`.

The override-at-end pattern is load-bearing: in `.zshrc`, `.zshenv`, and `.gitconfig`, the `*.local` source/include is **the last line** so per-máquina values win over repo defaults. Don't move them.

## Tema del stack (theme switcher)

El look de la terminal es **un solo tema que abarca tres capas** (Ghostty + nvim + tmux); starship se adapta solo vía nombres ANSI. Un id canónico vale igual en las tres. Cambiás el look con **`scripts/theme <id>`** (o la función `theme` de `functions.zsh`, con completion) — NO editando cada herramienta a mano.

- **Familia canónica (7):** `carbon` (minimal true-black, high contrast, acento Claude orange, **default**), `osaka` (deep-ocean craftzdog), `oled-neon`, `anthropic-dark`, `anthropic-warm`, `prism-night`, `paper`. Alias osaka (sub-sabores del plugin, no entradas de la matriz): `solarized-osaka`, `osaka-moon`, `osaka-storm`, `osaka-day`. `obsidian` sigue siendo theme nvim válido pero queda **fuera** del switcher (solo nvim).
- **Definiciones versionadas, selección per-máquina.** Cada tema tiene su paleta en `ghostty/themes/<id>`, `nvim/lua/themes/<id>.lua` (excepto osaka, que es el plugin `solarized-osaka.nvim`) y `tmux/themes/<id>.conf`. La *selección activa* son tres punteros gitignored (`*.local`) que escribe el switcher: `ghostty/themes/current.local`, `nvim/lua/theme-current.local`, `tmux/current.local`. Toggling NO genera commits.
- **Cada capa lee el puntero como override-at-end** (mismo ADN que `.zshrc.local`): Ghostty `config-file = ?~/.config/ghostty/themes/current.local` (último `theme=` gana; `?` = opcional); nvim lee `theme-current.local` en `options.lua` con fallback al default; tmux `source -q current.local` después de la paleta default. Sin puntero (máquina recién clonada) → todo cae a carbon.
- **osaka es la fuente de verdad de su propia paleta.** Los hex salen del plugin (`require("solarized-osaka.colors").setup()`, extraíbles con nvim headless) y se hornean a mano en el theme Ghostty y la paleta tmux. Si el plugin cambia su paleta, re-extraé y re-sincronizá esos dos espejos.
- **Reload:** tmux se re-sourcea en vivo si hay server; Ghostty y nvim aplican **al reabrir** (decisión deliberada: sin push a instancias vivas). En Linux/WSL2 sin Ghostty, el switcher omite esa capa sin error.
- **Agregar un tema a la familia** = crear sus 3 definiciones (ghostty/nvim/tmux, todas espejo del mismo palette) + una entrada en el `case` de `scripts/theme` + el `compadd` de `functions.zsh`. Agregar SOLO a nvim (fuera de la matriz, estilo `obsidian`) = solo el `.lua`.

## zsh design constraints

- **No framework** (no Oh My Zsh, no zinit, no zplug). Startup target: <50ms. Adding a plugin manager is a regression, not an upgrade.
- **Plugin source order is mandatory** in `zsh/.zshrc`: autosuggestions → syntax-highlighting → history-substring-search. Inverting 2↔3 silently breaks highlighting on history matches.
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
- **Estructura modular: 5 archivos**, idéntica al patrón de craftzdog. `tmux.conf` carga `macos.conf` (condicional Darwin), la paleta del tema (`themes/<id>.conf` + `current.local`), `theme.conf`, `statusline.conf`, `utility.conf`. `theme.conf`/`statusline.conf` son ahora **solo estructura** (no hex) — los colores salen de `themes/<id>.conf` vía user-options `@thm_*`. Si vas a tweakear un COLOR, andá a `tmux/themes/<id>.conf`; si es ESTRUCTURA (segmentos, separadores), a `theme.conf`/`statusline.conf`.
- **tpm bootstrap vive en `install.sh`**, no en `tmux.conf`. Plugins listados en `tmux.conf` se instalan con `prefix + I` (mayúscula) la primera vez. tpm clonado en `~/.config/tmux/plugins/tpm/` por el installer (idempotente).
- **Paleta tmux vía user-options `@thm_*`.** tmux SÍ tiene variables: cada `tmux/themes/<id>.conf` setea `@thm_bg/@thm_fg/@thm_accent/…` y la estructura (`theme.conf`/`statusline.conf`) los consume. Style options con `set -gF` (hornea el hex al sourcear, porque NO son formatos y no expanden en draw); format options (`status-left`, `window-status-*-format`) con `set -g` y `#{@thm_*}` inline (expanden en draw, conviven con `#S`/`%H:%M`). Si invertís eso, o ves `fg=#{@thm_x}` literal en un border, es que usaste el flag equivocado.
- **El tema es cross-stack, NO por-herramienta — ver sección "Tema del stack".** Ghostty, nvim y tmux comparten un id de tema y se voltean juntos con `scripts/theme <id>`. NO edites el `theme=` de Ghostty ni `vim.g.theme` a mano para cambiar el look — usá el switcher (sino quedan desincronizados). Starship se adapta solo (ANSI).
- **`utility.conf` tiene los popups por proyecto.** `prefix + y` abre Claude Code en una sesión tmux dedicada por directorio (md5 del path = session ID) — cerrás el popup, Claude sigue vivo en background; reabrir desde otro pane del mismo proyecto te devuelve la misma sesión con su contexto. Igual con `prefix + g` para lazygit.

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

The user's auto-memory (`~/.claude/projects/-Users-m-galicia/memory/`) — which is symlinked from `claude/memory/` when present — contains durable preferences and project context. Two memories particularly relevant here:

- **Docker-only dev workflow** — host-side runtime managers (mise, nvm, pyenv outside Docker) have low ROI. Runtimes live in Dockerfiles. Don't suggest uninstalling host node/npm — Claude Code itself is installed via global npm.
- **Ghostty config gotchas** — already encoded above (no inline comments; `audible-bell` is not a valid key — use `bell-features`).

When suggesting changes, check those memories first if behavior seems surprising.
