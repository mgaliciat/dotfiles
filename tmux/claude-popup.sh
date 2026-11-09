#!/usr/bin/env bash
# ─── tmux/claude-popup.sh — Claude Code for a directory, in a tmux popup ──
#
#   claude-popup.sh <variant> <dir> <origin-window> <session> <client>
#
# Launches a detached tmux session running Claude in <dir>, or re-attaches to
# the one already there, and shows it in a popup over <client>. Closing the
# popup leaves Claude running. Everything after <variant> is a tmux format the
# bind expands (tmux.conf's Alt+c / Alt+C / Alt+a / Alt+A).
#
# Variants, each in sessions of its own so one directory can run them side by
# side:
#   plain     claude                                  claude-<hash>
#   yolo      claude --dangerously-skip-permissions   claude-yolo-<hash>
#   api       claude-api-env claude                   claude-api-<hash>
#   api-yolo  the two together                        claude-api-yolo-<hash>
#
# HOW IT FITS tmux-claude-hatch. `plain` is the very session the plugin's own
# launcher makes (same prefix, same hash of the path), and every name starts
# with `claude-`, the plugin's @claude_session_prefix. So its picker resumes
# all four as its own sessions, its bell forwarding reads the @claude_origin
# set here, and Alt+d detaches from them. The launcher is ours because the
# plugin has one command for every launch (@claude_command, a single word its
# picker checks with `command -v`): no variants, and no `caffeinate`.
set -uo pipefail

variant="${1:-plain}"
dir="${2:-$PWD}"
window="${3:-}"
current="${4:-}"
client="${5:-}"

case "$variant" in
plain) infix='' title='Claude' cmd='claude' ;;
yolo) infix='yolo-' title='Claude | Bypass Permissions' cmd='claude --dangerously-skip-permissions' ;;
api) infix='api-' title='Claude | API' cmd='claude-api-env claude' ;;
api-yolo) infix='api-yolo-' title='Claude | API | Bypass Permissions' cmd='claude-api-env claude --dangerously-skip-permissions' ;;
*)
  tmux display-message "claude-popup: unknown variant '$variant'"
  exit 0
  ;;
esac

# The key pressed inside a Claude popup: a popup over the popup is never what
# it meant.
case "$current" in claude-*) exit 0 ;; esac

# The plugin's session_hash: md5 of the path plus a newline, first 8 hex
# digits, md5sum before macOS's md5.
if command -v md5sum >/dev/null 2>&1; then
  hash="$(printf '%s\n' "$dir" | md5sum)"
else
  hash="$(printf '%s\n' "$dir" | md5 -q)"
fi
session="claude-${infix}${hash:0:8}"

# `=` is an exact match; a bare name also matches by prefix. The trailing `:`
# in the set-option targets is what lets them take the `=`.
if ! tmux has-session -t "=$session" 2>/dev/null; then
  [[ -d "$dir" ]] || {
    tmux display-message "claude-popup: $dir no longer exists"
    exit 0
  }
  # A gateway launch that cannot start (no ~/.claude/claude-api.env, no
  # ANTHROPIC_BASE_URL in it, the helper not on PATH) would take its session
  # and its error down together, leaving a popup that flashes. `true` through
  # the helper runs the same checks first, and tmux shows what it said.
  if [[ $variant == api* ]]; then
    err="$(claude-api-env true 2>&1)" || {
      err="${err% — not launching true}"
      tmux display-message -d 5000 "${err:-claude-api-env failed}"
      exit 0
    }
  fi
  # While Claude runs, detached included, the Mac neither idle-sleeps (-i) nor
  # lets the display sleep (-d, which would lock the screen mid-run). The
  # assertion is the process's own, so it ends with Claude.
  command -v caffeinate >/dev/null 2>&1 && cmd="caffeinate -di $cmd"
  tmux new-session -d -s "$session" -c "$dir" "$cmd"
fi

# Close the popup when Claude exits, even under a global detach-on-destroy off.
tmux set-option -t "=$session:" detach-on-destroy on
# The window that launched it: where the plugin's picker jumps back to, and
# the one its bell forwarding flags.
[[ -n "$window" ]] && tmux set-option -t "=$session:" @claude_origin "$window"

popup=(tmux display-popup)
[[ -n "$client" ]] && popup+=(-c "$client")
"${popup[@]}" -w 90% -h 90% -T " $title " -E "tmux attach-session -t '=$session'"
