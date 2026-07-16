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
# (per-machine, not versioned) — the skill is the engine, that file is the config.
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
