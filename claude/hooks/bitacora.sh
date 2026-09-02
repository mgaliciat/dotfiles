#!/usr/bin/env bash
# ─── PostToolUse hook: remind to log the bitácora after a commit ───
#
# A skill cannot fire on an event — it only self-activates on what the user says.
# The bitácora is supposed to be written after a commit lands, and "the model
# remembers to" is exactly the guarantee a prose rule in CLAUDE.md does not give.
# So the event half lives here and the how-to half stays in the skill: this script
# only detects the commit and hands back one line of context.
#
# Installed by claude/install/settings.sh as ~/.claude/hooks/bitacora.sh (symlink)
# and invoked as `bash ~/.claude/hooks/bitacora.sh` — through bash on purpose, so
# a fresh clone with no exec bit still runs. Windows has its own .ps1 twin
# (install-windows.ps1 registers that one); this file never runs there.
#
# Contract: hook input arrives as JSON on stdin, and stdout is read back as JSON.
# `hookSpecificOutput.additionalContext` is the field that reaches the model —
# plain stdout would only show up in transcript view, which nobody reads mid-turn.
# ANY other output breaks the parse, so every failure path below must exit silent.

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

INPUT="$(cat)"

TOOL="$(jq -r '.tool_name // ""' <<<"$INPUT" 2>/dev/null)" || exit 0
CMD="$(jq -r '.tool_input.command // ""' <<<"$INPUT" 2>/dev/null)" || exit 0

# Both tool names on purpose: settings.json sets CLAUDE_CODE_USE_POWERSHELL_TOOL
# on Windows, and a session that inherits that env var elsewhere routes commits
# through PowerShell instead of Bash. Matching only "Bash" would go quietly dead.
case "$TOOL" in
  Bash | PowerShell) ;;
  *) exit 0 ;;
esac

# `git commit` anywhere in the command: it is routinely the tail of a chain
# (`git add -A && git commit -m ...`). Deliberately loose — a false positive costs
# one line of context, a false negative costs the note.
[[ "$CMD" == *"git commit"* ]] || exit 0

# --dry-run writes nothing, so there is nothing to log about it.
[[ "$CMD" == *"--dry-run"* ]] && exit 0

# PostToolUse only fires on a tool call that SUCCEEDED (a failure routes to
# PostToolUseFailure), so exit status is already handled. This catches the one
# case that succeeds without producing a commit.
RESPONSE="$(jq -r '.tool_response | if type == "string" then . else tostring end' <<<"$INPUT" 2>/dev/null)" || RESPONSE=""
[[ "$RESPONSE" == *"nothing to commit"* ]] && exit 0

jq -n '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: "A git commit just landed. If this commit closes a meaningful unit of work (not a WIP step), invoke the `bitacora` skill now to write the per-invocation note — what changed and, above all, WHY, which the diff will not preserve. If it is a WIP step, say so in one line and skip it."
  }
}'
