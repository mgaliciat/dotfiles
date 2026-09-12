# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Personal dotfiles for macOS (Ghostty + Homebrew), with a portable subset for Linux/WSL2 (zsh, nvim, tmux, lazygit, git) and a deliberately narrow native-Windows entry point. **The repo is public.**

## Commands

- `./install.sh` — macOS. Idempotent; backs up existing files (`.backup.<timestamp>`) before symlinking.
- `./install-linux.sh` — Ubuntu/Debian/WSL2. Portable subset, no ghostty.
- `./install-windows.ps1` — native Windows. Needs Developer Mode for symlinks.
- `exec zsh` after editing `zsh/`.
- `Cmd+Shift+R` in Ghostty after editing `ghostty/` — it does not watch its config.
- `prefix + r` (prefix is `C-t`) after editing `tmux/`.

No build and no test suite. CI (`.github/workflows/lint.yml`) runs static checks only:
shellcheck + `bash -n` over the installers and `claude/install/*.sh`, `zsh -n` over the
zsh files, `luac5.1 -p` over every nvim lua file, `jq empty` over the JSON, and a
PowerShell parse of `install-windows.ps1`. tmux and nvim configs are deliberately not
parsed (they need their plugins to load). Runtime validation is running the installer.

## Layout

| Path | What |
|---|---|
| `zsh/` | `.zshrc` (interactive), `.zshenv` (env + PATH), `functions.zsh` |
| `ghostty/` | `config.ghostty` + `themes/` |
| `nvim/` | lazy.nvim, `lua/plugins/*` one file per plugin, `lua/themes/*` |
| `tmux/` | `tmux.conf` + `macos.conf` / `theme.conf` / `statusline.conf` / `utility.conf` / `themes/` |
| `claude/` | User-level Claude Code: `CLAUDE.md`, `statusline.{sh,ps1}`, `hooks/`, `agents/`, `skills/`, `install/` |
| `scripts/` | `lib.sh` (shared by both bash installers), `ide`, `claude-api-env` |
| `runbook/` | Operator bring-up per OS |

`README.md` is the map of the repo; this file is the rationale.

## Architecture

### Shared installer core

`scripts/lib.sh` holds what both bash installers use: `link()`, `link_portable()` (the
portable symlink list — adding a file is one edit, not one per installer),
`install_claude()`, `bootstrap_gh_stack()`, `bootstrap_tmux()`. `install-windows.ps1`
replicates the Claude Code parts by hand; PowerShell cannot source bash.

### Claude Code config: three mechanisms

`claude/install/` is split by **who writes `settings.json`**:

| | File | Who writes | Idempotency |
|---|---|---|---|
| 1 | `settings.sh` | We do, with `jq` | Our guard |
| 2 | `binaries.sh` | The external binary | The binary |
| 3 | `plugins.sh` | The `claude plugin` CLI | The CLI |

Sourced in that fixed order by `install_claude`. `permissions.json` is the single source
of truth for permissions, read by `settings.sh` with `jq --slurpfile` and by
`install-windows.ps1` with `ConvertFrom-Json`.

### The stack theme

One theme id spanning Ghostty + nvim + tmux, plus Windows Terminal as an independent
fourth layer. Selection is a direct versioned value in each config:

- `theme = <id>` in `ghostty/config.ghostty`
- `vim.g.theme = "<id>"` in `nvim/lua/config/options.lua`
- `source ~/.config/tmux/themes/<id>.conf` in `tmux/tmux.conf`
- `$WtTheme` in `install-windows.ps1` (generated from `ghostty/themes/<id>` at install time)

Adding a theme = its three definitions (`ghostty/themes/<id>`,
`nvim/lua/themes/<id>.lua`, `tmux/themes/<id>.conf`). Provenance of each palette is in
`ghostty/themes/README.md`.

### The per-machine split

Some things are versioned, some deliberately are not:

| Versioned | Per-machine |
|---|---|
| `zsh/.zshrc` | `~/.zshrc.local` (sourced last) |
| `zsh/.zshenv` | `~/.zshenv.local` (sourced last) |
| `git/.gitignore_global` | `~/.gitconfig` (not symlinked at all) |
| `claude/CLAUDE.md` | `~/.claude/settings.json` |
| `claude/install/*` | `~/.claude/skills/`, `~/.claude/projects/*/memory/` |
