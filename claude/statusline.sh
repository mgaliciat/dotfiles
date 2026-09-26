#!/bin/bash
# Claude Code status line, in two zones:
#   left  — WHERE you are:    model + effort, cwd, git branch
#   right — WHAT you've spent: the context bar, 5h quota
# The split is the whole layout decision (ago-2026). Everything on the right is
# a meter that only grows; everything on the left changes when you move. Reading
# order follows that: you scan left to orient, right to check the budget, and
# the two never interleave (ctx used to sit on the left, between branch and the
# quota — a gauge stranded in the identity half).
# JSON session data arrives on stdin (see: https://code.claude.com/docs/en/statusline).
shopt -s extglob   # needed by vis() to match an ANSI escape; see below

# ONE jq for every field, one value per line. This script runs every second
# (`statusLine.refreshInterval`, set by claude/install/settings.sh, is what
# drives the bar's animation), so it used to cost nine jq processes, a `cut`
# per percentage and a `date` for the countdown — per second. `now` gives the
# clock from inside jq, and `floor` does what the `cut -d.` did.
#
# Line-per-value rather than @tsv: `read` with a tab IFS collapses empty
# fields, and EFFORT / the quota are empty often.
{
  read -r MODEL
  read -r DIR
  read -r PCT
  read -r USED
  read -r SIZE
  read -r EFFORT
  read -r FIVE_H
  read -r RESETS_AT
  read -r SESSION
  read -r NOW
} < <(jq -r '
  (.model.id // ""),
  (.workspace.current_dir // ""),
  (.context_window.used_percentage // 0 | floor),
  (.context_window.total_input_tokens // 0),
  (.context_window.context_window_size // 0),
  # `effort.level` is the LIVE value — a mid-session `/effort` is reflected
  # here. Absent when the model has no effort parameter, and ultracode
  # reports as `xhigh` rather than a level of its own.
  (.effort.level // ""),
  (.rate_limits.five_hour.used_percentage // "" | if . == "" then . else floor end),
  (.rate_limits.five_hour.resets_at // ""),
  (.session_id // "" | gsub("[^A-Za-z0-9_-]"; "")),
  (now | floor)
')

# $'…' (ANSI-C quoting), NOT '\033[…m': these have to be REAL escape characters,
# not a backslash-0-3-3 string that only becomes an escape inside `echo -e`. The
# literal form cost 7 invisible-but-counted characters per reset in vis() below,
# which silently ate 28 columns of the right-alignment. One representation only.
#
# Colours are plain ANSI (not hex) on purpose: the active stack theme remaps
# them, so the statusline follows whatever Ghostty/tmux/nvim are wearing. FAINT
# right after a reset dims the theme's own foreground — the only "grey" that is
# readable on every palette in the family, since ANSI 8 is not (solarized-osaka
# mirrors its brights, so 8 is near-invisible there).
GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'
FAINT=$'\033[2m'
# Spelled as its UTF-8 bytes, never pasted: U+F2DB is a Private Use codepoint,
# which editors and tools drop in silence, leaving `$''` — an empty chip with
# nothing for the context hue to paint. `\xHH` rather than `` because
# macOS runs this under /bin/bash 3.2, which predates `\u`.
CHIP=$'\xef\x8b\x9b' # nf-fa-microchip, U+F2DB

# One ladder for every gauge on the line (ctx, quota) so a colour means the same
# thing wherever it appears — there used to be a copy of this `if` per gauge,
# which is how they drift apart.
hue() {
  if   [ "$1" -ge 90 ]; then printf '%s' "$RED"
  elif [ "$1" -ge 70 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"; fi
}

NUM_COLOR=$(hue "$PCT")

# 121002 -> 121k, 1000000 -> 1M. Integer only; k granularity is all that fits.
fmt() {
  if   [ "$1" -ge 1000000 ]; then printf '%dM' $(($1 / 1000000))
  elif [ "$1" -ge 1000 ];    then printf '%dk' $(($1 / 1000))
  else printf '%d' "$1"; fi
}

# ─── context bar ──────────────────────────────────────────────
# A half-height slab `▄` for the used part, riding on a thin rail `▁` for the
# rest: both are anchored to the bottom of the cell, so the fill reads as
# something laid ON the track rather than a second line beside it. Block
# elements, NOT the geometric shapes: Ghostty draws U+2580–259F itself as
# sprites, exactly one cell wide and seamless cell to cell in any font. The
# ■/◼/⬛ cubes of an earlier version here were font glyphs of ambiguous width,
# which is what broke the right-alignment and got the first bar removed.
#
# Why a rail and not a dimmed slab for the empty part: FAINT is the only
# theme-safe way to dim, and this config sets `faint-opacity = 0.7` — a faint
# slab sits too close to the lit one to read as empty. A 1/8-height stroke stays
# quiet at any opacity. The rail is the theme's foreground, not the ladder
# colour, so the fill is the only coloured thing in the bar.
#
# One step per cell (5% on 20 cells). The quadrant glyph that would give half
# steps leaves a hole in the rail under its empty half; the number beside the
# bar carries the precision anyway. The number stays (`121k/1M`): the bar
# answers "how full", the number "how much", and on a 1M window the bar alone
# reads as nearly empty for a whole session.
#
# THE ANIMATION: when the context grows, the cells it grew into rise and
# settle — a full block `█`, then three quarters `▆`, then the slab `▄` like the
# rest — in the ladder colour throughout. Height, not a colour flash: the only
# theme-safe "brighter" colour is the foreground, which some palettes keep
# muted on purpose (solarized-patched's #708284 read as an EMPTY cell next to
# the fill) and light palettes make dark. It only ever plays on growth: an idle
# session is a still bar, never a shimmer.
# The frames come from `statusLine.refreshInterval = 1`; each run of this
# script is one frame, drawn from the age of the last change.
#
# That age needs memory across runs: one small file per session under $TMPDIR
# holding "tokens-now changed-at tokens-before", read with `read` and written
# with `printf` so the state costs no process. A DROP in tokens is /compact or
# /clear: the file resets and nothing animates — the bar just jumps down.
state_dir="${TMPDIR:-/tmp}/claude-statusline-${UID}"
[[ -d $state_dir ]] || mkdir -p "$state_dir" 2>/dev/null
state_file="$state_dir/${SESSION:-default}"

last_used=0 changed_at=0 from_used=0
[[ -r $state_file ]] && read -r last_used changed_at from_used < "$state_file"
if (( USED > last_used )); then
  from_used=$last_used changed_at=$NOW
  printf '%s %s %s\n' "$USED" "$NOW" "$from_used" > "$state_file" 2>/dev/null
elif (( USED < last_used )); then
  from_used=$USED changed_at=0
  printf '%s %s %s\n' "$USED" 0 "$USED" > "$state_file" 2>/dev/null
fi
AGE=$(( NOW - changed_at ))

# cells(TOKENS, WIDTH): filled cells, rounded, never zero once there is
# anything in the window — an empty bar has to mean an empty context.
cells() {
  local n=0
  if (( SIZE > 0 )); then
    n=$(( ($1 * $2 * 2 + SIZE) / (SIZE * 2) ))
    (( $1 > 0 && n == 0 )) && n=1
    (( n > $2 )) && n=$2
  fi
  printf '%d' "$n"
}

# bar WIDTH → the rendered bar.
bar() {
  local width=$1 filled from=0 hot=0 out
  filled=$(cells "$USED" "$width")
  if (( changed_at > 0 && AGE < 2 && filled > 0 )); then
    from=$(cells "$from_used" "$width")
    # A turn often adds less than a cell (5k tokens on 1M is a tenth of one).
    # The head cell rises anyway, or the animation would be invisible exactly
    # when it is most frequent.
    (( from >= filled )) && from=$(( filled - 1 ))
    hot=$(( filled - from ))
  fi
  printf -v out '%*s' $(( filled - hot )) ''
  local lit=${out// /▄}
  printf -v out '%*s' "$hot" ''
  local rise='█'
  (( AGE == 1 )) && rise='▆'
  local flash=${out// /$rise}
  printf -v out '%*s' $(( width - filled )) ''
  local rail=${out// /▁}
  out=""
  [[ -n $lit ]]   && out+="${NUM_COLOR}${lit}${RESET}"
  [[ -n $flash ]] && out+="${NUM_COLOR}${flash}${RESET}"
  [[ -n $rail ]]  && out+="${FAINT}${rail}${RESET}"
  printf '%s' "$out"
}

# Left-padded to the widest value it can take (`199k/200k`, `999k/1M`), so the
# bar keeps its length and position as the count gains a digit — a gauge that
# shrinks when the number grows misstates its own proportion.
CTX_NUM="$(fmt "$USED")"
if [ "$SIZE" -gt 0 ]; then
  SIZE_FMT="$(fmt "$SIZE")"
  WIDEST="$(fmt $(( SIZE - 1 )))"
  (( ${#SIZE_FMT} > ${#WIDEST} )) && WIDEST=$SIZE_FMT
  CTX_NUM="${CTX_NUM}/${SIZE_FMT}"
  printf -v CTX_NUM '%*s' $(( ${#WIDEST} + 1 + ${#SIZE_FMT} )) "$CTX_NUM"
fi
CTX_NUM="${NUM_COLOR}${CTX_NUM}${RESET}"

# ─── session quota ────────────────────────────────────────────
# The subscription's rolling 5-hour window (Pro/Max), on the same
# green/yellow/red ladder as ctx.
#
# Rendered UNLABELLED — `37% ↻2h15m`, not `5h 37% ↻2h15m`. The countdown
# already says how much of the window is left, which is the only thing the "5h"
# was there to imply, and ↻ is what tells it apart from the ctx number.
#
# The weekly window (`.rate_limits.seven_day`, same two fields) was here and was
# dropped: it isn't a budget this user acts on. Add it back only if that
# changes — it is NOT missing by oversight.
#
# ⚠️ Only a PERCENTAGE is on stdin — there is NO token count for the window, and
# it is not derivable: the limit weights models and output differently, so
# summing the transcript's tokens (what ccusage does) yields a different number
# wearing the same label. The % *is* the quantity here; `resets_at` is what
# makes it actionable.
#
# Optional throughout: `rate_limits` is absent for API-key users and until the
# first API response of the session, and `resets_at` can be absent on its own —
# hence `// ""` on both and a guard each, so the % still renders without it.
#
# `resets_at` is epoch seconds rendered as time-REMAINING: pure arithmetic
# against jq's `now`, so no `date -r` (BSD) vs `date -d @` (GNU) branch on a
# file both OSes symlink.
LIMIT=""
if [ -n "$FIVE_H" ]; then
  LIMIT="$(hue "$FIVE_H")${FIVE_H}%"
  if [ -n "$RESETS_AT" ]; then
    MINS=$(((RESETS_AT - NOW) / 60))
    [ "$MINS" -ge 60 ] && REMAIN="$((MINS / 60))h$((MINS % 60))m" || REMAIN="${MINS}m"
    [ "$MINS" -gt 0 ] && LIMIT="${LIMIT} ↻${REMAIN}"
  fi
  LIMIT="${LIMIT}${RESET}"
fi

# `-C "$DIR"`: the branch of the directory this line SHOWS, not of whatever cwd
# Claude Code happened to launch us from — the two differ once the session
# moves. One git call, not two: outside a repo it fails, and on a detached HEAD
# it prints nothing, so an empty answer hides the segment in both cases instead
# of leaving a bare `⎇ `.
BRANCH=""
GIT_BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
[ -n "$GIT_BRANCH" ] && BRANCH=" | ⎇ ${GIT_BRANCH}"

# Full path, not just the leaf — but with $HOME collapsed to `~`, the way every
# shell prompt does it. Nothing is lost (the path stays unambiguous) and a deep
# project saves ~15 columns.
#
# A `case`, not `${DIR/#$HOME/~}`: bash 5.2 tilde-expands that replacement back
# into $HOME, so it collapses nothing, and a bare prefix match would turn
# /home/bobby into `~by` for HOME=/home/bob. The `/*` arm only matches at a path
# boundary. The quoted `~` is the literal character on purpose.
# shellcheck disable=SC2088
case $DIR in
  "$HOME"|"$HOME"/*) DIR_FMT="~${DIR#"$HOME"}" ;;
  *)                 DIR_FMT=$DIR ;;
esac

# Effort rides inside the model segment rather than getting its own `| … |`:
# it IS a model parameter, and the level names (low/medium/high/xhigh/max) can't
# be mistaken for part of the id.
#
# The context hue rides on the CHIP GLYPH ALONE, not on the model name. The
# whole segment used to be tinted, which read as "the model is red" — a colour
# saying something about a value that isn't in that segment. As a single leading
# dot it's ambient: peripheral pressure at the start of the line, with the exact
# figure over on the right where the meters live.
MODEL_SEG="${NUM_COLOR}${CHIP}${RESET} ${MODEL}"
[ -n "$EFFORT" ] && MODEL_SEG="${MODEL_SEG} ${EFFORT}"

# ─── layout: meters flushed right ─────────────────────────────
# What you're working ON stays left; every meter gets pushed to the far edge as
# one block, because they're a budget you glance at rather than something you
# read in sequence with the rest. The empty gap IS the separator between the two
# zones — that's why the ` | ` join below is only a fallback.
#
# COLUMNS is the only way to know the width: Claude Code captures our stdout
# instead of wiring it to the tty, so `tput cols` is blind from in here (docs:
# COLUMNS/LINES are exported for us, Claude Code >= 2.1.153). If it's ever
# missing — older build, or anything else piping into this script — we fall
# straight back to the inline ` | ` join instead of guessing a width.
#
# ⚠️ EDGE_RESERVE is EMPIRICAL — tune this number, not the arithmetic, if the
# line ever clips again. It started at 2 and Claude Code truncated the tail to
# `↻3h…`, because two separate widths are invisible from in here and they stack:
#
#   1. COLUMNS is the whole terminal, not this row. The status line renders
#      inside a bordered box with its own border and padding (what the `padding`
#      setting adds *to*), and that chrome's width is not on stdin.
#   2. Nerd Font glyphs count 1 CHARACTER but can render 2 CELLS. The chip,
#      ⎇ and ↻ are one codepoint each to `${#s}` and there is no way to ask the
#      terminal how wide the font drew them — the same ambiguous-width trap that
#      killed the ■/◼/⬛ cubes in an earlier version of this file.
#
# So the true usable width is COLUMNS minus an unknown, and the only safe move
# is to under-fill it. Overshooting costs a truncated tail with an ellipsis —
# visibly broken. Undershooting costs a slightly wider gap on a 164-column
# terminal — nobody can see it. Bias hard toward undershooting.
EDGE_RESERVE=8
LEFT="${MODEL_SEG} | ${DIR_FMT}${BRANCH}"

# Visible width: the colour escapes are zero-width and have to come out before
# counting, or the block would jump ~5 columns left the moment a gauge turns
# yellow. This is the reason the colours above are real escapes — one form to
# strip, and anything it misses is counted as if it were printable.
#
# `${#s}` counts CHARACTERS rather than bytes only under a UTF-8 locale. Claude
# Code runs us with LANG=en_US.UTF-8 (verified), which is what keeps the chip,
# ⎇, ↻, the bar's strokes and any non-ASCII cwd from counting 3:1 and dragging
# the block leftward.
vis() { local s=${1//$'\033'\[*([0-9;])m/}; printf '%d' "${#s}"; }

# The bar takes whatever the rest of the line leaves, up to BAR_MAX cells, and
# disappears below BAR_MIN — a stub of four cells says nothing the number does
# not. Meters ordered by scope, narrowest first: this turn's window (ctx), the
# rolling 5h window (%↻).
BAR_MAX=20 BAR_MIN=8
TAIL="$CTX_NUM"
[ -n "$LIMIT" ] && TAIL="${TAIL} | ${LIMIT}"

if [ -n "$COLUMNS" ]; then
  # 3 = the narrowest gap that still reads as separation, 1 = bar↔number space.
  ROOM=$((COLUMNS - EDGE_RESERVE - $(vis "$LEFT") - $(vis "$TAIL") - 3 - 1))
  (( ROOM > BAR_MAX )) && ROOM=$BAR_MAX
  RIGHT=$TAIL
  (( ROOM >= BAR_MIN )) && RIGHT="$(bar "$ROOM") ${TAIL}"
  GAP=$((COLUMNS - EDGE_RESERVE - $(vis "$LEFT") - $(vis "$RIGHT")))
  # Under 3 columns of gap it stops reading as separation and starts reading as
  # a typo, so a narrow terminal keeps the inline join. This doubles as the
  # no-wrap guard: a negative gap can never reach printf.
  if [ "$GAP" -ge 3 ]; then
    printf -v PAD '%*s' "$GAP" ''
    OUT="${LEFT}${PAD}${RIGHT}"
  else
    OUT="${LEFT} | ${RIGHT}"
  fi
else
  OUT="${LEFT} | $(bar 12) ${TAIL}"
fi

# Plain `echo`, no -e: every escape in $OUT is already a real one, so -e would
# only add a way for a backslash in a cwd or branch name to get interpreted.
echo "$OUT"
echo
