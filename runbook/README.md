# Runbooks

Step-by-step procedures to bring a machine up on these dotfiles and keep it in
sync. One file per operating system, written to be followed top to bottom on a
box that has nothing yet.

This folder is the *how*. The *why* behind every non-obvious line lives in the
repo's [`CLAUDE.md`](../CLAUDE.md); the map of what is in the repo is the root
[`README.md`](../README.md). When a runbook and `CLAUDE.md` disagree, `CLAUDE.md`
wins and the runbook has drifted — fix the runbook.

| Machine | Runbook | Entry point |
|---|---|---|
| macOS (Ghostty + Homebrew) | [`macos.md`](macos.md) | `./install.sh` |
| Ubuntu / Debian / WSL2 | [`linux-wsl2.md`](linux-wsl2.md) | `./install-linux.sh` |
| Native Windows (no WSL2) | [`windows.md`](windows.md) | `./install-windows.ps1` |

A WSL2 box is **two** runbooks: `linux-wsl2.md` inside the distro for the shell
stack, and `windows.md` on the Windows side for the fonts and the Windows
Terminal theme — nothing inside WSL can install a font the terminal can see.

## Before any installer — what the repo cannot bring

The repo holds the shared layer. Everything below is per-machine, never
versioned, and either you create it or that machine goes without it. The
installers do not create any of these.

| File | Holds | Who reads it |
|---|---|---|
| `~/.gitconfig` + `~/.gitconfig.local` | git identity, signing key, 1Password vault | git |
| `~/.zshenv.local` | secrets and tokens as `export` lines (`CONTEXT7_API_KEY`, `OPENKNOWLEDGE_MCP_URL`, `OPENKNOWLEDGE_CF_ACCESS_CLIENT_ID`, `OPENKNOWLEDGE_CF_ACCESS_CLIENT_SECRET`) | every zsh, and the installers |
| `~/.zshrc.local` | aliases and functions for this machine only | interactive zsh |
| `~/.claude/claude-api.env` | the API-gateway credential (`ANTHROPIC_BASE_URL=…`, `chmod 600`) | `claude --api`, `code --api`, tmux `Alt+a` |
| `~/.claude/settings.json` | Claude Code permissions and UI prefs | Claude Code; the installers only add keys that are absent |

On native Windows the shell files do not exist; the secrets are Windows user
environment variables set with `setx` (see `windows.md`).

**Order matters on a fresh machine.** Two guards in the installers skip
silently when their input is missing, and a second run is the only fix:

1. **Install Claude Code first.** Every MCP registration (`context7`,
   `open-knowledge`) is guarded on `claude` being on PATH. No binary, no
   registration, no error.
2. **Write the secrets first.** The same registrations are guarded on their env
   vars. A missing var prints a `→ skipped` line and moves on. On mac/Linux that
   means `~/.zshenv.local` exists *and* has been sourced in the shell that runs
   the installer (`exec zsh`, or a new terminal).

Neither is a failure of the installer — re-running it once the inputs exist
converges. It is simply cheaper to do it in one pass.

## Reading installer output

The bash installers use `set -euo pipefail` but wrap every network step in
`|| echo "⚠️ …"`, so they finish even when a download fails. Read the markers:

- `✓` — done, or already in place.
- `→` — an action was taken (a symlink, a download, a backup).
- `⚠️` — that one step failed and the script **kept going**. Each `⚠️` line
  names the tool and usually the manual fallback. Scroll back for them; the
  final "Done" does not mean every step succeeded.

Anything the installer would overwrite is moved aside as
`<file>.backup.<YYYYMMDD_HHMMSS>` first. To undo a symlink, delete it and move
the backup back.

## After every `git pull`

Symlinked files are already current. Re-run the installer anyway — it is
idempotent and it is what delivers new symlinks, new packages, new
`settings.json` keys and the pinned tmux plugin. Then reload what is still
holding the old config in memory:

| Changed | Apply with |
|---|---|
| `zsh/*` | `exec zsh` in each open terminal |
| `ghostty/*` | `Cmd+Shift+R` in a Ghostty window. New `keybind` lines need a full quit and relaunch |
| `tmux/*` | the installer reloads a running server; or `tmux source ~/.config/tmux/tmux.conf` |
| `nvim/*` | restart nvim |
| `lazygit/*` | reopen lazygit |
| `claude/*`, `install*` | the installer; then restart Claude Code |
