<p align="center">
  <img src="assets/dotfiles-icon-paper.svg" alt="dotfiles" width="128">
</p>

<h1 align="center">dotfiles</h1>

Personal config for macOS — Ghostty terminal, zsh, Starship prompt, Neovim, tmux, lazygit.

## What's here

| Path | What |
|---|---|
| `zsh/.zshrc` | Interactive shell config (no Oh My Zsh — startup ~60ms) |
| `zsh/.zshenv` | Env vars and PATH, loaded for all shells |
| `starship/starship.toml` | Starship prompt config |
| `ghostty/config.ghostty` | Ghostty terminal config — theme, fonts, keybinds |
| `git/.gitignore_global` | Global gitignore — macOS noise, editor files, build dirs, **and AI-agent scratch** (`.claude/`, `.cursor/`, `.aider*`, `.covenant/`, etc.), deliberately excluded in every repo |
| `nvim/` | Neovim config — lazy.nvim, modular `lua/plugins/*`; the active theme is `vim.g.theme` in `lua/config/options.lua` (currently `solarized-osaka`, part of the cross-stack Ghostty+nvim+tmux theme). Cheatsheets: `NVIM-CHEATSHEET.md` (root) has the most up-to-date plugin coverage; `nvim/CHEATSHEET.md` goes deeper on native vim/LSP but is missing plugins |
| `tmux/` | tmux config — prefix `C-t`, popups Alt+c/C/y/u/d/g/Enter, modular (theme/statusline/utility). Cheatsheet in `tmux/CHEATSHEET.md` |
| `lazygit/config.yml` | lazygit theme + custom commands |
| `scripts/` | Helpers — `ide` (4-pane IDE-style tmux layout, `prefix + g`), `lib.sh` (shared by both bash installers) |
| `claude/` | User-level Claude Code config — `CLAUDE.md` (→ `~/.claude/CLAUDE.md`), `statusline.sh`, and `install/` (everything the installers do to `~/.claude/`, split by mechanism — see its README). `settings.json`, `skills/` and `memory/` are **per-machine**: neither versioned nor symlinked |
| `install.sh` | macOS entry point — symlinks + dependency auto-install |
| `install-linux.sh` | Portable subset for Ubuntu/Debian/WSL2 |
| `install-windows.ps1` | Native Windows (no WSL2) — narrow scope, Claude Code pieces only (see the comment in the script) |

## Setup on a new machine

Prerequisite: **Homebrew**. If you don't have it:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then:

```bash
git clone https://github.com/mgaliciat/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` takes care of:

1. Symlinking configs (`.zshrc`, `.zshenv`, `.gitignore_global`, ghostty, starship, nvim, tmux, lazygit, `claude/CLAUDE.md`, `claude/statusline.sh`)
2. Auto-installing missing dependencies via Homebrew:
   - **Formulae**: `starship`, `zsh-syntax-highlighting`, `zsh-autosuggestions`, `zsh-history-substring-search`, `eza`, `bat`, `fd`, `ripgrep`, `gomi`, `zoxide`, `fzf`, `jq`, `git-delta`, `pyenv`, `neovim`, `tree-sitter-cli`, `tmux`, `lazygit`, `rtk`
   - **Casks**: `ghostty`, `font-plemol-jp-nf`, `font-ia-writer-mono`, `font-monaspace`
3. Configuring Claude Code (all idempotent and **additive-only**: anything you set up by hand on that machine is never clobbered):
   - `statusLine` + base `permissions` in the real `settings.json` (which is NOT versioned)
   - [`rtk`](https://github.com/rtk-ai/rtk) — proxy CLI that rewrites Bash commands into a compressed equivalent to save tokens. Transparent, via a `PreToolUse` hook
   - [`codebase-memory-mcp`](https://github.com/DeusData/codebase-memory-mcp) — MCP server that indexes the code into a queryable graph
   - Plugins [`ponytail`](https://github.com/DietrichGebert/ponytail) (lazy senior dev) and [`andrej-karpathy-skills`](https://github.com/multica-ai/andrej-karpathy-skills) (guidelines)
4. Cloning tpm (Tmux Plugin Manager) if missing
5. Reloading the tmux config if a server is running
6. Registering VS Code as the default app for `.ghostty` (if VS Code is installed)

**`~/.gitconfig` is neither versioned nor symlinked** — each machine keeps its own (credentials, 1Password vaults, signing keys are per-machine). On a new Mac, copy your `.gitconfig` from wherever you backed it up.

**Caps Lock → Option** is set in System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys (not versioned, it's per-device).

## Sync an existing machine

After a `git pull` on an already-configured Mac, the files are up to date through the symlinks, **but tools already running still hold the old config in memory**. To apply:

| Changed tool | How to apply |
|---|---|
| `zsh/*` | `exec zsh` in every open terminal |
| `starship/*` | Automatic — re-read on every prompt |
| `ghostty/*` | `Cmd+Shift+R` reloads most settings. **For new `keybind`s: full quit (`Cmd+Q`) + relaunch** — the reload doesn't always pick them up |
| `tmux/*` | `./install.sh` already does it; or manually: `tmux source ~/.config/tmux/tmux.conf` |
| `nvim/*` | Restart nvim (or `:Lazy reload <plugin>` for a single plugin) |
| `lazygit/*` | Close and reopen lazygit |

Shortcut: running `./install.sh` after the pull is idempotent and applies whatever can be applied without restarting GUI processes.

## macOS tweaks

`install.sh` also registers **VS Code** as the default app for `.ghostty` files (without this, `⌘,` inside Ghostty opens `config.ghostty` in TextEdit, because the extension has no UTI registered in macOS). Done via `defaults write` on `com.apple.LaunchServices` plus a DB rebuild. Idempotent.

## Per-machine config (not versioned)

- **`~/.gitconfig.local`** — git identity (`user.name`, `user.email`, signing key). Created by hand; your `~/.gitconfig` (also unversioned) includes it via `[include]` at the end, so it wins over any default.
- **`~/.zshenv.local`** — secrets (DB passwords, API keys). Created manually:

```sh
# ~/.zshenv.local — never commit
export PG_PASSWORD="..."
export REDASH_API_KEY="..."
```

`.zshenv` automatically sources `.zshenv.local` if present.

- **`~/.claude/settings.json`**, **`~/.claude/skills/`**, **`~/.claude/projects/*/memory/`** — Claude Code state. Neither versioned nor symlinked: permissions/UI diverge per host, and the skills and memories are written by Claude Code and its binaries at runtime. `install.sh` only does targeted, additive-only merges into `settings.json` (statusLine, base permissions, rtk/codebase-memory hooks) — it never overwrites the whole file. If you delete `~/.claude` entirely, re-running `./install.sh` rebuilds what the binaries and plugins install (MCP config + hooks + the `codebase-memory` skill, ponytail's skills); what does NOT come back are your permissions and memories — those don't live in the repo.
