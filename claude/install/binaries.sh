# shellcheck shell=bash
# ─── Claude Code: external binaries that self-register ───
#
# Mechanism 2 of 3 (see claude/install/README.md). We install the binary and run
# ITS setup command — the binary writes into ~/.claude/ (hooks, MCP server,
# skills) and handles its own idempotence. We do not touch settings.json here;
# that is mechanism 1 (settings.sh).
#
# Sourced by install.sh and install-linux.sh — NOT a standalone executable.
# It goes AFTER settings.sh: that one symlinks ~/.claude/CLAUDE.md, and `rtk init`
# adds an @RTK.md line to it — we want that to land on the versioned file.

# ─── rtk (token-reducing proxy CLI) ───────────────────────────
# Adds a PreToolUse hook (matcher Bash → "rtk hook claude") that rewrites common
# commands (git status, cargo test, npm test...) to their rtk equivalent, with
# filtered/compressed output: fewer context tokens. It also creates
# ~/.claude/RTK.md (command reference, per-machine, not versioned).
#
# On mac the binary already comes from Homebrew (REQUIRED_FORMULAE); on Linux
# there is no formula, so it falls back to the official curl installer. The
# `command -v` guard unifies both cases: if brew already put it there, the curl
# is not even attempted.
#
# `</dev/null` is NOT cosmetic: without it the command hung in a real terminal
# waiting for an invisible interactive prompt (probably the trust prompt for
# filters.toml). --auto-patch only avoids the "patch settings.json?" prompt, not
# that other one. Closed stdin → EOF → the command continues with its default.
# Doc: https://github.com/rtk-ai/rtk
if ! command -v rtk >/dev/null 2>&1; then
  echo ""
  echo "→ Installing rtk (official curl installer)"
  curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh \
    || echo "⚠️  rtk install failed"
fi

if command -v rtk >/dev/null 2>&1; then
  # Idempotence: handled by rtk itself (verified by running it twice — the second
  # run detects the existing hook and does not duplicate it), not by our jq.
  if rtk init --global --auto-patch >/dev/null 2>&1 </dev/null; then
    echo "✓ rtk Claude Code hook configured (or already there)"
  else
    echo "⚠️  rtk init --global failed — check by hand (rtk init --global -v)"
  fi
fi

# ─── codebase-memory-mcp (code graph MCP server) ──────────────
# Indexes the codebase into a persistent graph — 14 tools (search_graph,
# trace_path, get_architecture...), 158 languages via tree-sitter. No Homebrew
# formula, so it goes through the project's official install.sh on both
# platforms. Variant WITHOUT --ui (headless, the installer's own default): the
# consumer is the agent via MCP tools, not a human browsing the 3D graph on
# localhost:9749 — that way it does not open an extra local HTTP port.
# Doc: https://github.com/DeusData/codebase-memory-mcp
#
# The binary weighs ~260MB: we only download it if it is missing.
if ! command -v codebase-memory-mcp >/dev/null 2>&1; then
  echo ""
  echo "→ Installing codebase-memory-mcp"
  curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash \
    || echo "⚠️  codebase-memory-mcp install failed"
fi

# `install -y` runs ALWAYS — with no guard, and that is load-bearing. It is the
# command that writes ALL the state into ~/.claude/: MCP server + hooks
# (PreToolUse on Grep/Glob, SessionStart, SubagentStart) for every detected
# agent, and the `codebase-memory` skill in ~/.claude/skills/. If it lives under
# the binary's guard (that is, implicitly inside the curl above), a ~/.claude
# deleted by hand is NEVER rebuilt: the binary is still in PATH → guard false →
# zero re-registration, and ./install.sh appears to run fine. The state of the
# binary and the state of ~/.claude are independent. If you see the
# `codebase-memory` skill missing again after an install.sh, someone put this
# back inside the `if`.
# It is idempotent (verified with --dry-run: it detects the existing config and
# does not duplicate it).
if command -v codebase-memory-mcp >/dev/null 2>&1; then
  codebase-memory-mcp install -y >/dev/null 2>&1 \
    && echo "✓ codebase-memory-mcp: MCP server + hooks + skill registered" \
    || echo "⚠️  codebase-memory-mcp install -y failed"
  # auto_index: cheap and idempotent, forced on every run so new projects index
  # themselves on connect.
  codebase-memory-mcp config set auto_index true >/dev/null 2>&1
  echo "✓ codebase-memory-mcp: auto_index=true"
fi

# ─── context7 (up-to-date library docs MCP) ───────────────────
# Hosted HTTP server — nothing to install, no binary, no local port: we only
# register the endpoint. It injects current docs for the library you are using,
# which is what kills the "invented API signature" failure on libs the model
# knows poorly. Doc: https://github.com/upstash/context7
#
# The key is read from the ENVIRONMENT, never from the repo: it lives in
# ~/.zshenv.local (per-machine secrets, gitignored) and this repo is PUBLIC.
# Hence the guard: a machine with no key simply skips this — install.sh must not
# fail there. Do NOT "helpfully" default the key to an empty string; that
# registers the server with a broken header and it fails at call time, which is
# much harder to diagnose than a server that is plainly absent.
#
# `--scope user` is load-bearing: the CLI default is `local`, which scopes the
# server to the CURRENT directory's project entry in ~/.claude.json — it would
# work while running install.sh from the dotfiles repo and be invisible from
# every other project. `user` is the one that means "all projects".
#
# The registration lands in ~/.claude.json (per-machine, not versioned, not
# symlinked — same treatment as settings.json), so the key never reaches git.
#
# NOTE the upstream install path is `npx ctx7 setup`, which we deliberately do
# NOT use: it does interactive OAuth, and an installer that blocks on a browser
# prompt is the `</dev/null` footgun all over again — except here there is no
# default to fall through to. Registering the endpoint by hand is equivalent.
#
# Idempotence is ours: `claude mcp add` errors out if the name already exists.
# Guarding on absence also means a ROTATED key is not picked up by a re-run —
# for that, `claude mcp remove context7 -s user` first, then re-run install.sh.
if command -v claude >/dev/null 2>&1 && [[ -n "$CONTEXT7_API_KEY" ]]; then
  if claude mcp get context7 >/dev/null 2>&1; then
    echo "✓ context7: already registered"
  elif claude mcp add --transport http context7 https://mcp.context7.com/mcp \
      --scope user --header "CONTEXT7_API_KEY: $CONTEXT7_API_KEY" >/dev/null 2>&1 </dev/null; then
    echo "✓ context7: MCP server registered (user scope)"
  else
    echo "⚠️  context7 registration failed — check by hand (claude mcp add ...)"
  fi
elif [[ -z "$CONTEXT7_API_KEY" ]]; then
  echo "→ context7: skipped (no CONTEXT7_API_KEY — add it to ~/.zshenv.local)"
fi

# ─── obsidian (Local REST API MCP — cross-repo markdown notes) ─
# Same shape as context7: a hosted-style HTTP endpoint we only register — no
# binary, nothing to install here. The server is not ours: it is the "Local REST
# API" Obsidian community plugin, which since 2026 ships its OWN MCP server at
# /mcp/ (no external Python/uvx process). The vault is a per-machine local dir
# (deliberately NOT versioned — same reasoning as ~/.claude/skills/); this block
# only wires Claude Code to it so notes written in one repo are readable from any
# other. Doc: https://github.com/coddingtonbear/obsidian-local-rest-api
#
# HTTP (27123), not HTTPS (27124): the plugin's default is HTTPS with a
# SELF-SIGNED cert, which Node/Claude Code rejects unless you trust the cert by
# hand. On loopback the non-encrypted port loses nothing and dodges that entirely
# — but it must be enabled in the plugin ("Enable Non-encrypted (HTTP) Server").
#
# The key is per-machine and read from the ENVIRONMENT (~/.zshenv.local,
# gitignored) — never the repo (PUBLIC). Same guard/scope logic as context7:
#  - no key → skip cleanly (install.sh must not fail on a machine without it);
#  - `--scope user` = all projects (CLI default `local` would bind it to the
#    dotfiles dir and be invisible elsewhere — the whole point is cross-repo);
#  - idempotence is ours (`claude mcp add` errors if the name exists), so a
#    ROTATED key needs `claude mcp remove obsidian -s user` before a re-run.
#
# Registration is decoupled from Obsidian being up: this only stores a URL, so it
# succeeds even with Obsidian closed. But the tools only WORK when Obsidian is
# open with the plugin + its MCP server enabled — that is the runtime cost of the
# "real Obsidian" path (Dataview, atomic patch by heading) vs plain filesystem.
if command -v claude >/dev/null 2>&1 && [[ -n "$OBSIDIAN_API_KEY" ]]; then
  # Strip a leading "Bearer " if present: the plugin's "copy" button hands you
  # `Bearer <hex>`, and pasting that verbatim into the env var yields a doubled
  # `Authorization: Bearer Bearer <hex>` → silent 401. The key is the bare hex.
  OBSIDIAN_KEY="${OBSIDIAN_API_KEY#Bearer }"
  if claude mcp get obsidian >/dev/null 2>&1; then
    echo "✓ obsidian: already registered"
  elif claude mcp add --transport http obsidian http://127.0.0.1:27123/mcp/ \
      --scope user --header "Authorization: Bearer $OBSIDIAN_KEY" >/dev/null 2>&1 </dev/null; then
    echo "✓ obsidian: MCP server registered (user scope)"
  else
    echo "⚠️  obsidian registration failed — check by hand (claude mcp add ...)"
  fi
elif [[ -z "$OBSIDIAN_API_KEY" ]]; then
  echo "→ obsidian: skipped (no OBSIDIAN_API_KEY — add it to ~/.zshenv.local)"
fi

# ── convergent cleanup: the line the binary puts in ~/.zshrc ──
# The binary (src/cli/cli.c, cbm_detect_shell_rc) does its own
# fopen(~/.zshrc, "a") and appends `export PATH=...` if it does not find an exact
# TEXTUAL match. Our PATH lives in zsh/.zshenv with `$HOME` (not the expanded
# absolute path), so that naive check never recognizes it and it always re-adds
# its line, with THIS machine's path hardcoded. Since ~/.zshrc is a symlink into
# the repo, that dirties the VERSIONED file — and since `install -y` runs on
# every run, it comes back every time. It goes AFTER the install -y: the other
# way around, the binary would dirty the file again and `git status` would be
# dirty after every run.
#
# Two details that are NOT cosmetic (both used to break silently):
#  - The binary writes THREE lines: a BLANK one, the marker, and the export. A
#    `skip = 2` from the marker leaves the blank one orphaned and the diff still
#    showed a `+`. The awk defers the blanks (pending) and drops them if what
#    follows is the marker.
#  - It writes with `cat >`, NEVER with `mv`: ~/.zshrc is a SYMLINK into the repo.
#    `mv` replaces the symlink with a regular file (it breaks the dotfile AND
#    leaves the dirty line intact in the repo — you wrote next to it, not into
#    it). The redirection follows the symlink and cleans the real file. That is
#    the difference with settings.sh, where mktemp + mv IS correct because
#    settings.json is a real file.
ZSHRC="$HOME/.zshrc"
if [[ -f "$ZSHRC" ]] && grep -qF "# Added by codebase-memory-mcp install" "$ZSHRC"; then
  ZSHRC_TMP="$(mktemp)"
  if awk '
    /^# Added by codebase-memory-mcp install$/ { skip = 2; pending = 0; next }
    skip > 0 { skip--; next }
    /^$/ { pending++; next }
    { while (pending-- > 0) print ""; pending = 0; print }
    END { while (pending-- > 0) print "" }
  ' "$ZSHRC" > "$ZSHRC_TMP"; then
    cat "$ZSHRC_TMP" > "$ZSHRC"
    rm -f "$ZSHRC_TMP"
    echo "✓ PATH line that codebase-memory-mcp added to .zshrc cleaned up (already covered by .zshenv)"
  else
    rm -f "$ZSHRC_TMP"
    echo "⚠️  could not clean .zshrc — check by hand"
  fi
fi
