#!/usr/bin/env bash
# ─── tmux/reap-tabs.sh — a tab's session ends with its tab ────
#
#   reap-tabs.sh <client that just detached>
#
# Run by tmux.conf's client-detached hook. tmux itself keeps a session alive
# after its client is gone, so every Ghostty tab closed with ⌘W (or with the
# window, or by quitting Ghostty) would leave its session and the shell in it
# running where nothing shows them.
#
# zsh/.zshrc's auto-tmux stamps each session it creates with @tab_client, the
# client (the tab's tty) that owns it. This kills every stamped session that
# no client is attached to and whose owner is no longer connected. The owner
# and not "the session the client was on": the picker can switch a tab's
# client to another tab's session, and closing the tab must then take its own
# session with it, not the one it was visiting. For the same reason this is
# not `destroy-unattached`, which would kill a tab's session, and what runs in
# it, the moment its client looked elsewhere.
#
# Sessions without the stamp are never touched: the `claude-*` ones behind the
# popups are meant to outlive the tab (the picker lists them), and so is
# anything started by hand with `tmux new -s`.
set -uo pipefail

gone="${1:-}"
clients="$(tmux list-clients -F '#{client_name}' 2>/dev/null)"

tmux list-sessions -F '#{session_attached}	#{session_id}	#{@tab_client}' 2>/dev/null |
  while IFS=$'\t' read -r attached id owner; do
    [[ -n "$owner" && "$attached" == 0 ]] || continue
    # The hook can run before the server has dropped the client that left.
    if [[ "$owner" != "$gone" ]] && grep -qxF -- "$owner" <<<"$clients"; then
      continue
    fi
    tmux kill-session -t "$id" 2>/dev/null
  done
exit 0
