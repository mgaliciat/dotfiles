#!/bin/bash
# Claude Code status line: model, cwd, git branch, context-usage cubes, session cost.
# JSON session data arrives on stdin (see: https://code.claude.com/docs/en/statusline).
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.id')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
USED=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

# ─── context cubes ────────────────────────────────────────────
# Cubes are coloured by WHERE they sit in the window, not by when they filled:
# the first six are green, the seventh yellow, the last red. So the colour of
# the leading cube tells you how close to full you are, and the danger zone is
# a fixed place on the bar rather than a state you have to read off a number.
#
# This replaced an earlier cyan/magenta split (accumulated vs. added-this-turn).
# Both don't fit — a cube is one glyph and gets one colour. The data for that
# split is still on stdin if it's ever wanted back: `current_usage` breaks into
# cache_read (everything before this turn) + cache_creation (what this turn
# added) + input, summing exactly to total_input_tokens.
#
# ⚠️ What is NOT available at all is the `/context` category breakdown (system
# prompt / system tools / MCP tools / skills / memory / messages). Claude Code
# computes that internally and never puts it on stdin — don't try to colour by
# category, the data isn't there.
#
# Colours are plain ANSI (not hex) on purpose: the active stack theme remaps
# them, so the statusline follows whatever Ghostty/tmux/nvim are wearing.

GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; GRAY='\033[90m'; RESET='\033[0m'
CHIP=$'' # nf-fa-microchip

# Each cube fills in 8 sub-steps before the next one starts — a cube grows from
# a sliver to full, then the next is born. That's not decoration: with a 1M
# window you sit at ~12% for a whole session, so a plain 8-cube bar lights ONE
# cube and never visibly moves. 8 cubes x 8 levels = 64 steps of resolution in
# the same width.
#
# Every glyph here is Block Elements (U+2581-2588, U+258F, U+2595), which
# terminal fonts render single-width. ■/◼/⬛/▢ are ambiguous-width and would
# drift the alignment of everything to their right — don't "upgrade" to them.
# An empty cube is drawn as its two side walls (`▏` = bar on the cell's left,
# `▕` = bar on the cell's right), so it reads as an empty slot with a grey
# border rather than a blank gap.
LEVELS=('' '▁' '▂' '▃' '▄' '▅' '▆' '▇' '█')
EMPTY='▏▕'
CUBES=8; SUB=8
WIDTH=2          # cells per cube — the whole point is that they read as chunky
TICKS=$((CUBES * SUB))

# The number is absolute (121k/1M), not a percentage: on a 1M window "12%" is
# not a quantity you can act on, while "121k" is. It carries the same
# green/yellow/red thresholds as the cubes so both agree.
if   [ "$PCT" -ge 90 ]; then NUM_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then NUM_COLOR="$YELLOW"
else NUM_COLOR="$GREEN"; fi

FILLED=$((PCT * TICKS / 100))
# Round any non-zero usage up to one tick: "5% with nothing lit" reads as broken.
[ "$PCT" -gt 0 ] && [ "$FILLED" -eq 0 ] && FILLED=1

BAR=""
for ((i = 0; i < CUBES; i++)); do
  start=$((i * SUB))
  lvl=$((FILLED - start))
  [ "$lvl" -lt 0 ] && lvl=0
  [ "$lvl" -gt "$SUB" ] && lvl=$SUB

  if [ "$lvl" -eq 0 ]; then
    BAR="${BAR}${GRAY}${EMPTY}"
  else
    # Threshold on the percentage the cube ENDS at — i.e. its worst point —
    # giving 5 green, 2 yellow (>=70%), 1 red (>=90%). Judging by the midpoint
    # instead put the bar's yellow at 75% while the number's was at 70%, so at
    # 75% you got a yellow number over an all-green bar. Ending-edge makes the
    # bar lead the number by up to 7.5% instead, which is the safe direction
    # for a "you're filling up" cue: warn early, never late.
    end=$(((start + SUB) * 100 / TICKS))
    if   [ "$end" -ge 90 ]; then colour=$RED
    elif [ "$end" -ge 70 ]; then colour=$YELLOW
    else colour=$GREEN; fi
    printf -v cube "%${WIDTH}s"
    BAR="${BAR}${colour}${cube// /${LEVELS[$lvl]}}"
  fi
  [ "$i" -lt $((CUBES - 1)) ] && BAR="${BAR} "
done
BAR="${BAR}${RESET}"

# 121002 -> 121k, 1000000 -> 1M. Integer only; k granularity is all that fits.
fmt() {
  if   [ "$1" -ge 1000000 ]; then printf '%dM' $(($1 / 1000000))
  elif [ "$1" -ge 1000 ];    then printf '%dk' $(($1 / 1000))
  else printf '%d' "$1"; fi
}

BRANCH=""
git rev-parse --git-dir > /dev/null 2>&1 && BRANCH=" | ⎇ $(git branch --show-current 2>/dev/null)"

COST_FMT=$(printf '$%.2f' "$COST")
# Full path, not just the leaf — but with $HOME collapsed to `~`, the way every
# shell prompt does it. Nothing is lost (the path stays unambiguous) and a deep
# project saves ~15 columns on a line that already carries 8 cubes.
DIR_FMT="${DIR/#$HOME/~}"
CTX_NUM="$(fmt "$USED")"
[ "$SIZE" -gt 0 ] && CTX_NUM="${CTX_NUM}/$(fmt "$SIZE")"

echo -e "${NUM_COLOR}${CHIP} ${MODEL}${RESET} | ${DIR_FMT}${BRANCH} | ctx ${BAR} ${NUM_COLOR}${CTX_NUM}${RESET} | ${COST_FMT}"
echo
