# shellcheck shell=bash
# ─── Claude Code: external binaries that self-register ───
#
# Mechanism 2 of 3 (see claude/install/README.md). We install the binary and run
# ITS setup command — the binary writes into ~/.claude/ (hooks, MCP server,
# skills) and handles its own idempotence. We do not touch settings.json here;
# that is mechanism 1 (settings.sh).
#
# Sourced by install.sh and install-linux.sh — NOT a standalone executable.
# It goes AFTER settings.sh, whose `$SETTINGS` and `_settings_*` helpers it uses.
#
# `</dev/null` on a setup command is NOT cosmetic: run from a real terminal,
# a CLI that wants to ask something hangs on a prompt nobody sees (the
# installer silences its output). Closed stdin → EOF → it takes its default.

# ─── rtk: retired, and uninstalled ────────────────────────────
# rtk (rtk-ai/rtk) used to live here: a PreToolUse hook on Bash that rewrote
# common commands to their rtk equivalent with compressed output, plus a
# versioned config.toml copied to the per-OS path. It is no longer installed,
# and this block takes it back off a machine that had it. Convergent and
# silent once there is nothing left to remove.
#
# rtk's own `init --global --uninstall` goes first, while the binary is still
# there to run it: it knows every artefact it wrote (the `rtk hook claude`
# entry, the legacy ~/.claude/hooks/rtk-rewrite.sh and its hash sidecar,
# ~/.claude/RTK.md and the @RTK.md import, its Cursor/OpenCode hooks). It only
# writes ~/.claude/CLAUDE.md (a symlink into this repo) when that file carries
# an @RTK.md line, which the versioned one never did.
#
# Everything after it does not need the binary, so a run where it is already
# gone (brew uninstalled it by hand, a second run) still converges: the jq strip
# for the settings.json entries, the files, the binary, rtk's own dirs.
#
# TEMPORARY: delete once every machine has run this version.
if command -v rtk >/dev/null 2>&1; then
  if rtk init --global --uninstall >/dev/null 2>&1 </dev/null; then
    echo "✓ rtk: its own uninstall ran (hook, RTK.md, settings.json entry)"
  else
    echo "⚠️  rtk init --global --uninstall failed — the cleanup below still runs"
  fi
fi

# Matched on the command, like rtk's own uninstall: the current `rtk hook claude`
# (with or without an absolute path in front) and the legacy rtk-rewrite.sh.
# `$SETTINGS` and `_settings_strip_hooks` come from settings.sh, sourced first;
# without jq the helper's guard fails and this is a no-op.
_settings_strip_hooks 'rtk hook claude|rtk-rewrite\.sh' \
  "rtk hooks stripped from settings.json" \
  "could not strip the rtk hooks — settings.json left untouched"
rm -f "$HOME/.claude/RTK.md" \
      "$HOME/.claude/hooks/rtk-rewrite.sh" \
      "$HOME/.claude/hooks/.rtk-hook.sha256"

# The binary: Homebrew's formula on mac (it was in REQUIRED_FORMULAE), the
# official curl installer's ~/.local/bin/rtk on Linux. Anything else on PATH
# was not put there by this repo, so it is reported and left alone.
if command -v brew >/dev/null 2>&1 && brew list --formula rtk >/dev/null 2>&1; then
  if brew uninstall rtk >/dev/null 2>&1; then
    echo "✓ rtk: Homebrew formula uninstalled"
  else
    echo "⚠️  brew uninstall rtk failed — remove it by hand"
  fi
fi
if [[ -e "$HOME/.local/bin/rtk" || -L "$HOME/.local/bin/rtk" ]]; then
  rm -f "$HOME/.local/bin/rtk"
  echo "✓ rtk: removed ~/.local/bin/rtk"
fi
hash -r
if command -v rtk >/dev/null 2>&1; then
  echo "⚠️  rtk is still on PATH at $(command -v rtk) — not installed by this repo, remove it by hand"
fi

# rtk's own dirs: config.toml (and the backups of a diverged one), filters.toml,
# the tracking db, the tee spool. It follows the platform convention, so on
# mac config and data are the same Application Support dir.
if [[ "$OSTYPE" == darwin* ]]; then
  _rtk_dirs=("$HOME/Library/Application Support/rtk")
else
  _rtk_dirs=("${XDG_CONFIG_HOME:-$HOME/.config}/rtk" "${XDG_DATA_HOME:-$HOME/.local/share}/rtk")
fi
for _rtk_dir in "${_rtk_dirs[@]}"; do
  if [[ -d "$_rtk_dir" ]]; then
    rm -rf "$_rtk_dir"
    echo "✓ rtk: removed $_rtk_dir"
  fi
done
unset _rtk_dirs _rtk_dir

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
# binary and the state of ~/.claude are independent. If the `codebase-memory`
# skill goes missing after an install.sh, check this has not moved inside the
# `if`.
# It is idempotent (verified with --dry-run: it detects the existing config and
# does not duplicate it).
if command -v codebase-memory-mcp >/dev/null 2>&1; then
  codebase-memory-mcp install -y >/dev/null 2>&1 \
    && echo "✓ codebase-memory-mcp: MCP server + skill registered" \
    || echo "⚠️  codebase-memory-mcp install -y failed"
  # auto_index: cheap and idempotent, forced on every run so new projects index
  # themselves on connect. The `||` is not optional: this file is sourced under
  # the installer's `set -e`, so a bare failing command here would abort every
  # step after install_claude.
  codebase-memory-mcp config set auto_index true >/dev/null 2>&1 \
    && echo "✓ codebase-memory-mcp: auto_index=true" \
    || echo "⚠️  codebase-memory-mcp config set auto_index failed"
fi

# ── convergent cleanup: the hooks `install -y` registers ──
# `install -y` also writes three Claude Code hooks, and 0.9.0 has no way to opt
# out (no install flag, no config key), so they are stripped after every run:
#  - SessionStart (startup/resume/clear/compact) + SubagentStart print a fixed
#    "ALWAYS use codebase-memory-mcp FIRST" protocol into every context. The MCP
#    tools and the `codebase-memory` skill already announce themselves; which one
#    to reach for is the user's call, not a standing order.
#  - PreToolUse on `Grep|Glob` augments those tools' results, and never fires in
#    a session that has no Grep/Glob tool.
# Matched on the script path, not on event or matcher: those arrays are shared
# (the logbook plugin's, no-bash-edits'). Must stay AFTER `install -y`, which
# re-adds all three on every run.
#
# Not `_settings_strip_hooks`: that one drops a whole entry when ANY of its
# commands matches, this drops the matching commands and keeps whatever else
# shares their entry. `$SETTINGS` and `_settings_apply` come from settings.sh,
# sourced first; when it bailed out for lack of jq, the `jq -e` guard fails too
# and this is skipped.
if [[ -f "${SETTINGS:-}" ]] && jq -e '[.hooks[]?[]?.hooks[]?.command // "" | select(contains("hooks/cbm-"))] | length > 0' \
     "$SETTINGS" >/dev/null 2>&1; then
  _settings_apply '.hooks |= (map_values(map(.hooks |= map(select((.command // "") | contains("hooks/cbm-") | not)))
                               | map(select(.hooks | length > 0)))
                    | with_entries(select(.value | length > 0)))' \
    "codebase-memory-mcp hooks stripped from settings.json" \
    "could not strip the codebase-memory-mcp hooks — settings.json left untouched"
fi
rm -f "$HOME"/.claude/hooks/cbm-*

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

# ─── the vault's MCP: not registered here ─────────────────────
# The `logbook` skills write through a server named `logbook-mcp`, but which vault
# that is (personal or work) is a per-machine choice with its own Access token. It is
# registered by hand with the one-line command kept in that vault's 1Password item.

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
#                   on invisible stdin is the footgun documented at the top
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
# TEXTUAL match. Our PATH lives in zsh/path.zsh with `$HOME` (not the expanded
# absolute path), so that naive check never recognizes it and it always re-adds
# its line, with THIS machine's path hardcoded. Since ~/.zshrc is a symlink into
# the repo, that dirties the VERSIONED file — and since `install -y` runs on
# every run, it comes back every time. It goes AFTER the install -y: the other
# way around, the binary would dirty the file again and `git status` would be
# dirty after every run.
#
# Two details that are NOT cosmetic (both break silently):
#  - The binary writes THREE lines: a BLANK one, the marker, and the export. A
#    `skip = 2` from the marker leaves the blank one orphaned, a `+` in the
#    diff. The awk defers the blanks (pending) and drops them if what
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
