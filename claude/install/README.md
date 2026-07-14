# claude/install/ — how Claude Code is configured

Everything this repo does to `~/.claude/` lives here, split by **who writes to
`settings.json`**. That is the dividing line — not "what it installs", but who authors
the write, because that determines who handles idempotence and where to look when
something breaks.

The three files are **sourced** from the bash installers (`install.sh`,
`install-linux.sh` — both source all three); they are not standalone executables. They
assume `link()`, `$DOTFILES` and `$TS` from the parent, and that `jq` is already
installed (the installers run their deps block first).

| | File | Who writes to `settings.json` | Idempotence |
|---|---|---|---|
| **1** | `settings.sh` | **Us**, with `jq` | Our own guard: only if the key does not exist |
| **2** | `binaries.sh` | The **external binary**, in its setup command | Handled by the binary |
| **3** | `plugins.sh` | The **Claude Code CLI** (`claude plugin`) | Handled by the CLI |

**1 — `settings.sh`.** The only thing we write by hand: `statusLine`, `permissions.allow/deny`,
and the convergent cleanup of the obsolete `tmux-claude-session-manager` hooks. Additive-only,
with a guard: if the key already exists on that machine, it is not touched. It also symlinks the
two versioned pieces of `claude/` (`statusline.sh`, the user-level `CLAUDE.md`).

The permission lists themselves live in **`permissions.json`** — single source of truth, read here
with `jq --slurpfile` and by `install-windows.ps1` with `ConvertFrom-Json`. Adding a permission in
one script used to leave the other platform silently behind. The rationale for what is in and out
of each list is in that file's `_comment`.

**2 — `binaries.sh`.** You install the binary (brew / curl) and run *its* setup command, which is
the one that writes hooks, MCP servers and skills into `~/.claude/`. Today: `rtk` (a `PreToolUse`
hook that compresses Bash output) and `codebase-memory-mcp` (MCP server + hooks + the
`codebase-memory` skill).

**3 — `plugins.sh`.** One `marketplace add` + one `install` and the CLI does the rest (including
writing `extraKnownMarketplaces` / `enabledPlugins`). It is the cheapest way to add new skills or
hooks. Today: `ponytail` (6 bundled skills) and `andrej-karpathy-skills`.
Careful in the Windows port: the plugins block has to go **after** the script writes its
`settings.json`, or you clobber what the CLI just put there.

## To add something new

It exists as a marketplace plugin → mechanism 3, two lines in `plugins.sh`.
It is a standalone binary or MCP → mechanism 2. Mechanism 1 only when there is nobody
else to write it.

## Order

`settings.sh` → `binaries.sh` → `plugins.sh`, and it is load-bearing: `settings.sh` symlinks
`~/.claude/CLAUDE.md`, and `rtk init` (in `binaries.sh`) adds an `@RTK.md` line to it — we want
that write to land on the versioned file through the symlink, not on a loose one.

## What is NOT here

`settings.json` itself (per-machine, not versioned — see the repo's `CLAUDE.md`),
`~/.claude/skills/` (per-machine, a real dir), `~/.claude/projects/*/memory/` (Claude Code
handles it on its own).

`install-windows.ps1` **cannot** source these scripts (PowerShell), so it replicates the three
mechanisms by hand. If you change something here, check whether it applies there — it is the only
remaining copy, and nothing keeps it in sync automatically.
