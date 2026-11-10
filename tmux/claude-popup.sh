#!/usr/bin/env bash
# ─── tmux/claude-popup.sh — Claude Code for a directory, in a tmux popup ──
#
#   claude-popup.sh <variant> <dir> <origin-window> <session> <client> [args]
#   claude-popup.sh ask <variant> <session> <client>
#   claude-popup.sh hold <command>
#
# Launches a detached tmux session running Claude in <dir>, or re-attaches to
# the one already there, and shows it in a popup over <client>. Closing the
# popup leaves Claude running. Everything after <variant> is a tmux format the
# bind expands (tmux.conf's Alt+c / Alt+a).
#
# Variants, each in sessions of its own so one directory can run both side by
# side:
#   plain     claude                   claude-<hash>
#   api       claude-api-env claude    claude-api-<hash>
#
# WITH ARGUMENTS. `ask` (tmux.conf's prefix + the same two keys) puts the
# variant's whole command on tmux's prompt line, `caffeinate -di claude ` for
# plain, with `-w ` already typed after it: finish the line the way you would
# in a shell and Enter calls this script back with it as [args]. So `name-wt`
# and Enter is `caffeinate -di claude -w name-wt`, Claude in a git worktree of
# its own making, in the popup. [args] is shell text, appended to the command
# as typed: a quoted prompt stays one word, and a `#1234` needs its quotes.
# Each distinct [args] is a session of its own (the hash covers the directory
# and the text), so the directory's plain Claude and each of its worktrees run
# side by side and the same line typed again re-attaches. Nothing typed is the
# plain launch.
#
# A typed line can be wrong where the fixed commands cannot (`-w` outside a
# repo, a flag that does not exist), and Claude's error would go down with the
# session, leaving a popup that flashes. So a session with [args] runs through
# this script (`hold`), which keeps a command that ended at once on screen
# until Enter.
#
# HOW IT FITS tmux-claude-hatch. `plain` is the very session the plugin's own
# launcher makes (same prefix, same hash of the path), and every name starts
# with `claude-`, the plugin's @claude_session_prefix. So its picker resumes
# all of them as its own sessions, its bell forwarding reads the @claude_origin
# set here, and Alt+d detaches from them. The launcher is ours because the
# plugin has one command for every launch (@claude_command, a single word its
# picker checks with `command -v`): no variants, and no `caffeinate`.
set -uo pipefail

# The session's own command when [args] were typed: `hold <command>`.
if [[ ${1:-} == hold ]]; then
  "${SHELL:-/bin/sh}" -c "${2:-}"
  rc=$?
  # SECONDS counts from this script's start. Under 5 is a start that failed,
  # or a `--version`: either way something to read before the popup goes.
  if ((SECONDS < 5)); then
    printf '\n[ended at once, exit %s — Enter closes] ' "$rc"
    read -r _
  fi
  exit "$rc"
fi

ask=''
if [[ ${1:-} == ask ]]; then
  ask=1
  # The prompt's callback fills in <dir> and <origin-window>.
  set -- "${2:-}" '' '' "${3:-}" "${4:-}"
fi

variant="${1:-plain}"
dir="${2:-$PWD}"
window="${3:-}"
current="${4:-}"
client="${5:-}"
args="${6:-}"
# The option was only how the prompt's answer got here.
(($# >= 6)) && tmux set-option -gu @claude_popup_args 2>/dev/null
# Trimmed, so a trailing space does not make a second session.
args="${args#"${args%%[![:space:]]*}"}"
args="${args%"${args##*[![:space:]]}"}"

case "$variant" in
plain) infix='' title='Claude' cmd='claude' ;;
api) infix='api-' title='Claude | API' cmd='claude-api-env claude' ;;
*)
  tmux display-message "claude-popup: unknown variant '$variant'"
  exit 0
  ;;
esac

# The key pressed inside a Claude popup: a popup over the popup is never what
# it meant.
case "$current" in claude-*) exit 0 ;; esac

# While Claude runs, detached included, the Mac neither idle-sleeps (-i) nor
# lets the display sleep (-d, which would lock the screen mid-run). The
# assertion is the process's own, so it ends with Claude.
command -v caffeinate >/dev/null 2>&1 && cmd="caffeinate -di $cmd"

# A gateway launch that cannot start (no ~/.claude/claude-api.env, no
# ANTHROPIC_BASE_URL in it, the helper not on PATH) would take its session
# and its error down together, leaving a popup that flashes. `true` through
# the helper runs the same checks first, and tmux shows what it said.
api_ready() {
  local err
  [[ $variant == api* ]] || return 0
  err="$(claude-api-env true 2>&1)" && return 0
  err="${err% — not launching true}"
  tmux display-message -d 5000 "${err:-claude-api-env failed}"
  return 1
}

if [[ -n $ask ]]; then
  # Before the typing, not after it.
  api_ready || exit 0
  prompt=(tmux command-prompt)
  [[ -n "$client" ]] && prompt+=(-t "$client")
  # The answer goes through an option and back out with `#{q:…}`: `%%%` is
  # escaped for tmux's double quotes only, and q is what makes it one safe
  # shell word, whatever was typed. The formats are run-shell's to expand, on
  # Enter. $variant is one of the two words above.
  "${prompt[@]}" -I '-w ' -p "$cmd" \
    "set-option -g @claude_popup_args \"%%%\" ; run-shell \"~/.config/tmux/claude-popup.sh $variant #{q:pane_current_path} #{q:window_id} #{q:session_name} #{q:client_name} #{q:@claude_popup_args}\""
  exit 0
fi

# The plugin's session_hash: md5 of the path plus a newline, first 8 hex
# digits, md5sum before macOS's md5. With [args] the hash covers them too.
key="$dir"
[[ -n "$args" ]] && key+=$'\n'"$args"
if command -v md5sum >/dev/null 2>&1; then
  hash="$(printf '%s\n' "$key" | md5sum)"
else
  hash="$(printf '%s\n' "$key" | md5 -q)"
fi
session="claude-${infix}${hash:0:8}"

# `=` is an exact match; a bare name also matches by prefix. The trailing `:`
# in the set-option targets is what lets them take the `=`.
if ! tmux has-session -t "=$session" 2>/dev/null; then
  [[ -d "$dir" ]] || {
    tmux display-message "claude-popup: $dir no longer exists"
    exit 0
  }
  api_ready || exit 0
  if [[ -n "$args" ]]; then
    # Several words after the options: tmux executes them as they are, no
    # shell in between, so the typed text is parsed once, by `hold`'s shell.
    tmux new-session -d -s "$session" -c "$dir" \
      "$HOME/.config/tmux/claude-popup.sh" hold "$cmd $args"
  else
    tmux new-session -d -s "$session" -c "$dir" "$cmd"
  fi
fi

# Close the popup when Claude exits, even under a global detach-on-destroy off.
tmux set-option -t "=$session:" detach-on-destroy on
# The window that launched it: where the plugin's picker jumps back to, and
# the one its bell forwarding flags.
[[ -n "$window" ]] && tmux set-option -t "=$session:" @claude_origin "$window"

# The arguments in the title say which of the directory's Claudes this is.
# `#` doubled: the title is a tmux format.
if [[ -n "$args" ]]; then
  shown="$args"
  ((${#shown} > 40)) && shown="${shown:0:39}…"
  title+=" | ${shown//#/##}"
fi

popup=(tmux display-popup)
[[ -n "$client" ]] && popup+=(-c "$client")
"${popup[@]}" -w 90% -h 90% -T " $title " -E "tmux attach-session -t '=$session'"
