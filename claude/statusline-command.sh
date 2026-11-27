#!/bin/bash
# Claude Code status line meant to be changed from the chat with `/statusline`.
#
# ~/.claude/statusline-command.sh is a symlink to this file in the dotfiles
# repo, so a change made here shows up as a diff in ~/dotfiles to commit.
# Claude Code's Edit refuses to write through a symlink and names the target:
# edit that target, the repo file. Never replace the symlink with a regular
# file or write a second script. Keep it runnable by macOS's /bin/bash 3.2 (no \u
# escapes, no associative arrays, no ${var,,}), and keep it to one jq call.
#
# Starting design: craftzdog's tmux status line (craftzdog/dotfiles-public,
# dot_config/tmux/statusline.conf) as rounded Solarized pills.
#   left   model | effort, then git branch | cwd basename
#   right  context % and the 5h quota with its reset countdown
#   magenta on the branch and meter pills once context reaches 90%
# Needs jq, git, a 24-bit colour terminal and a Nerd Font for the caps.

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

# 24-bit hex on purpose: craftzdog's exact values, so this does not follow the
# stack theme the way statusline.sh (plain ANSI) does.
fg() { printf '\033[38;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
bg() { printf '\033[48;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
BASE2=eee8d5 BASE02=073642 BASE1=93a1a1 INK=15161e BLUE=278bd3 MAGENTA=d33682
BOLD=$'\033[1m' RESET=$'\033[0m'
# Private Use glyphs spelled as UTF-8 bytes: editors drop them when pasted.
L=$'\xee\x82\xb6'  # U+E0B6, left rounded cap
R=$'\xee\x82\xb4'  # U+E0B4, right rounded cap

# pill BG FG TEXT [NEXT_BG]: with NEXT_BG the right cap is drawn on the next
# pill's fill, which joins the two.
pill() {
  local out
  out="$(bg "$1")$(fg "$2")${BOLD} $3 ${RESET}"
  if [ -n "$4" ]; then out+="$(bg "$4")$(fg "$1")${R}"
  else                 out+="$(fg "$1")${R}${RESET}"; fi
  printf '%s' "$out"
}
cap() { printf '%s%s%s' "$(fg "$1")" "$L" "$RESET"; }

if [ -n "$EFFORT" ]; then
  LEFT="$(cap $BASE2)$(pill $BASE2 $BASE02 "$MODEL" $BASE1)$(pill $BASE1 $INK "$EFFORT")"
else
  LEFT="$(cap $BASE2)$(pill $BASE2 $BASE02 "$MODEL")"
fi

ACCENT=$BLUE METER_BG=$BASE1 METER_FG=$INK
if [ "$PCT" -ge 90 ]; then ACCENT=$MAGENTA METER_BG=$MAGENTA METER_FG=$BASE2; fi

# -C "$DIR": the branch of the directory shown, not of this script's cwd.
# --no-optional-locks: this runs every second beside the session's own git.
BRANCH=$(git --no-optional-locks -C "$DIR" branch --show-current 2>/dev/null)
LEAF=${DIR##*/}
[ -z "$LEAF" ] && LEAF=$DIR
if [ -n "$BRANCH" ]; then
  WIN="$(cap $ACCENT)$(pill $ACCENT $BASE2 "$BRANCH" $BASE2)$(pill $BASE2 $BASE02 "$LEAF")"
else
  WIN="$(cap $BASE2)$(pill $BASE2 $BASE02 "$LEAF")"
fi

# rate_limits is absent for API-key users and before the first response.
METER="ctx ${PCT}%"
if [ -n "$FIVE_H" ]; then
  METER="${METER} · 5h ${FIVE_H}%"
  if [ -n "$RESETS_AT" ]; then
    MINS=$(((RESETS_AT - NOW) / 60))
    if [ "$MINS" -ge 60 ]; then REMAIN="$((MINS / 60))h$((MINS % 60))m"; else REMAIN="${MINS}m"; fi
    [ "$MINS" -gt 0 ] && METER="${METER} ↻${REMAIN}"
  fi
fi
RIGHT="$(cap $METER_BG)$(pill $METER_BG $METER_FG "$METER")"

# Meters flush right when COLUMNS is known. EDGE_RESERVE covers the status
# box's border and padding, which COLUMNS does not account for.
EDGE_RESERVE=8
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

# No `echo -e`: a backslash in a branch or directory name must stay literal.
echo "$OUT"
