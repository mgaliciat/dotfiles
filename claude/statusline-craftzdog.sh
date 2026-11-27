#!/bin/bash
# Claude Code status line in craftzdog's look — an OPT-IN alternative to
# statusline.sh, not a replacement for it.
#
# Provenance: craftzdog publishes no Claude Code status line (checked against
# github.com/craftzdog/dotfiles-public, its full history, his gists and
# tmux-claude-hatch, 2026-11). The bar people see under his Claude sessions is
# his TMUX status line, dot_config/tmux/statusline.conf. This is that bar
# ported: the same rounded Solarized pills, the same hex values, the same three
# groups, filled with what Claude Code hands a status line on stdin.
#
#   his tmux bar                          this line
#   ─────────────────────────────────     ──────────────────────────────────
#   status-left   session │ whoami        model │ effort
#   current win   index │ path basename   branch │ cwd basename
#   bell flag     magenta window          magenta once context ≥ 90%
#   status-right  hostname                context % · 5h quota ↻ reset
#
# Activate it per machine (settings.json is not versioned; see
# claude/install/README.md):
#   jq '.statusLine.command = "~/.claude/statusline-craftzdog.sh"' \
#     ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
#
# Needs: jq, git, a terminal with 24-bit colour (Ghostty is), and a Nerd Font
# for the two rounded caps U+E0B6/U+E0B4 (the same glyphs his tmux bar uses).

# ONE jq for every field, one value per line — the reasoning is statusline.sh's:
# this runs every second (statusLine.refreshInterval = 1), so every process
# counts, and `read` with a tab IFS would collapse the empty fields.
{
  read -r MODEL
  read -r DIR
  read -r PCT
  read -r EFFORT
  read -r FIVE_H
  read -r RESETS_AT
  read -r NOW
} < <(jq -r '
  (.model.display_name // .model.id // ""),
  (.workspace.current_dir // .cwd // ""),
  (.context_window.used_percentage // 0 | floor),
  (.effort.level // ""),
  (.rate_limits.five_hour.used_percentage // "" | if . == "" then . else floor end),
  (.rate_limits.five_hour.resets_at // ""),
  (now | floor)
')

# ─── palette: his hex, verbatim ───────────────────────────────
# 24-bit, NOT plain ANSI like statusline.sh. The point of this file is his
# look, and his bar names hex values; ANSI slots would repaint it with whatever
# the stack theme puts there (solarized-osaka's 14 is a cyan, not base1). So it
# does NOT follow `theme` — it is Solarized on every theme, as his is.
#
# The one change: his caps sit on bg #00141A, his tmux bar's own fill. Here
# there is no bar fill, so the caps sit on the terminal's default background
# and the pills float on whatever canvas the theme draws.
fg() { printf '\033[38;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
bg() { printf '\033[48;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
BASE2=eee8d5 BASE02=073642 BASE1=93a1a1 INK=15161e BLUE=278bd3 MAGENTA=d33682
BOLD=$'\033[1m' RESET=$'\033[0m'
# As UTF-8 bytes, never pasted — Private Use codepoints get dropped in silence
# by editors and tools (see BRAIN in statusline.sh). \xHH because macOS runs
# this under /bin/bash 3.2, which has no \u.
L=$'\xee\x82\xb6'  # U+E0B6, left rounded cap
R=$'\xee\x82\xb4'  # U+E0B4, right rounded cap

# pill BG FG TEXT [NEXT_BG] — one rounded segment. With NEXT_BG the right cap
# is drawn over the next segment's fill (his `#[fg=#eee8d5,bg=#93a1a1]`),
# which is what joins two pills into one; without it the cap closes the group.
# The left cap is the caller's, so a joined segment does not get a second one.
pill() {
  local out
  out="$(bg "$1")$(fg "$2")${BOLD} $3 ${RESET}"
  if [ -n "$4" ]; then out+="$(bg "$4")$(fg "$1")${R}"
  else                 out+="$(fg "$1")${R}${RESET}"; fi
  printf '%s' "$out"
}
cap() { printf '%s%s%s' "$(fg "$1")" "$L" "$RESET"; }

# ─── left: model │ effort ─────────────────────────────────────
if [ -n "$EFFORT" ]; then
  LEFT="$(cap $BASE2)$(pill $BASE2 $BASE02 "$MODEL" $BASE1)$(pill $BASE1 $INK "$EFFORT")"
else
  LEFT="$(cap $BASE2)$(pill $BASE2 $BASE02 "$MODEL")"
fi

# ─── current window: branch │ cwd ─────────────────────────────
# His window pill turns magenta on the bell flag — the window that needs you.
# Here the thing that needs you is a full context window, so that is what
# flips it.
ACCENT=$BLUE
[ "$PCT" -ge 90 ] && ACCENT=$MAGENTA
# `-C "$DIR"`: the branch of the directory shown, not of our own cwd. Empty
# outside a repo and on a detached HEAD, and then the blue half is skipped.
BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
LEAF=${DIR##*/}
[ -z "$LEAF" ] && LEAF=$DIR
if [ -n "$BRANCH" ]; then
  WIN="$(cap $ACCENT)$(pill $ACCENT $BASE2 "$BRANCH" $BASE2)$(pill $BASE2 $BASE02 "$LEAF")"
else
  WIN="$(cap $BASE2)$(pill $BASE2 $BASE02 "$LEAF")"
fi

# ─── right: context · quota ───────────────────────────────────
# The 5h window is optional throughout: absent for API-key users and until the
# first response, and resets_at can be absent on its own. Time remaining is
# arithmetic against jq's `now`, so no BSD/GNU `date` branch.
METER="ctx ${PCT}%"
if [ -n "$FIVE_H" ]; then
  METER="${METER} · 5h ${FIVE_H}%"
  if [ -n "$RESETS_AT" ]; then
    MINS=$(((RESETS_AT - NOW) / 60))
    if [ "$MINS" -ge 60 ]; then REMAIN="$((MINS / 60))h$((MINS % 60))m"; else REMAIN="${MINS}m"; fi
    [ "$MINS" -gt 0 ] && METER="${METER} ↻${REMAIN}"
  fi
fi
# Magenta here too, not only on the window pill: outside a repo there is no
# blue half to flip, and the meter is where the number lives.
if [ "$PCT" -ge 90 ]; then
  RIGHT="$(cap $MAGENTA)$(pill $MAGENTA $BASE2 "$METER")"
else
  RIGHT="$(cap $BASE1)$(pill $BASE1 $INK "$METER")"
fi

# ─── layout ───────────────────────────────────────────────────
# His bar is left / centred windows / right. Centring the middle group would
# make it jump every time the model name or the meter changes width, so the
# window pill rides after the left group and the meters flush right — the same
# zones statusline.sh uses. EDGE_RESERVE is statusline.sh's empirical margin
# for the box chrome and wide glyphs that COLUMNS cannot see; without COLUMNS
# (older Claude Code, or a pipe) everything is simply joined with spaces.
EDGE_RESERVE=8
# Visible width, escapes stripped — statusline.sh's vis(), which needs extglob.
shopt -s extglob
vis() { local s=${1//$'\033'\[*([0-9;])m/}; printf '%d' "${#s}"; }

MAIN="${LEFT} ${WIN}"
OUT="${MAIN} ${RIGHT}"
if [ -n "$COLUMNS" ]; then
  GAP=$((COLUMNS - EDGE_RESERVE - $(vis "$MAIN") - $(vis "$RIGHT")))
  if [ "$GAP" -ge 3 ]; then
    printf -v PAD '%*s' "$GAP" ''
    OUT="${MAIN}${PAD}${RIGHT}"
  fi
fi

# Plain echo, no -e: the escapes above are already real ones, and -e would let
# a backslash in a branch or directory name be interpreted.
echo "$OUT"
