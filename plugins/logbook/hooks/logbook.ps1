# ─── PostToolUse hook: remind to write the logbook entry after a commit ───
#
# Windows twin of logbook.sh beside it — same contract, same output, rewritten
# because native Windows has no bash to run the .sh (the statusline.sh /
# statusline.ps1 split, for the same reason). The two are hand-kept in sync;
# nothing checks that automatically.
#
# Why a hook at all: a skill cannot fire on an event, only on what the user says.
# The entry is meant to be written after a commit lands, and "the model
# remembers to" is exactly the guarantee a prose rule does not give. This script
# holds the event half; the how-to half stays in the skill.
#
# Registered by install-windows.ps1 as ~/.claude/hooks/logbook.ps1.
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
    # negative costs the note. Same pattern as logbook.sh: global options may
    # precede `commit` — `-C <dir>` / `-c <key=val>` with a value that may be
    # quoted and hold spaces (`C:\Users\First Last`), and long ones like
    # `--no-pager` — and `commit-tree` / `committed` do not count. The c-prefixed
    # operators keep it case-sensitive like bash; plain -match / -like ignore case.
    if ($Cmd -cnotmatch 'git(\s+(-[cC]\s+([^\s"'']|"[^"]*"|''[^'']*'')+|--[\w-]+(=\S+)?))*\s+commit([^\w-]|$)') { exit 0 }
    if ($Cmd -clike '*--dry-run*') { exit 0 }

    # PostToolUse only fires on a tool call that SUCCEEDED (failures route to
    # PostToolUseFailure), so exit status is already handled. This catches the one
    # case that succeeds without producing a commit.
    # Serialized as JSON, like jq's `tostring` in logbook.sh — NOT Out-String,
    # which renders a console-width table and can wrap the phrase across lines.
    # -WarningAction: pwsh 7 warns when -Depth truncates, and a warning on the
    # host's stdout would break the JSON this script prints.
    $Response = ''
    if ($In.tool_response -is [string]) {
        $Response = $In.tool_response
    } elseif ($null -ne $In.tool_response) {
        $Response = $In.tool_response | ConvertTo-Json -Depth 5 -Compress -WarningAction SilentlyContinue
    }
    if ($Response -clike '*nothing to commit*') { exit 0 }

    # " - " where logbook.sh has an em dash, on purpose: powershell.exe (5.1) reads
    # a BOM-less script as ANSI, so a literal em dash would reach the model mangled.
    $Context = 'A git commit just landed. If this commit closes a meaningful unit of work (not a WIP step), invoke the `logbook:entry` skill now to write the per-invocation note - what changed and, above all, WHY, which the diff will not preserve. If it is a WIP step, say so in one line and skip it.'

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
