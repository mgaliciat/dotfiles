#!/usr/bin/env bash
# ─── tmux/reap-sessions.sh — no session left running unseen ───
#
#   reap-sessions.sh [client that just detached]
#
# Run by tmux.conf's client-attached and client-detached hooks, so on every
# tab opened or closed and every popup opened or closed. tmux itself keeps a
# session alive after its client is gone; this ends the two kinds that would
# otherwise pile up where nothing shows them.
#
# 1. A TAB'S SESSION, WHEN ITS TAB IS GONE. Every Ghostty tab closed with ⌘W
#    (or with the window, or by quitting Ghostty) would leave its session and
#    the shell in it behind. zsh/.zshrc's auto-tmux stamps each session it
#    creates with @tab_client, the client (the tab's tty) that owns it; a
#    stamped session that no client is attached to and whose owner is no
#    longer connected is killed. The owner and not "the session the client
#    was on": the picker can switch a tab's client to another tab's session,
#    and closing the tab must then take its own session with it, not the one
#    it was visiting. For the same reason this is not `destroy-unattached`,
#    which would kill a tab's session, and what runs in it, the moment its
#    client looked elsewhere.
#
# 2. A CLAUDE NOBODY CAME BACK TO. The `claude-*` sessions behind the popups
#    outlive the tab on purpose, and each keeps the Mac awake while it lives.
#    One left detached for @claude_idle_days (tmux.conf) is killed. The clock
#    is tmux's session_activity, the last time a client attached to it or
#    typed in it: what Claude prints on its own does not move it, so a run
#    you never look at again still ends. The conversation is not lost, only
#    the process: `claude --resume` in that directory brings it back.
#
# Anything else (a session started by hand with `tmux new -s`) is never
# touched.
set -uo pipefail

gone="${1:-}"
clients="$(tmux list-clients -F '#{client_name}' 2>/dev/null)"

days="$(tmux show-option -gqv @claude_idle_days 2>/dev/null)"
# Unset, 0 or not a number: no age limit.
[[ "$days" =~ ^[0-9]+$ ]] || days=0
now="$(date +%s)"

# `|` between the fields, not a tab: outside a UTF-8 locale tmux prints control
# characters as `_`. The name goes last, so a `|` in it stays in it.
tmux list-sessions -F '#{session_attached}|#{session_id}|#{session_activity}|#{@tab_client}|#{session_name}' 2>/dev/null |
  while IFS='|' read -r attached id activity owner name; do
    [[ "$attached" == 0 ]] || continue
    if [[ -n "$owner" ]]; then
      # The hook can run before the server has dropped the client that left.
      if [[ "$owner" != "$gone" ]] && grep -qxF -- "$owner" <<<"$clients"; then
        continue
      fi
    elif [[ "$name" == claude-* ]]; then
      ((days > 0 && now - activity > days * 86400)) || continue
    else
      continue
    fi
    tmux kill-session -t "$id" 2>/dev/null
  done
exit 0
