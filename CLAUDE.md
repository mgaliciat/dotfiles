# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Personal dotfiles for macOS (Ghostty + Homebrew), with a portable subset for Linux/WSL2 (zsh, nvim, lazygit, git) and a deliberately narrow native-Windows entry point. **The repo is public.**

## Commands

- `./install.sh` — macOS. Idempotent; backs up existing files (`.backup.<timestamp>`) before symlinking.
- `./install-linux.sh` — Ubuntu/Debian/WSL2. Portable subset, no ghostty.
- `./install-windows.ps1` — native Windows. Needs Developer Mode for symlinks.
- `exec zsh` after editing `zsh/`.
- `Cmd+Shift+R` in Ghostty after editing `ghostty/` — it does not watch its config.

No build and no test suite. CI (`.github/workflows/lint.yml`, read-only token, actions
pinned to SHAs) runs static checks only:

- syntax: shellcheck + `bash -n` over every bash script, `zsh -n` over every file in
  `zsh/`, `luac5.1 -p` over every nvim lua file, `jq empty` over the JSON, the
  `claude/hooks/*.py` parsed against the 3.9 grammar (the Mac's `/usr/bin/python3`),
  and the PowerShell parser plus PSScriptAnalyzer at Error severity over the three
  `.ps1` files;
- the pairs kept in sync by hand: `scripts/theme` bare (the two selection lines agree),
  every `ghostty/themes/<id>` has its nvim half and the reverse (`solarized-osaka`'s is
  `nvim/lua/plugins/solarized-osaka.lua`), every key `settings.sh` sets is mentioned in
  `install-windows.ps1`, the two logbook manifests agree on name/version/description/
  author, and `logbook.sh` and `logbook.ps1` hand the model the same reminder (the `.sh`
  em dash folded to the `.ps1`'s ASCII `-`);
- one smoke test, for `no-bash-edits.py`, which fails open by design.

The nvim config is deliberately not loaded (it needs its plugins). Runtime validation is
running the installer.

## Layout

| Path | What |
|---|---|
| `zsh/` | `.zshrc` (interactive), `.zshenv` (env), `path.zsh` (PATH, sourced by `.zshenv` and again by `.zprofile` after macOS's `path_helper`), `functions.zsh` |
| `ghostty/` | `config.ghostty` + `themes/` |
| `nvim/` | lazy.nvim, `lua/plugins/*` one file per plugin, `lua/themes/*` |
| `claude/` | User-level Claude Code: `CLAUDE.md`, `statusline.{sh,ps1}`, `themes/`, `hooks/`, `install/` |
| `plugins/` | Plugins shared by Claude Code and Antigravity. `logbook/` carries two manifests (`.claude-plugin/plugin.json`, `plugin.json`), `skills/`, `rules/`, `hooks/` |
| `scripts/` | `lib.sh` (shared by both bash installers), `claude-api-env`, `theme` |
| `runbook/` | Operator bring-up per OS |

`README.md` is the map of the repo; this file is the rationale.

## Architecture

### Shared installer core

`scripts/lib.sh` holds what both bash installers use: `link()`, `link_portable()` (the
portable symlink list — adding a file is one edit, not one per installer),
`install_claude()`, `bootstrap_gh_stack()`. `install-windows.ps1`
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

One theme id spanning Ghostty + nvim, plus Windows Terminal as an independent
third layer. Selection is a direct versioned value in each config:

- `theme = <id>` in `ghostty/config.ghostty`
- `vim.g.theme = "<id>"` in `nvim/lua/config/options.lua`
- `$WtTheme` in `install-windows.ps1` (generated from `ghostty/themes/<id>` at install time)
- `theme = "custom:<id>"` in `~/.claude/settings.json`, written by `settings.sh` from
  ghostty's `theme =` line whenever `claude/themes/<id>.json` exists (convergent, the one
  settings key that is), pointing at that Claude Code custom theme

`scripts/theme <id>` (on PATH as `theme`) rewrites the first two lines, regenerates
lazygit's `theme:` block from the ghostty palette, and reports a pinned
`background =`/`foreground =` in `config.ghostty` rather than touching it. It leaves
`$WtTheme` alone on purpose: Windows is independent. CI runs it bare, which fails when
the two selection lines disagree.

Adding a theme = its two definitions (`ghostty/themes/<id>`,
`nvim/lua/themes/<id>.lua`). The nvim module wraps its spec in
`require("themes._base")`, which maps the palette onto tokyonight's slots and paints
the fixed-role groups (cursorline, floats, telescope frame, gitsigns, markdown code);
the module passes only what that theme does differently — its own `on_colors` /
`on_highlights`, which run after the shared ones, and an optional `code` table for
markdown code colours. The spec is documented in `_base.lua`'s header. The one
exception is `solarized-osaka`: no `nvim/lua/themes/` module, it is rendered by its own
plugin (`nvim/lua/plugins/solarized-osaka.lua`), and `scripts/theme` accepts that id by
name. Provenance of each palette is in
`ghostty/themes/README.md`. The Claude Code theme is optional and exists for a canvas
the brand colours cannot read on, or for a theme whose accent should carry into the TUI
(`dia-de-muertos`): `base: light-ansi`/`dark-ansi` makes the TUI take its colours from the
terminal's ANSI slots, and `overrides.claude` re-tunes the spinner. A Ghostty shader is
optional the same way: `ghostty/shaders/<id>.glsl` belongs to theme `<id>`, and
`scripts/theme` uncomments its `custom-shader` line on selecting it and comments it out
on selecting anything else (`blueprint`). A shader not named after a theme (`crt`) is
left alone.

### The per-machine split

Some things are versioned, some deliberately are not:

| Versioned | Per-machine |
|---|---|
| `zsh/.zshrc` | `~/.zshrc.local` (sourced last) |
| `zsh/.zshenv` | `~/.zshenv.local` (sourced last) |
| `zsh/.zprofile` | `~/.zprofile.local` (sourced last) |
| `ghostty/config.ghostty` | `~/.config/ghostty/config.local` (`config-file`, wins) |
| `git/.gitignore_global` | `~/.gitconfig` (not symlinked at all) |
| `claude/CLAUDE.md` | `~/.claude/settings.json` |
| `claude/install/*` | `~/.claude/skills/`, `~/.claude/projects/*/memory/` |
