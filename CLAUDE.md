# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Personal macOS dotfiles for Ghostty, zsh (no Oh My Zsh), Starship, git, and Claude Code. The repo only holds the **portable / shared layer**; anything per-máquina (identity, secrets, settings that diverge across machines) is intentionally not versioned. Understand this split before suggesting changes — the wrong "improvement" can leak personal state into the public repo.

## Commands

- `./install.sh` — single entry point. Idempotent: backs up existing files (`.backup.<timestamp>`) before symlinking. Re-run after `git pull` to pick up changes. Also auto-installs missing Homebrew deps and registers VS Code as default for `.ghostty` files.
- `exec zsh` — reload shell after editing `zsh/` files. Ghostty reloads its own config automatically on save; Starship reads `~/.config/starship.toml` on every prompt render (no reload needed).

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
| `install.sh`                | `claude/settings.json` (untracked)           |
| `karabiner/karabiner.json`  | `claude/memory/` (untracked)                 |
|                             | `claude/skills/` (untracked)                 |

`install.sh` symlinks `claude/{settings.json,skills,memory}` only if they exist locally. They are intentionally absent from the repo so each machine has fully independent Claude state. Do not commit them. Same for `git/.gitconfig` — only the global ignore file is versioned from `git/`.

The override-at-end pattern is load-bearing: in `.zshrc`, `.zshenv`, and `.gitconfig`, the `*.local` source/include is **the last line** so per-máquina values win over repo defaults. Don't move them.

## zsh design constraints

- **No framework** (no Oh My Zsh, no zinit, no zplug). Startup target: <50ms. Adding a plugin manager is a regression, not an upgrade.
- **Plugin source order is mandatory** in `zsh/.zshrc`: autosuggestions → syntax-highlighting → history-substring-search. Inverting 2↔3 silently breaks highlighting on history matches.
- **`pyenv` is lazy-loaded** via a shim function that self-replaces on first call. Eager `pyenv init` adds ~40ms. Other tools (`zoxide`, `fzf`) are eager because they're cheap.
- **`.zshenv` vs `.zshrc`**: env vars and `PATH` that subprocesses (Docker, Claude Code, scripts) need go in `.zshenv`. Aliases, prompt, plugins, UI go in `.zshrc`. Don't move PATH setup into `.zshrc` — non-interactive shells won't see it.

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
- **Estructura modular: 5 archivos**, idéntica al patrón de craftzdog. `tmux.conf` carga `macos.conf` (condicional Darwin), `theme.conf`, `statusline.conf`, `utility.conf`. Si vas a tweakear un color, andá a `theme.conf`/`statusline.conf` — `tmux.conf` solo tiene comportamiento.
- **tpm bootstrap vive en `install.sh`**, no en `tmux.conf`. Plugins listados en `tmux.conf` se instalan con `prefix + I` (mayúscula) la primera vez. tpm clonado en `~/.config/tmux/plugins/tpm/` por el installer (idempotente).
- **Paleta `theme.conf` es duplicación deliberada.** tmux no tiene variables — los mismos hex (lineage del viejo `blueprint-engineering`) viven en `nvim/lua/plugins/colorscheme.lua` y `tmux/theme.conf`. Si cambias el theme de nvim, sincronizá tmux a mano. Ghostty ya no participa: usa built-ins (`theme = Kanagawa Lotus`, etc.) — su paleta es independiente.
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
- **Karabiner `lazy: true` es lo que hace funcionar el dual-function de Caps Lock.** Sin `lazy: true` en el modifier `left_option`, cualquier tap de Caps Lock mandaría `Option` ANTES de saber si era tap o hold — rompiendo apps que reaccionan a Option solo (input methods con dead keys, IME). Con `lazy: true`, el Option se "arma" pero solo se envía si lo combinás con otra tecla; un tap suelto cae al `to_if_alone` → `escape`. No lo saques.
- **Karabiner pide permisos de Input Monitoring + Accessibility la primera vez.** `brew install --cask karabiner-elements` no los puede otorgar — el usuario tiene que aprobar en System Settings → Privacy & Security manualmente. Hasta entonces el daemon no intercepta nada y el caps lock se comporta normal.
- **Karabiner NO auto-reloadea cuando editás `karabiner.json` vía symlink.** Su file watcher mira el symlink, no el target — ediciones al archivo del repo no disparan reload. Para aplicar cambios hay que reiniciar el Core Service, y ojo: corren DOS (uno por user, uno por root) y solo el de root aplica el remap real. `killall Karabiner-Core-Service` o "Quit & Restart" desde la UI solo reinicia el de user — el de root requiere `sudo killall Karabiner-Core-Service`. Verificación: el PID del proceso `root Karabiner-Core-Service` tiene que cambiar (`ps -axco pid,user,command | grep Karabiner-Core`). Si sigue igual después de "Quit & Restart", la regla vieja sigue cacheada en memoria.

## Cross-references to other Claude state

The user's auto-memory (`~/.claude/projects/-Users-m-galicia/memory/`) — which is symlinked from `claude/memory/` when present — contains durable preferences and project context. Two memories particularly relevant here:

- **Docker-only dev workflow** — host-side runtime managers (mise, nvm, pyenv outside Docker) have low ROI. Runtimes live in Dockerfiles. Don't suggest uninstalling host node/npm — Claude Code itself is installed via global npm.
- **Ghostty config gotchas** — already encoded above (no inline comments; `audible-bell` is not a valid key — use `bell-features`).

When suggesting changes, check those memories first if behavior seems surprising.
