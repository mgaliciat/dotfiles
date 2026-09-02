# ─── PostToolUse hook: remind to log the bitácora after a commit ───
#
# Windows twin of claude/hooks/bitacora.sh — same contract, same output, rewritten
# because native Windows has no bash to run the .sh (the statusline.sh /
# statusline.ps1 split, for the same reason). The two are hand-kept in sync;
# nothing checks that automatically.
#
# Why a hook at all: a skill cannot fire on an event, only on what the user says.
# The bitácora is meant to be written after a commit lands, and "the model
# remembers to" is exactly the guarantee a prose rule does not give. This script
# holds the event half; the how-to half stays in the skill.
#
# Registered by install-windows.ps1 as ~/.claude/hooks/bitacora.ps1.
#
# Contract: input arrives as JSON on stdin, stdout is parsed back as JSON, and
# `hookSpecificOutput.additionalContext` is the only field that reaches the model.
# ANY other output breaks that parse, so every failure path must exit silent —
# hence the single try/catch around the whole thing.

$ErrorActionPreference = 'Stop'

try {
    $Raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($Raw)) { exit 0 }

    $In = $Raw | ConvertFrom-Json

    # Both tool names on purpose: this machine sets CLAUDE_CODE_USE_POWERSHELL_TOOL,
    # so commits normally route through PowerShell, but a session without it (or
    # one driving Git Bash) uses Bash. Matching one would go quietly dead.
    if ($In.tool_name -ne 'Bash' -and $In.tool_name -ne 'PowerShell') { exit 0 }

    $Cmd = [string]$In.tool_input.command
    if ([string]::IsNullOrWhiteSpace($Cmd)) { exit 0 }

    # `git commit` anywhere in the command: it is routinely the tail of a chain.
    # Deliberately loose — a false positive costs one line of context, a false
    # negative costs the note.
    if ($Cmd -notlike '*git commit*') { exit 0 }
    if ($Cmd -like '*--dry-run*') { exit 0 }

    # PostToolUse only fires on a tool call that SUCCEEDED (failures route to
    # PostToolUseFailure), so exit status is already handled. This catches the one
    # case that succeeds without producing a commit.
    $Response = ''
    if ($null -ne $In.tool_response) { $Response = ($In.tool_response | Out-String) }
    if ($Response -like '*nothing to commit*') { exit 0 }

    $Context = 'A git commit just landed. If this commit closes a meaningful unit of work (not a WIP step), invoke the `bitacora` skill now to write the per-invocation note - what changed and, above all, WHY, which the diff will not preserve. If it is a WIP step, say so in one line and skip it.'

    # -Depth 3: the default of 2 in Windows PowerShell 5.1 stringifies the nested
    # object into "System.Collections.Hashtable" instead of serializing it.
    [pscustomobject]@{
        hookSpecificOutput = [pscustomobject]@{
            hookEventName     = 'PostToolUse'
            additionalContext = $Context
        }
    } | ConvertTo-Json -Depth 3 -Compress
} catch {
    exit 0
}
