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
# Nothing in binaries.sh writes to ~/.claude/CLAUDE.md any more: `rtk init` used
# to append an `@RTK.md` import, and `--hook-only` (binaries.sh) stopped it. The
# symlink still goes first, it just no longer has to.
link "$DOTFILES/claude/statusline.sh" "$HOME/.claude/statusline.sh"
link "$DOTFILES/claude/CLAUDE.md"     "$HOME/.claude/CLAUDE.md"

# Per-ITEM skill symlinks — NOT the whole ~/.claude/skills/ dir. Symlinking the
# whole dir was rejected (see project CLAUDE.md: per-machine content, .gitignore
# leak risk). A hand-authored skill we DO version is the additive exception: we
# control its content, it sits beside the per-machine skills (`learned`,
# `codebase-memory`, the OpenKnowledge ones) without touching them, and there is no
# leak because the repo folder only ever holds what we put there.
#
# Dropped in aug-2026 with the obsidian MCP they wrote through, and back in
# sep-2026 rewritten against the `open-knowledge` MCP (registered in binaries.sh).
#
# `logbook` covers BOTH vault layers, capture and synthesis: `/logbook:entry`
# writes one immutable note per invocation into entries/, and ingest/query/lint
# work over the wiki/ pages synthesized from those notes. On top of that,
# guide/runbook/document/walkthrough AUTHOR new documents into guides/, runbooks/,
# docs/ and flows/ from verified sources rather than from the session's context —
# `walkthrough` anchors every diagram node to a file:line at a pinned commit SHA,
# so its page can be re-verified mechanically. `task` is the odd one: a per-repo
# board in tasks/, the one MUTABLE layer, holding pending work with a code anchor
# when it is technical. The per-vault taxonomy is
# NOT here — it lives in the vault's own wiki/CLAUDE.md, versioned with the content
# it governs. The plugin is the engine, that file is the config.
#
# NOTE: `logbook` is a skills-dir PLUGIN, not a plain skill — the dir holds a
# `.claude-plugin/plugin.json` (skills: ./skills/) so Claude Code auto-loads it as
# `logbook@skills-dir`, bundling nine sub-skills that invoke as `/logbook:entry`,
# `/logbook:ingest`, `/logbook:query`, `/logbook:lint`, `/logbook:guide`,
# `/logbook:runbook`, `/logbook:document`, `/logbook:walkthrough`,
# `/logbook:task`. Plugin skills are ALWAYS
# namespaced with a colon: invocation is `/<plugin>:<folder>` (folder = skill name,
# `logbook` = plugin `name:` from plugin.json). So the folders are the bare nouns
# and verbs (entry, ingest, …) and you type the real colon form `/logbook:lint` —
# the `:` is a typeable invocation, not a display label. Naming a folder
# `wiki-lint` is what once made it `/wiki:wiki-lint`.
# It installs by THIS symlink alone — a skills-dir plugin is referenced in place,
# so a `git pull` propagates edits with no marketplace and no copy into
# ~/.claude/plugins/cache (unlike mechanism 3 in plugins.sh). That's why nothing
# here differs from a plain skill, and why plugins.sh has no `logbook` entry. The
# plugin's value is packaging: one dir, one symlink, and the skills share two spec
# files at the root (each SKILL.md reads them first) so the spec is single-source —
# ENGINE.md for the vault's layers and tools, AUTHORING.md for the evidence rule
# the four authoring skills follow. `entry` and `task` are deliberately outside
# both and self-contained: each writes one short thing, so reading three spec
# files first is a cost neither would earn back.
link "$DOTFILES/claude/skills/logbook" "$HOME/.claude/skills/logbook"

# The logbook's event half. A skill cannot fire on a git event — it only
# self-activates on what the user says — so the "log after a commit lands" trigger
# is a PostToolUse hook (registered further down) pointing at this script.
# ~/.claude/hooks/ is a real per-machine dir (codebase-memory-mcp writes its own
# hooks there), so this is a per-ITEM link for the same reason as the skills above.
link "$DOTFILES/claude/hooks/logbook.sh" "$HOME/.claude/hooks/logbook.sh"

# ── convergent cleanup: the pre-rename `bitacora` + `wiki` names (sep-2026) ──
# The plugin was `wiki` and capture was a separate plain skill, `bitacora`; both
# are now the one `logbook` plugin. A machine that ran the old installer still has
# those two symlinks, and they now dangle — a dangling skill dir is a skill Claude
# Code tries to load and cannot. Guarded on -L so a REAL per-machine dir that
# happens to carry one of those names is never touched. TEMPORARY: delete once
# every machine has run this version.
for _stale in "$HOME/.claude/skills/bitacora" "$HOME/.claude/skills/wiki" \
              "$HOME/.claude/hooks/bitacora.sh"; do
  if [ -L "$_stale" ]; then
    rm -f "$_stale"
    echo "✓ removed pre-rename symlink $_stale"
  fi
done
unset _stale

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

# ── env.CLAUDE_CODE_EXPERIMENTAL_* : agent teams + observer agents ──
# Two experimental features that are OFF unless their env var is set: agent
# teams (teammate agents you can message, `--agent-teams` is the CLI twin of
# the var) and observer agents (the fan-out that reviews a subagent's work).
# Verified against the 2.1.267 binary, which reads both as plain truthiness —
# the value is any non-empty STRING ("1" here; `env` is documented as string
# pairs, an integer is the wrong type), and there is no `false` value: to turn
# one off you remove the key, you don't set it to "0".
#
# Both are ALSO gated server-side (`tengu_amber_flint`, `tengu_observer_agents_enabled`),
# so the var is necessary and not sufficient — on an account without the gate,
# or on a CLI too old to know the name, this degrades to an ignored key. That's
# why there is no version guard, same as outputStyle.
#
# Written into settings.json's `env` and not exported from `.zshenv`, for the
# reason that file's own rules give: `.zshenv` is sourced by every zsh, so an
# export there hands the flag to every process the shell spawns. `env` scopes it
# to Claude Code and needs no new terminal.
#
# Keyed per FIELD, like attribution.* above: `env` may already exist on a machine
# (Windows sets CLAUDE_CODE_USE_POWERSHELL_TOOL in it), and a guard on `.env`
# would be satisfied by that and never write these.
_settings_set_if_absent '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' \
  '.env //= {} | .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"' \
  'env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'

_settings_set_if_absent '.env.CLAUDE_CODE_EXPERIMENTAL_OBSERVER_AGENTS' \
  '.env //= {} | .env.CLAUDE_CODE_EXPERIMENTAL_OBSERVER_AGENTS = "1"' \
  'env.CLAUDE_CODE_EXPERIMENTAL_OBSERVER_AGENTS'

# ── convergent cleanup: the pre-rename bitacora hook entry (sep-2026) ──
# Must run BEFORE the block that registers the new one, or the guard below sees a
# settings.json with no "hooks/logbook" string, appends ours, and leaves the dead
# `hooks/bitacora.sh` entry beside it firing exit 127 on every commit. Same shape
# as the state.sh cleanup at the bottom of this file. TEMPORARY, same terms.
if jq -e '[.. | strings] | any(test("hooks/bitacora"))' "$SETTINGS" >/dev/null 2>&1; then
  SETTINGS_TMP="$(mktemp)"
  if jq '.hooks |= (to_entries
          | map(.value |= map(select(
              (.hooks // []) | any(.command? // "" | test("hooks/bitacora")) | not
            )))
          | map(select((.value | length) > 0))
          | from_entries)' "$SETTINGS" > "$SETTINGS_TMP"; then
    mv "$SETTINGS_TMP" "$SETTINGS"
    echo "✓ pre-rename bitacora hook stripped from settings.json"
  else
    rm -f "$SETTINGS_TMP"
    echo "⚠️  pre-rename hook cleanup failed — settings.json left untouched"
  fi
fi

# ── PostToolUse hook: logbook entry after a commit ──
# The one thing a SKILL cannot do is fire on an event: it self-activates on what
# the user says, and "write the entry after you commit" has no user utterance to
# hang on. So the trigger is a hook and the how-to stays in the skill —
# claude/hooks/logbook.sh only detects the commit and returns one line of context.
#
# `matcher` covers BOTH tool names: settings.json sets CLAUDE_CODE_USE_POWERSHELL_TOOL
# on Windows, and any session that inherits it routes commits through PowerShell
# instead of Bash. Matching only "Bash" is how this would go quietly dead.
#
# Invoked as `bash ~/.claude/hooks/…` rather than as the script itself: the file
# arrives through a symlink from a fresh clone, and git does not always carry the
# exec bit (it never does on Windows checkouts). Naming the interpreter sidesteps
# the whole question.
#
# Guarded on the COMMAND STRING appearing anywhere in .hooks, not on a jq path:
# .hooks.PostToolUse is an array shared with other tools (codebase-memory-mcp
# registers its own entries there), so `_settings_set_if_absent` cannot be used —
# its key would be satisfied by somebody else's hook and ours would never land,
# or a re-run would append a duplicate. Deep-scanning for our own command is the
# only check that is both idempotent and additive.
if ! jq -e '[.. | strings] | any(test("hooks/logbook"))' "$SETTINGS" >/dev/null 2>&1; then
  SETTINGS_TMP="$(mktemp)"
  if jq '.hooks //= {}
         | .hooks.PostToolUse //= []
         | .hooks.PostToolUse += [{
             matcher: "Bash|PowerShell",
             hooks: [{
               type: "command",
               command: "bash ~/.claude/hooks/logbook.sh",
               timeout: 5
             }]
           }]' "$SETTINGS" > "$SETTINGS_TMP"; then
    mv "$SETTINGS_TMP" "$SETTINGS"
    echo "✓ logbook PostToolUse hook added to settings.json"
  else
    rm -f "$SETTINGS_TMP"
    echo "⚠️  could not add the logbook hook — settings.json left untouched"
  fi
else
  echo "✓ logbook PostToolUse hook already in settings.json — leaving it alone"
fi

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
