#!/bin/bash
# Claude Code status line: model, reasoning effort, cwd, git branch, context
# usage, rate-limit windows.
# Session cost was dropped (jul-2026): `.cost.total_cost_usd` is still on stdin
# if it's ever wanted back, but on a subscription it's a number you can't act on.
# JSON session data arrives on stdin (see: https://code.claude.com/docs/en/statusline).
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.id')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
USED=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

# `effort.level` is the LIVE value — a mid-session `/effort` is reflected here,
# so this is not decoration: it's the biggest lever on how fast the rate-limit
# windows below fill. Absent when the model has no effort parameter (hence
# `// empty`), and ultracode reports as `xhigh` rather than a level of its own.
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')

# ─── context usage ────────────────────────────────────────────
# Just the number, no gauge. A graphical bar was tried (8 cubes x 8 sub-levels,
# coloured green/yellow/red by position in the window) and removed jul-2026: on
# a 1M window you sit at ~12% for a whole session, so it spent ~17 columns
# saying what `121k/1M` already says, more precisely.
#
# This replaced an earlier cyan/magenta split (accumulated vs. added-this-turn).
# The data for that split is still on stdin if it's ever wanted back:
# `current_usage` breaks into cache_read (everything before this turn) +
# cache_creation (what this turn added) + input, summing exactly to
# total_input_tokens.
#
# ⚠️ What is NOT available at all is the `/context` category breakdown (system
# prompt / system tools / MCP tools / skills / memory / messages). Claude Code
# computes that internally and never puts it on stdin — don't try to break the
# number down by category, the data isn't there.
#
# Colours are plain ANSI (not hex) on purpose: the active stack theme remaps
# them, so the statusline follows whatever Ghostty/tmux/nvim are wearing.

GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'
CHIP=$'' # nf-fa-microchip

# One ladder for every gauge on the line (ctx, 5h, 7d) so a colour means the
# same thing wherever it appears — there used to be a copy of this `if` per
# gauge, which is how they drift apart. `%b` expands the \033 literals into real
# escapes, so callers can interpolate the result straight into a string.
hue() {
  if   [ "$1" -ge 90 ]; then printf '%b' "$RED"
  elif [ "$1" -ge 70 ]; then printf '%b' "$YELLOW"
  else printf '%b' "$GREEN"; fi
}

# The number is absolute (121k/1M), not a percentage: on a 1M window "12%" is
# not a quantity you can act on, while "121k" is.
NUM_COLOR=$(hue "$PCT")

# 121002 -> 121k, 1000000 -> 1M. Integer only; k granularity is all that fits.
fmt() {
  if   [ "$1" -ge 1000000 ]; then printf '%dM' $(($1 / 1000000))
  elif [ "$1" -ge 1000 ];    then printf '%dk' $(($1 / 1000))
  else printf '%d' "$1"; fi
}

# ─── rate-limit windows ───────────────────────────────────────
# The subscription's rolling windows (Pro/Max): 5-hour and weekly, on the same
# green/yellow/red ladder as ctx so one glance covers every budget.
#
# BOTH are here on purpose. The 5h can sit in green all afternoon while the
# weekly is the one that actually runs out on you — either number alone tells
# half the story.
#
# ⚠️ Only a PERCENTAGE is on stdin — there is NO token count for either window,
# and it is not derivable: the limit weights models and output differently, so
# summing the transcript's tokens (what ccusage does) yields a different number
# wearing the same label. The % *is* the quantity here; `resets_at` is what
# makes it actionable.
#
# Everything is optional: `rate_limits` is absent for API-key users and until
# the first API response of the session, and each window can be absent on its
# own — hence `// empty` everywhere and one guard per window, not one for both.
#
# Only the 5h carries a countdown. `resets_at` exists for the weekly too, but
# "↻4d3h" is not a thing you act on and costs the same columns as the one that
# is. Epoch seconds rendered as time-REMAINING is pure arithmetic, so there's no
# `date -r` (BSD) vs `date -d @` (GNU) branch on a file both OSes symlink.
#
# ⚠️ The countdown only stays honest because `statusLine.refreshInterval` is set
# in claude/install/settings.sh — without it the status line re-runs on EVENTS
# only, so ↻ freezes exactly while you sit idle watching it.
LIMIT=""
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' | cut -d. -f1)
RESETS_AT=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
if [ -n "$FIVE_H" ]; then
  LIMIT=" | $(hue "$FIVE_H")5h ${FIVE_H}%"
  if [ -n "$RESETS_AT" ]; then
    MINS=$(((RESETS_AT - $(date +%s)) / 60))
    [ "$MINS" -ge 60 ] && LEFT="$((MINS / 60))h$((MINS % 60))m" || LEFT="${MINS}m"
    [ "$MINS" -gt 0 ] && LIMIT="${LIMIT} ↻${LEFT}"
  fi
  LIMIT="${LIMIT}${RESET}"
fi
[ -n "$WEEK" ] && LIMIT="${LIMIT} | $(hue "$WEEK")7d ${WEEK}%${RESET}"

BRANCH=""
git rev-parse --git-dir > /dev/null 2>&1 && BRANCH=" | ⎇ $(git branch --show-current 2>/dev/null)"

# Full path, not just the leaf — but with $HOME collapsed to `~`, the way every
# shell prompt does it. Nothing is lost (the path stays unambiguous) and a deep
# project saves ~15 columns.
DIR_FMT="${DIR/#$HOME/~}"
CTX_NUM="$(fmt "$USED")"
[ "$SIZE" -gt 0 ] && CTX_NUM="${CTX_NUM}/$(fmt "$SIZE")"

# Effort rides inside the model segment rather than getting its own `| … |`:
# it IS a model parameter, and the level names (low/medium/high/xhigh/max) can't
# be mistaken for part of the id.
MODEL_SEG="${CHIP} ${MODEL}"
[ -n "$EFFORT" ] && MODEL_SEG="${MODEL_SEG} ${EFFORT}"

echo -e "${NUM_COLOR}${MODEL_SEG}${RESET} | ${DIR_FMT}${BRANCH} | ctx ${NUM_COLOR}${CTX_NUM}${RESET}${LIMIT}"
echo
