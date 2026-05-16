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
|                             | `claude/memory/` (untracked)                 |
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

## Tool-specific gotchas

- **Ghostty config does NOT allow inline comments** on the same line as a value (`key = val  # comment` breaks). Comments go on their own line.
- **Starship `$` is a variable sigil.** A literal `$` in a format string needs `\$` (in TOML double-quoted, write `\\$`). Same for `[` and `]` → `\\[`, `\\]`.
- **`.ghostty` files have no macOS UTI**, so without intervention `⌘,` opens them in TextEdit. `install.sh` registers VS Code via `defaults write` on `LaunchServices`; the block is idempotent (checks before writing).
- **`bat` is aliased to `cat`** — `\cat` invokes the real one when bypassing aliases is needed (e.g., for piping into tools that choke on bat output).

## Cross-references to other Claude state

The user's auto-memory (`~/.claude/projects/-Users-m-galicia/memory/`) — which is symlinked from `claude/memory/` when present — contains durable preferences and project context. Two memories particularly relevant here:

- **Docker-only dev workflow** — host-side runtime managers (mise, nvm, pyenv outside Docker) have low ROI. Runtimes live in Dockerfiles. Don't suggest uninstalling host node/npm — Claude Code itself is installed via global npm.
- **Ghostty config gotchas** — already encoded above (no inline comments; `audible-bell` is not a valid key — use `bell-features`).

When suggesting changes, check those memories first if behavior seems surprising.
