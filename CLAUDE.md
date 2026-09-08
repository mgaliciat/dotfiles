# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Personal dotfiles for macOS (Ghostty + Homebrew), with a portable subset for Linux/WSL2 (zsh, nvim, tmux, lazygit, git) and a deliberately narrow native-Windows entry point. The repo holds the **portable / shared layer**; anything per-machine (identity, secrets, settings that diverge across machines) is intentionally not versioned. **The repo is public** — understand that split before suggesting changes, because the wrong "improvement" leaks personal state into it.

## Commands

- `./install.sh` — macOS. Idempotent; backs up existing files (`.backup.<timestamp>`) before symlinking. Re-run after `git pull`.
- `./install-linux.sh` — Ubuntu/Debian/WSL2. Portable subset (no ghostty), apt + curl installers + GitHub release binaries. **No `cargo install` step — don't reintroduce one.**
- `./install-windows.ps1` — native Windows. The Claude Code pieces, `git/.gitignore_global`, Nerd Fonts and the Windows Terminal theme/keybindings. Not a port of the rest; don't expect parity. Needs Developer Mode for symlinks.
- `exec zsh` after editing `zsh/`. **Ghostty does not watch its config** — after editing `ghostty/config.ghostty` or a theme, press `Cmd+Shift+R` in an open window or nothing changes on screen.

No test suite, lint or build. Changes are validated by running them.

**`runbook/` is the operator's copy of the installers** — one file per OS, with the ordering that avoids a second run. It restates what the installers do, so **a change to an installer's steps, guards or output markers is not done until the matching runbook says the same thing.** Rationale lives here; the runbooks hold only the how.

## Architecture: the per-machine split

The defining decision in this repo. Some things are versioned, some are **deliberately not**:

| Versioned (in repo)         | Per-machine (gitignored or unlinked)         |
|-----------------------------|----------------------------------------------|
| `zsh/.zshrc`                | `~/.zshrc.local` (sourced at end)            |
| `zsh/.zshenv`               | `~/.zshenv.local` (sourced at end — secrets) |
| `git/.gitignore_global`     | `~/.gitconfig` itself (not symlinked at all) |
| `ghostty/themes/*`          | `~/.gitconfig.local` (`[include]` at end → wins on conflicts) |
| `ghostty/config.ghostty`    | `~/.claude/settings.json` (never versioned, never symlinked) |
| `claude/statusline.sh`      | `~/.claude/skills/` (real dir, per-machine)  |
| `claude/CLAUDE.md` (user-level, → `~/.claude/CLAUDE.md`) | `~/.claude/projects/*/memory/` (Claude Code owns it) |
| `claude/install/*`          | `~/.claude/claude-api.env` (gateway credential, never versioned) |
| `zsh/functions.zsh`         | Caps Lock → Option (System Settings UI)      |

- **The override-at-end pattern is load-bearing**: in `.zshrc`, `.zshenv` and `.gitconfig` the `*.local` source/include is the **last line**, so per-machine values win. Don't move them.
- **`skills/` and `memory/` are unlinked for different reasons.** `skills/`: the symlink worked, but the content is per-machine and one loosened `.gitignore` from leaking. `memory/`: Claude Code derives the project id from the *real* path, so a symlink was silently ignored.
- **`~/.claude/claude-api.env` holds a gateway credential** — never versioned, never symlinked, and deliberately **not** in `~/.zshenv.local`: `.zshenv` is sourced by every zsh, so an export there hands the token to every process the shell spawns. `zsh/functions.zsh` and `scripts/claude-api-env` **parse** it (`NAME=value`, optional `export`, `#` comments) rather than sourcing it, so a credentials file can't run commands — don't "simplify" that into a `source`. It carries the real `ANTHROPIC_*` / `CLAUDE_CODE_*` names, passed through verbatim; the required one is `ANTHROPIC_BASE_URL`.
- **`--api` is recognised only as the FIRST argument** to the `claude` / `code` shell functions, and is stripped before the binary sees it. Scanning the whole list would corrupt `claude -p 'compare --api vs the SDK'`. Everything else is `command claude` verbatim, so a machine with no gateway behaves as if the functions did not exist.
- **The parsing lives in `scripts/claude-api-env`, on PATH at `~/.local/bin/`; the shell functions are a facade.** A zsh function exists only in an interactive shell, and tmux launches its popups through `$SHELL -c` where `.zshrc` never runs — an executable on PATH serves the shell, tmux, scripts and hooks from one implementation.
- **A tmux Claude session name must start with `claude-`.** `Alt+d`'s detach guard matches `#{m:claude*,…}` and the `Alt+u` picker lists by that prefix. The gateway twins (`Alt+a`/`Alt+A`) use `claude-api-` / `claude-api-yolo-`; they check `command -v claude-api-env` first (between a `git pull` and `./install.sh` the helper isn't there yet) and set `CLAUDE_API_HOLD_ERRORS=1`, because the popup's only process is the helper and a plain exit would destroy the session with the error message still in it.

**Versioned skills are per-item symlinks, never the parent dir.** `claude/skills/logbook/` is a skills-dir plugin (`.claude-plugin/plugin.json`), loaded in place — a `git pull` propagates edits with no marketplace and no copy into `~/.claude/plugins/cache/`. It therefore lives in `settings.sh`, not `plugins.sh`. Plugin skills are **always** colon-namespaced: `/logbook:entry`, `/logbook:ingest`, `/logbook:query`, `/logbook:lint`, `/logbook:guide`, `/logbook:runbook`, `/logbook:document`, where the folder name is the skill name — so the folders are bare (`entry`, not `wiki-lint`, which once produced `/wiki:wiki-lint`).

**Renaming or adding a versioned skill means editing the `.gitignore` whitelist in the same commit.** `claude/skills/*` is ignored and each versioned skill is whitelisted by literal name, so a `git mv` drops the old path from the index and silently declines to add the new one — `git status` then reports a clean tree with the skill deleted.

## Claude Code config: `claude/install/`

Everything this repo does to `~/.claude/` lives here, split by **who writes to `settings.json`** — that determines who owns idempotency and where to look when something breaks.

| | File | Who writes `settings.json` | Idempotency | Currently |
|---|---|---|---|---|
| **1** | `settings.sh` | **We do**, with `jq` | Our guard (only if the key is absent) | `statusLine`, `permissions.*`, `attribution.*`, `outputStyle`, the logbook `PostToolUse` hook, stale-hook cleanup, symlinks for `statusline.sh` + `CLAUDE.md` + `hooks/logbook.sh` + the `logbook` skill plugin |
| **2** | `binaries.sh` | The **external binary**, in its own setup command | The binary handles it | `rtk`, `codebase-memory-mcp`, `context7` and `open-knowledge` (endpoint-only, credentials from env), the `gh-stack` skill |
| **3** | `plugins.sh` | The **CLI** (`claude plugin`) | The CLI handles it | *(nothing — the helper stays)* |

`install.sh` and `install-linux.sh` source all three through `install_claude` in `scripts/lib.sh`; the portable symlink list is `link_portable` in the same file, so adding a file is one edit, not one per installer. `install-windows.ps1` **replicates both by hand** and nothing keeps it in sync automatically.

**To add something new:** marketplace plugin → mechanism 3. Standalone binary or MCP server → mechanism 2. Mechanism 1 only when nobody else will write it.

**`~/.claude/settings.json` is never versioned and never symlinked** — same treatment as `~/.gitconfig`. Every write above is additive-only and guarded, so a list built by hand on that machine is never clobbered.

### Invariants — break these and it fails silently

The full reasoning lives in the comments of each `claude/install/*.sh` — read it before editing one. What follows is only what breaks quietly:

- **Source order.** `settings.sh` → `binaries.sh` → `plugins.sh`, fixed inside `install_claude` — don't source them directly from an installer. `settings.sh` symlinks `~/.claude/CLAUDE.md`; `rtk init` (in `binaries.sh`) appends an `@RTK.md` line that must land on the versioned file through that symlink. All three run **after** the deps block (`settings.sh` needs `jq`).
- **`codebase-memory-mcp install -y` runs with NO guard.** It registers the MCP server, the hooks and the `codebase-memory` skill. Behind the binary's `command -v` guard, a hand-deleted `~/.claude` never gets rebuilt and the install still looks like it worked. If that skill vanishes after an install, someone moved this back inside the `if`.
- **`codebase-memory-mcp` ships two binaries per release and the official installer picks the wrong one.** The graph UI on `localhost:9749` exists only in the `-ui-` asset; the headless build accepts `--ui=true`, warns, and **keeps running**, so the symptom is a dead port rather than an error. `install-windows.ps1` fetches the `-ui-` asset itself. The two builds are indistinguishable from outside (same filename, same `--version`), so the guard is a **stamp file** — `~/.local/bin/.codebase-memory-mcp-ui` — and `codebase-memory-mcp update` self-updates back to headless, which only a stamp mismatch catches. Enable the UI with `config set ui_enabled true` + `ui_port`, **not** the documented `--ui=true --port=N`, which persists the keys and then blocks running the server. `binaries.sh` (mac/Linux) still installs the headless build.
- **The `.zshrc` cleanup writes with `cat >`, never `mv`.** `~/.zshrc` is a symlink into the repo; `mv` replaces it with a regular file *and* leaves the dirty line in the versioned one. (The `settings.json` cleanup does use `mktemp` + `mv` — correct there, it's a real file.)
- **Permissions live in `claude/install/permissions.json`.** Single source of truth: `settings.sh` reads it with `jq --slurpfile`, `install-windows.ps1` with `ConvertFrom-Json`.
- **On Windows the plugin block must come *after* the `settings.json` `WriteAllText`.** The plugin CLI writes `enabledPlugins` there; a later write of our `$Settings` object clobbers it.
- **`$SkillsDir` is assigned in one block of `install-windows.ps1` and read far below.** With `$ErrorActionPreference = "Stop"`, `Join-Path $null` throws — dropping the assignment once silently stopped the gh-stack skill, the fonts, the WT theme and the keybindings from installing for two weeks. Grep for a variable before deleting the block that sets it.
- **The logbook hook is guarded on its COMMAND STRING, not a `jq` path.** `.hooks.PostToolUse` is an array shared with other tools, so `_settings_set_if_absent` is the wrong shape — its key would be satisfied by somebody else's hook. Deep-scanning for `hooks/logbook` is the only check that is both idempotent and additive. Same guard in `install-windows.ps1`.
- **The hook's `matcher` is `Bash|PowerShell`, not `Bash`.** `CLAUDE_CODE_USE_POWERSHELL_TOOL` routes commits through the PowerShell tool on Windows. It is registered as `bash ~/.claude/hooks/logbook.sh`, naming the interpreter, because the file arrives through a symlink and git does not reliably carry the exec bit.
- **Hook scripts must be silent on every path but the one.** Their stdout is parsed as JSON; a stray `echo` or PowerShell error record breaks the parse. Hence `|| exit 0` on every step in the `.sh` and one `try/catch` around the whole `.ps1`.
- **Plugin URLs are full `https://`**, never the `owner/repo` shorthand, which clones over SSH and fails on a machine with no key.
- **`</dev/null` on `rtk init` and the `claude plugin` calls.** Both hung waiting on an invisible interactive prompt.
- **`claude/install/rtk-config.toml` is COPIED, never symlinked** — the only copy-instead-of-link here. rtk load→mutate→serializes its own config (`rtk telemetry disable` drops every comment and appends a timestamp), so through a symlink that per-machine state lands in this public repo. The repo file is the source of truth, `binaries.sh` pushes it out unconditionally, the installed copy is disposable. Path is OS-dependent — the one OS branch in `binaries.sh`; Windows parses it out of `rtk config` instead, because rtk documents no Windows location. Don't unify the two.
- **The Windows mirror of `settings.sh` is checked in CI, key by key.** `.github/workflows/lint.yml` fails if `install-windows.ps1` never writes a key `settings.sh` sets (quoted — a mention in a comment doesn't count). A key that should not be mirrored goes in the step's allowlist with its reason; today that is only `terminalTitleFromRename`.
- **Stale-hook cleanup in `settings.sh` is temporary.** Once every machine has run this installer, delete that block.

### `claude/CLAUDE.md` (user-level → `~/.claude/CLAUDE.md`)

Preferences that apply to ALL projects, distinct from this file. Two admitted categories: (a) which tools from these dotfiles to use and how; (b) general output/communication preferences.

**A tool has to be installed by this repo to be documented there** — if it's not in `install.sh` or `install-linux.sh`, it doesn't belong. Category (b) doesn't depend on installed tools. **mac + Linux is the bar; Windows is allowed to lag** and catches up as things get tested there.

## The stack theme

One theme spanning three layers (Ghostty + nvim + tmux), plus Windows Terminal as an independent fourth. Selection is a **direct, versioned value in each config** — no switcher, no pointer.

- **The three selection lines must name the same id** or the layers desync: `theme = <id>` in `ghostty/config.ghostty`, `vim.g.theme = "<id>"` in `nvim/lua/config/options.lua`, `source ~/.config/tmux/themes/<id>.conf` in `tmux/tmux.conf`. No fallback, no override-at-end.
- **Windows Terminal has a FOURTH, independent line** (`$WtTheme` in `install-windows.ps1`) — the one place the "same id everywhere" rule does not hold, because a native-Windows box shares none of the other layers. Its scheme is **generated at install time from `ghostty/themes/<id>`**; no `.json` copy of a palette is versioned. The write overwrites `profiles.defaults.colorScheme` on purpose, but only when its current value is a member of the family, so a scheme picked by hand in the WT UI is left alone. WT's `settings.json` is JSONC: if it still has its shipped `//` comments `ConvertFrom-Json` refuses it, and the block skips rather than regex-stripping `//` out of `"https://…"`.
- **Enumerate a font family name, never trust the config.** On Windows the oracle is `[System.Windows.Media.Fonts]::SystemFontFamilies` (the DirectWrite view WT resolves against); GDI+/`System.Drawing` reports a different set and is the wrong one to ask. A family that does not exist falls back **silently**. Installing a font needs a per-user registry entry plus `AddFontResourceW` + a `WM_FONTCHANGE` broadcast, or it only exists from the next logon — and a variable font's `[MONO,wght]` filename **must** be copied with `-LiteralPath`, or PowerShell reads the brackets as a wildcard, copies nothing and reports success.
- **Versioned definitions**: `ghostty/themes/<id>`, `nvim/lua/themes/<id>.lua`, `tmux/themes/<id>.conf`, all mirroring one palette. They arrive through the directory symlinks, so a `git pull` delivers them without re-running `install.sh`. **Where each palette's hex came from, and which sources are not valid, is in `ghostty/themes/README.md`** — read it before touching one.
- **Reload:** Ghostty `Cmd+Shift+R` (no file watcher — a saved theme looks like nothing happened until you press it); nvim on reopen; tmux `prefix + r`.
- **Adding a theme** = its 3 definitions. **Activating** = point the 3 selection lines at its id. Windows needs nothing — its scheme derives from the ghostty file.
- Selection used to go through a `scripts/theme <id>`; it was deleted as redundant with the config's own `theme =`. Don't revive it.

## zsh design constraints

- **No framework** (no Oh My Zsh, zinit, zplug). Startup target <50ms. A plugin manager is a regression.
- **Plugin source order is mandatory** in `zsh/.zshrc`: autosuggestions → syntax-highlighting → history-substring-search. Swapping the last two silently breaks highlighting over history matches. fzf-tab was tried and removed; don't reintroduce it.
- **`pyenv` is lazy-loaded** via a shim that self-replaces on first call — eager `pyenv init` adds ~40ms. `zoxide` and `fzf` are eager because they're cheap.
- **`.zshenv` vs `.zshrc`**: env vars and `PATH` that subprocesses need go in `.zshenv`; aliases, prompt, plugins and UI in `.zshrc`. Don't move PATH setup into `.zshrc` — non-interactive shells won't see it.
- **Plugin loading is cross-platform via dynamic discovery** (`_load_zsh_plugin` probes brew → linuxbrew → apt → `~/.zsh/plugins`). Do NOT hardcode `/opt/homebrew/share/...` back in, however much cleaner it looks — it breaks Linux.
- **PATH in `.zshenv` is conditional**, each block prepended only if the dir exists.

## tmux design constraints

- **Prefix is `C-t`**, not `C-b` (which collides with vim page-back).
- **`escape-time 10` is CRITICAL for nvim.** The 500ms default makes `<Esc>` perceptibly laggy. Don't raise it.
- **`focus-events on` is mandatory** — without it gitsigns misses external changes and nvim doesn't auto-reload modified files.
- **5 files.** `tmux.conf` loads `macos.conf`, the theme palette (the selection line), `theme.conf`, `statusline.conf`, `utility.conf`. `theme.conf` / `statusline.conf` are **structure only, no hex**. Colour → `themes/<id>.conf`. Structure → the other two.
- **tpm unconditionally rebinds `prefix + I` / `prefix + U` in its `run`** (last line of the config), silently clobbering any earlier `bind I` of your own. Use another key, or bind *after* tpm's `run` (the `unbind y` / `unbind u` pattern). tpm bootstrap itself lives in `bootstrap_tmux` (`scripts/lib.sh`), not in `tmux.conf`.
- **Style options use `set -gF`** (bakes the hex at source time — they are NOT formats); **format options use `set -g`** with inline `#{@thm_*}` (expanded at draw time). Invert that and a border shows a literal `fg=#{@thm_x}`.
- **The statusline's backgrounds are `bg=default`, never `#{@thm_bg}`** — a baked hex is opaque and sits as a solid strip over a translucent terminal. `default` inherits whatever the terminal shows, for every theme. `@thm_bg` still exists as a *foreground*.
- **`utility.conf`'s overlays are all 90% floating popups** on single chords (`bind -n M-…`): `Alt+g` lazygit, `Alt+Enter` shell, `Alt+c`/`Alt+C` Claude, `Alt+a`/`Alt+A` its gateway twins, `Alt+u` picker, `Alt+y` launcher. `Alt+c` attaches a popup to a per-directory session (md5 of the path); `Alt+d` detaches it and Claude stays alive. **Don't "improve" this into `switch-client`** — tried and reverted: a popup client is disposable, and taking over the only client made every exit path load-bearing.
- **`tmux-claude-session-manager` is pinned to a commit in `bootstrap_tmux`**, not left to `prefix + I`, so every machine runs the same picker; bump = change the SHA and re-run the installer. Its `session_hash()` matches `Alt+c`'s own `echo path | md5sum | cut -c1-8`, so both share one session per directory. Live state comes from `claude agents --json` (needs Claude Code ≥ 2.1.139 + `jq`) and identifies agents by process, so several Claudes in one project are separate rows.
- **`#{q:…}` goes BARE, never inside quotes.** It escapes with backslashes, so `'#{q:…}'` breaks on a `'` in the path and `"#{q:…}"` keeps the backslashes in the value.

## nvim design constraints

- **Modular custom, no distro** (no LazyVim / NvChad / AstroNvim). `lazy.nvim`, not Packer. `lua/config/lazy.lua` auto-imports all of `lua/plugins/*.lua` — adding a plugin is adding a file.
- **Mason doesn't pollute brew.** Servers and tools install into `~/.local/share/nvim/mason/`; do NOT duplicate them in `REQUIRED_FORMULAE`. The exception is base toolchains (go, php, node). **Two installers by what they know about**: `mason-lspconfig` for servers, `mason-tool-installer` for everything conform/nvim-lint/neotest reference. **A formatter named in `conform.lua` that is not in that list silently never runs** — that is how Go and Lua went unformatted-on-save for months.
- **Go and Lua are first-class.** gopls with staticcheck + govulncheck on imports, golangci-lint through `nvim-lint` for what gopls can't host (the project's `.golangci.yml` wins), neotest + neotest-golang. lua_ls + `lazydev` — **never put `nvim_get_runtime_file` back in `workspace.library`**, it re-indexes the whole runtime on every start. **This repo opts out of stylua** via `/.styluaignore` (its lua aligns `=` by hand); `conform.lua` anchors stylua's cwd on that file, and stylua is `automatic_enable`-excluded in mason-lspconfig because it also ships an LSP and would attach twice.
- **Rust goes through `rustaceanvim`**, never the `mason-lspconfig` loop or `lspconfig`. **The toolchain is rustup's, not mason's**: `rustup component add rust-analyzer rustfmt rust-src clippy` — the server must match the compiler it analyses for. A rustup *proxy* on PATH passes `command -v` and fails on exec, so check `rust-analyzer --version`, not the path. Tests use rustaceanvim's own neotest adapter, never `neotest-rust` beside it.
- **Git in nvim is three plugins with three jobs**: gitsigns for the hunk, lazygit in a snacks float for the porcelain (`configure = false`, so snacks never overlays its own theme on the versioned `lazygit/config.yml`), codediff for review.
- **Completion is `blink.cmp`, not `nvim-cmp`.** Old `cmp-nvim-lsp` / `cmp-buffer` / `cmp-path` docs don't apply.
- **Per-filetype conventions live in `autocmds.lua`**, not in global options: Go real tabs, PHP/Rust 4 spaces, markdown wrap+spell.
- **Selective format-on-save** (`conform.lua`): only go, rust, lua. The debatable ones use `<leader>cf`, to avoid fighting project styles.
- **`signcolumn = "yes"` always** — prevents the layout shift when a sign appears mid-edit. Not `"auto"`.
- **Removed on purpose, don't re-add without discussing it:** nvim-dap and its adapters, Neogit, `claudecode.nvim` (twice — the tmux popup is the only Claude entry point), nvim-ufo.

## Tool-specific gotchas

- **Ghostty config does NOT allow inline comments** (`key = val  # comment` breaks) — comments go on their own line. `audible-bell` is not a valid key; use `bell-features`.
- **`.ghostty` files have no macOS UTI**, so `⌘,` opens them in TextEdit. `install.sh` registers VS Code via `defaults write` on `LaunchServices`.
- **`bat` is aliased to `cat`** — `\cat` bypasses it when piping into something that chokes on bat output.
- **nvim `init.lua` order is load-bearing**: `options` → `keymaps` → `lazy` → `autocmds`. **`mapleader` must be set before `require("lazy")`**, or every plugin's `keys = {}` registers with an empty leader.
- **Caps Lock → Option lives in native macOS**, not the repo. Karabiner-Elements was tried and broke `<>` and `|°` on an ISO-LA layout — its virtual HID only supports generic `ansi`/`iso`/`jis`.

## Style and conventions

- **Comments explain WHY, not WHAT** — and this repo carries them densely on purpose. Terse, comment-free code is *less* in-style here than well-commented code. (The user-level `CLAUDE.md` defaults to no comment; this is the "a repo's own convention wins" case it names.)
- **English only** — comments, identifiers, commit messages and any prose that ships inside the repo, whatever language the session is in.
- **Section headers** use box-drawing: `# ─── name ───` in zsh/toml, `; ─── name ───` in `.gitconfig`.
- **Commit messages** are lowercase, prefixed `add:` / `feat:` / `fix:` / `chore:` / `refactor:` / `tweak:`, under 70 chars.
- **Colour palette** ("Anthropic Warm"): `#d97757` Claude orange, `#c8553d` terracotta, `#87a96b` olive, `#b08968` earth, `#d9a441` amber. Reuse these instead of inventing hex.

## Cross-references to other Claude state

The user's auto-memory (`~/.claude/projects/<path-id>/memory/`) holds durable preferences and project context — most relevantly the **Docker-only dev workflow**: host-side runtime managers have low ROI, runtimes live in Dockerfiles. Don't suggest uninstalling host node/npm; Claude Code itself is installed via global npm. When behaviour seems surprising, check those memories first.
