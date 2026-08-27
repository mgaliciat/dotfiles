# shellcheck shell=bash
# ─── Claude Code: what WE write into settings.json ───
#
# Mechanism 1 of 3 (see claude/install/README.md). Everything this repo writes
# into ~/.claude/settings.json by hand, with jq — nothing else. The other two
# mechanisms (self-registering binaries, marketplace plugins) don't touch the
# file from here: they write it themselves.
#
# Sourced by install.sh and install-linux.sh — NOT a standalone executable:
# it assumes `link()`, `$DOTFILES` and `$TS` from the parent installer, and
# that jq is already installed (the installers run their deps block first).

SETTINGS="$HOME/.claude/settings.json"
PERMISSIONS="$DOTFILES/claude/install/permissions.json"

# ── versioned symlinks (not settings.json itself, but its input) ──
# statusline.sh: generic script, no personal state → versioned.
# User-level CLAUDE.md: prose, preferences that apply to ALL projects.
# The CLAUDE.md symlink goes BEFORE binaries.sh: `rtk init --global` appends an
# `@RTK.md` line if missing, and we want that write to land on the versioned
# file (through the symlink), not on a loose per-machine one.
link "$DOTFILES/claude/statusline.sh" "$HOME/.claude/statusline.sh"
link "$DOTFILES/claude/CLAUDE.md"     "$HOME/.claude/CLAUDE.md"

# Per-ITEM skill symlink — NOT the whole ~/.claude/skills/ dir. Symlinking the
# whole dir was rejected (see project CLAUDE.md: per-machine content, .gitignore
# leak risk). A single hand-authored skill we DO version is the additive
# exception: we control its content, it sits beside the per-machine skills
# (`learned`, `codebase-memory`) without touching them. `bitacora` = daily work
# log into Obsidian; depends on the obsidian MCP, so it's mac/Linux like context7.
link "$DOTFILES/claude/skills/bitacora" "$HOME/.claude/skills/bitacora"
# `wiki` = synthesis layer OVER the bitácora: ingests Bitacora/ into cross-linked
# Wiki/ pages, queries them, lints for rot. Same obsidian-MCP dependency, so same
# mac/Linux reach. The per-vault taxonomy lives in the vault's Wiki/CLAUDE.md
# (per-machine, not versioned) — the plugin is the engine, that file is the config.
#
# NOTE: `wiki` is a skills-dir PLUGIN, not a plain skill — the dir holds a
# `.claude-plugin/plugin.json` (skills: ./skills/) so Claude Code auto-loads it as
# `wiki@skills-dir`, bundling three sub-skills that invoke as `/wiki:ingest`,
# `/wiki:query`, `/wiki:lint`. Plugin skills are ALWAYS namespaced with a colon:
# invocation is `/<plugin>:<folder>` (folder = skill name, `wiki` = plugin `name:`
# from plugin.json). So the folders are the bare verbs (ingest, …) and you type
# the real colon form `/wiki:lint` — the `:` is a typeable invocation, not just a
# display label. Naming the folder `wiki-lint` is what made it `/wiki:wiki-lint`.
# It still installs by THIS symlink alone — a skills-dir plugin is referenced in
# place, so a `git pull` propagates edits with no marketplace and no copy into
# ~/.claude/plugins/cache (unlike mechanism 3 in plugins.sh). That's why nothing
# here changed vs when it was a plain skill, and why plugins.sh has no `wiki`
# entry. The plugin's value now is packaging: one dir, one symlink, and the three
# skills share one ENGINE.md at the root (each SKILL.md reads it first) to keep the
# OKF spec single-source. `bitacora` stays a plain skill (no plugin.json) beside it.
link "$DOTFILES/claude/skills/wiki" "$HOME/.claude/skills/wiki"

# settings.json itself is NOT symlinked: it's 100% per-machine (like
# ~/.gitconfig). Permissions and UI prefs diverge per host, and symlinking it
# into a PUBLIC repo dragged personal state along (enabledPlugins, marketplaces).
# What follows are controlled exceptions: additive-only, guarded. If the key
# already exists on this machine, we leave it alone.

if ! command -v jq >/dev/null 2>&1; then
  echo "⚠️  jq not found — skipping settings.json config"
  return 0 2>/dev/null || exit 0
fi

mkdir -p "$(dirname "$SETTINGS")"
[[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"

# Atomic write behind a guard. $1 = key to check (jq path), $2 = jq filter to
# apply, $3 = human-readable name for the messages. settings.json is a REAL file
# (not a symlink), so mktemp + mv is correct here — unlike the ~/.zshrc cleanup
# in binaries.sh, which writes with `cat >` precisely because a symlink is
# involved there.
_settings_set_if_absent() {
  local key="$1" filter="$2" label="$3" tmp
  if jq -e "$key" "$SETTINGS" >/dev/null 2>&1; then
    echo "✓ $label already set in settings.json — leaving it alone"
    return 0
  fi
  tmp="$(mktemp)"
  if jq --slurpfile perms "$PERMISSIONS" "$filter" "$SETTINGS" > "$tmp"; then
    mv "$tmp" "$SETTINGS"
    echo "✓ $label added to settings.json"
  else
    rm -f "$tmp"
    echo "⚠️  could not add $label — settings.json left untouched"
  fi
}

# ── statusLine ──
# The script is versioned (above); its ACTIVATION is per-machine.
_settings_set_if_absent '.statusLine' \
  '.statusLine = {"type": "command", "command": "~/.claude/statusline.sh"}' \
  'statusLine'

# Keyed on the nested field, NOT on `.statusLine`: the guard above is satisfied
# by any pre-existing statusLine, so a machine that already had one would never
# see this. Runs second so it lands on the object the previous call may have
# just created.
#
# Without it the status line re-runs on EVENTS only, and our `↻` countdown to
# the 5h rate-limit reset freezes while the session is idle — which is exactly
# when you're looking at it. 60s because the countdown is rendered in minutes;
# anything faster just burns a subprocess to redraw the same string.
_settings_set_if_absent '.statusLine.refreshInterval' \
  '.statusLine.refreshInterval = 60' \
  'statusLine.refreshInterval'

# ── permissions.allow / deny ──
# The lists live in claude/install/permissions.json — single source of truth
# shared with install-windows.ps1, which reads the same file with
# ConvertFrom-Json. Adding a permission in one place used to leave the other
# platform silently behind; now there is only one place. The rationale for
# what's in (and deliberately out of) each list is in that file's _comment.
_settings_set_if_absent '.permissions.allow' \
  '.permissions //= {} | .permissions.allow = $perms[0].allow' \
  'permissions.allow'

_settings_set_if_absent '.permissions.deny' \
  '.permissions //= {} | .permissions.deny = $perms[0].deny' \
  'permissions.deny'

# ── attribution: no Co-Authored-By trailer ──
# `attribution.commit` / `.pr` override the text Claude Code appends to commit
# messages and PR bodies. An EMPTY STRING is the documented sentinel for "hide it
# entirely" ("Empty string hides attribution" in the CLI's own settings schema) —
# it is not a no-op, and it is not the same as leaving the key out, which means
# "use the default trailer". It supersedes `includeCoAuthoredBy`, which the CLI
# now marks deprecated: don't add that one back alongside it.
#
# Keyed per FIELD rather than on `.attribution`, for the same reason as
# refreshInterval above: a machine where /config or a hand edit already created
# the object for ONE field would never get the other. The empty string survives
# the guard correctly — `jq -e` only fails on `false` and `null`, so `""` reads
# as present and a re-run leaves it alone instead of rewriting it.
#
# There is a third field in the schema, `attribution.sessionUrl` (bool, appends
# the claude.ai session link on commits/PRs from web or Remote Control sessions).
# Deliberately not set: it is a different trailer with a different purpose, and
# it only ever fires on sessions we don't run from here.
#
# The user-level claude/CLAUDE.md carries the same rule in prose. Both on purpose:
# this setting stops the harness INJECTING the trailer instruction, the prose
# stops one being written by hand into a PR body or a commit made via another
# tool — and covers machines whose settings.json predates this block.
_settings_set_if_absent '.attribution.commit' \
  '.attribution //= {} | .attribution.commit = ""' \
  'attribution.commit (no Co-Authored-By)'

_settings_set_if_absent '.attribution.pr' \
  '.attribution //= {} | .attribution.pr = ""' \
  'attribution.pr (no Co-Authored-By)'

# ── outputStyle: Concise ──
# Output styles are the only lever that edits Claude Code's SYSTEM PROMPT (as
# opposed to CLAUDE.md, which is appended as a user message after it). `Concise`
# is a built-in: lead with the result, no preamble, no narration of what's about
# to happen — while doing the same engineering work, answering in full when you
# actually ask for detail, and never truncating errors, security warnings or
# destructive-action confirmations.
#
# Set HERE and not as a custom style in ~/.claude/output-styles/ on purpose: a
# custom style DROPS Claude Code's built-in software-engineering instructions
# (how to scope a change, how to verify work) unless `keep-coding-instructions:
# true` — all-or-nothing for a tone tweak. Anything about how code should be
# written belongs in claude/CLAUDE.md instead; that's the documented split.
#
# Needs Claude Code >= 2.1.237 (`Concise` didn't exist before). On an older CLI
# the key is simply an unknown style and the Default prompt is used — degrades
# to a no-op, which is why there's no version gate here.
#
# Guarded like the rest: `/config` writes the user's pick to the PROJECT-local
# .claude/settings.local.json, which outranks this file, so a per-project choice
# still wins and a hand-set value here is never rewritten.
_settings_set_if_absent '.outputStyle' \
  '.outputStyle = "Concise"' \
  'outputStyle (Concise)'

# ── fallbackModel ──
# Which model takes over when the primary is overloaded or unavailable. Without
# it an overloaded opus just makes you wait; with it the turn continues on
# sonnet. The schema wants an ARRAY even for a single entry (tried in order) —
# a bare string is silently ignored, which is the failure mode this comment
# exists to prevent. Aliases resolve at runtime, so "sonnet" keeps meaning the
# current sonnet without a version to bump here.
#
# `model` itself is deliberately NOT set by this installer: it is the one choice
# that legitimately differs per machine and per session (/model writes it), and
# a guard that pinned it would fight the picker.
_settings_set_if_absent '.fallbackModel' \
  '.fallbackModel = ["sonnet"]' \
  'fallbackModel (sonnet)'

# ── autoContinueAtUsageLimit ──
# On hitting a claude.ai usage limit, hold the session open and resume the task
# by itself when the window resets, instead of stopping at a dialog that has to
# be answered by hand. The wait is offered either way — this only picks the
# answer up front. Worth it here because sessions routinely run unattended in
# background tmux popups, where nobody is watching to click through.
_settings_set_if_absent '.autoContinueAtUsageLimit' \
  '.autoContinueAtUsageLimit = true' \
  'autoContinueAtUsageLimit'

# ── terminalTitleFromRename ──
# Stop `/rename` and `--name` from rewriting the terminal tab title. tmux
# already owns the window name (and the statusline renders it), so letting
# Claude Code write there means two things fighting over one string.
_settings_set_if_absent '.terminalTitleFromRename' \
  '.terminalTitleFromRename = false' \
  'terminalTitleFromRename (leave the tab title to tmux)'

# ── preferredNotifChannel ──
# How the OS notification is delivered when a turn finishes or input is needed.
# The enum is auto | iterm2 | terminal_bell | iterm2_with_bell | kitty |
# ghostty | notifications_disabled (from the CLI's own schema — a value outside
# it is accepted by the file and then ignored at runtime, so don't guess).
#
# `terminal_bell` and NOT `ghostty`, even though ghostty is the terminal on the
# mac: this file is sourced by install-linux.sh too, where Ghostty is not part
# of the portable subset, and a hardcoded `ghostty` there would resolve to
# nothing with no error. The bell is the one channel every terminal here has,
# and on the mac it lands in Ghostty's own `bell-features` handling anyway.
#
# `auto` (the default) would be the obvious third option, but it detects the
# terminal from the environment, and inside a tmux popup that environment says
# tmux — which is exactly where these sessions run.
_settings_set_if_absent '.preferredNotifChannel' \
  '.preferredNotifChannel = "terminal_bell"' \
  'preferredNotifChannel (terminal_bell)'

# ── convergent cleanup: stale tmux-claude-session-manager hooks ──
# Until jul-2026 the plugin read state through 4 hooks (UserPromptSubmit /
# Notification / PreToolUse / Stop → scripts/state.sh) that these installers
# merged in here. The plugin moved to `claude agents --json` (no hooks) and
# deleted state.sh upstream, so those hooks now fail (exit 127) on every event.
# We strip them if present, without touching the rest of .hooks. TEMPORARY
# block: once every machine has run this version of the installer, delete it.
if jq -e '[.. | strings] | any(test("tmux-claude-session-manager/scripts/state.sh"))' "$SETTINGS" >/dev/null 2>&1; then
  SETTINGS_TMP="$(mktemp)"
  if jq '.hooks |= (to_entries
          | map(.value |= map(select(
              (.hooks // []) | any(.command? // "" | test("tmux-claude-session-manager/scripts/state.sh")) | not
            )))
          | map(select((.value | length) > 0))
          | from_entries)' "$SETTINGS" > "$SETTINGS_TMP"; then
    mv "$SETTINGS_TMP" "$SETTINGS"
    echo "✓ stale claude-session-manager hooks (state.sh) stripped from settings.json"
  else
    rm -f "$SETTINGS_TMP"
    echo "⚠️  stale-hook cleanup failed — settings.json left untouched"
  fi
fi
