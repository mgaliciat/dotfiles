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

  # ── rtk config.toml: COPIED, not symlinked ──
  # The only copy-instead-of-link in this repo, and the exception is earned. rtk
  # does a load → mutate → serialize round-trip on its config: `rtk telemetry
  # disable` alone rewrote the file, dropped every comment, and appended
  # `consent_date = "<ISO timestamp>"`. Through a symlink that lands in a PUBLIC
  # repo — the exact failure that keeps ~/.claude/settings.json unversioned. So
  # the repo file is the source of truth and this pushes it out; the installed
  # copy is disposable and expected to come back comment-stripped.
  #
  # Unconditional on every run (convergent): a `git pull` + ./install.sh realigns
  # a machine whose copy rtk has since rewritten. Losing rtk's consent fields is
  # deliberate and free — telemetry stays off, rtk regenerates them on demand,
  # and trusted-projects state lives in history.db, not here.
  #
  # WHY the values (raised caps, tee=always, diff/curl excluded): all of it is
  # commented in claude/install/rtk-config.toml. Short version — rtk's defaults
  # truncate hard, and truncation the agent can't see is worse than the tokens it
  # saves. Upstream: rtk-ai/rtk#827 (silent diff truncation, P0), #1313
  # (lossless mode, still open), #1282 (no isatty check → corrupts pipes).
  #
  # The path is the one OS branch in this file: rtk follows the platform
  # convention (macOS Application Support, XDG on Linux) and there is no env var
  # to flatten it. `rtk config` prints the resolved path if this ever drifts.
  if [[ "$OSTYPE" == darwin* ]]; then
    RTK_CFG="$HOME/Library/Application Support/rtk/config.toml"
  else
    RTK_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/rtk/config.toml"
  fi
  # Back up only a copy that actually diverges, matching link()'s contract: a
  # hand-tuned config on a fresh machine is not silently thrown away, but the
  # steady state (our file, possibly comment-stripped by rtk) does not spawn a
  # backup on every single run.
  if [[ -f "$RTK_CFG" ]] && ! cmp -s "$DOTFILES/claude/install/rtk-config.toml" "$RTK_CFG"; then
    cp "$RTK_CFG" "$RTK_CFG.backup.$TS"
    echo "→ backing up diverged $RTK_CFG to $RTK_CFG.backup.$TS"
  fi
  mkdir -p "$(dirname "$RTK_CFG")"
  cp "$DOTFILES/claude/install/rtk-config.toml" "$RTK_CFG"
  echo "✓ rtk config.toml installed (copy — rtk rewrites it, cannot be a symlink)"
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
if command -v claude >/dev/null 2>&1 && [[ -n "${CONTEXT7_API_KEY:-}" ]]; then
  if claude mcp get context7 >/dev/null 2>&1; then
    echo "✓ context7: already registered"
  elif claude mcp add --transport http context7 https://mcp.context7.com/mcp \
      --scope user --header "CONTEXT7_API_KEY: $CONTEXT7_API_KEY" >/dev/null 2>&1 </dev/null; then
    echo "✓ context7: MCP server registered (user scope)"
  else
    echo "⚠️  context7 registration failed — check by hand (claude mcp add ...)"
  fi
elif [[ -z "${CONTEXT7_API_KEY:-}" ]]; then
  echo "→ context7: skipped (no CONTEXT7_API_KEY — add it to ~/.zshenv.local)"
fi

# ─── gh-stack skill (stacked PRs) ─────────────────────────────
# Mechanism 2 with a twist: the external tool here is not a binary we install but
# `npx skills` (skills.sh / vercel-labs), which resolves the skill from a repo and
# writes it into ~/.claude/skills/ — same contract, it owns the file layout.
#
# The skill lives INSIDE github/gh-stack (skills/gh-stack/, + references/): it
# teaches the agent the stacked model and the `gh stack` commands. The extension
# itself is a separate install — `bootstrap_gh_stack` in scripts/lib.sh. Skill
# without extension is useless, so keep both or drop both.
#
# Every flag is load-bearing:
#   -g              global (~/.claude/skills) — a workflow tool for every repo,
#                   not a skill of the project the installer happens to run in
#                   (the CLI's default scope is the CURRENT project: the same
#                   `--scope user` trap as the MCP registrations above)
#   -a claude-code  only Claude Code; without it the CLI prompts per detected agent
#   -s gh-stack     the repo ships one skill, but naming it skips the picker
#   -y + npx -y     no prompts, and `</dev/null` on top: an installer that blocks
#                   on invisible stdin is the exact rtk footgun documented above
#
# Idempotence is OURS (the CLI re-downloads and re-copies on every `add`), so this
# guards on the destination dir. That also means it never updates: for that,
# `npx skills update gh-stack -g`.
if ! command -v npx >/dev/null 2>&1; then
  # An explicit skip, not a silent one: node is not in any of our package lists,
  # so on a fresh Linux box this is the common path and a mute installer would
  # look like it installed the skill.
  echo "→ gh-stack skill: skipped (no npx — install Node.js and re-run)"
elif [[ ! -e "$HOME/.claude/skills/gh-stack" ]]; then
  echo ""
  echo "→ Installing the gh-stack skill (npx skills)"
  if npx -y skills@latest add https://github.com/github/gh-stack \
       -s gh-stack -a claude-code -g -y >/dev/null 2>&1 </dev/null; then
    echo "✓ gh-stack skill installed (~/.claude/skills/gh-stack)"
  else
    echo "⚠️  gh-stack skill failed — by hand: npx skills add https://github.com/github/gh-stack -s gh-stack -a claude-code -g -y"
  fi
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
