# Claude Code status line for NATIVE Windows — faithful port of
# claude/statusline.sh: same two zones, same segments, same colour ladder.
#   left  — WHERE you are:    model + effort, cwd, git branch
#   right — WHAT you've spent: ctx, session cost, 5h quota
# The .sh is the CANONICAL file: every design decision (why no gauge, why the
# quota is unlabelled, why cost is not colour-coded, why EDGE_RESERVE exists)
# is documented there and deliberately NOT duplicated here. Comments below are
# only what is Windows-specific. If you change one file, change both.
#
# No bash and no jq on native Windows (the only `bash` on PATH is WSL's, and
# Git Bash bundles no jq), hence PowerShell + ConvertFrom-Json.
# JSON session data arrives on stdin (see: https://code.claude.com/docs/en/statusline).
#
# Every non-ASCII glyph is built with [char] on purpose: this file has no BOM,
# so Windows PowerShell 5.1 reads it as the ANSI codepage — a literal ⎇/↻ in
# source would be corrupted on read. Codepoints survive that; literals don't.

# UTF-8 out is load-bearing too: PS 5.1 defaults stdout to the OEM codepage,
# which mangles those same glyphs on the way to Claude Code. Force UTF-8.
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false

$session = [Console]::In.ReadToEnd() | ConvertFrom-Json

# `// 0` equivalents throughout: a missing/null property is $null, and casting
# $null to a number yields 0. [math]::Floor mirrors the .sh's `cut -d. -f1`
# truncation — a plain [int] cast would round 42.7 up to 43.
$Model  = $session.model.id
$Dir    = $session.workspace.current_dir
$Pct    = [int][math]::Floor([double]$session.context_window.used_percentage)
$Used   = [long]$session.context_window.total_input_tokens
$Size   = [long]$session.context_window.context_window_size
$Effort = $session.effort.level

$ESC   = [char]27
$Green = "$ESC[32m"; $Yellow = "$ESC[33m"; $Red = "$ESC[31m"; $Reset = "$ESC[0m"
$Chip  = [char]0xf2db  # nf-fa-microchip
$Arrow = [char]0x2387  # ⎇
$Cycle = [char]0x21BB  # ↻ (reset countdown)

# One ladder for every gauge on the line (ctx, quota), same as hue() in the .sh.
function Get-Hue([int]$v) {
    if ($v -ge 90) { $Red } elseif ($v -ge 70) { $Yellow } else { $Green }
}

# 121002 -> 121k, 1000000 -> 1M. Integer division only, k granularity.
function Format-Tokens([long]$n) {
    if     ($n -ge 1000000) { "$([math]::Floor($n / 1000000))M" }
    elseif ($n -ge 1000)    { "$([math]::Floor($n / 1000))k" }
    else                    { "$n" }
}

$NumColor = Get-Hue $Pct

# ─── session quota (5h rolling window) ────────────────────────
$Limit = ""
$FiveH = $session.rate_limits.five_hour.used_percentage
if ($null -ne $FiveH) {
    $FiveH = [int][math]::Floor([double]$FiveH)
    $Limit = "$(Get-Hue $FiveH)$FiveH%"
    $ResetsAt = $session.rate_limits.five_hour.resets_at
    if ($null -ne $ResetsAt) {
        $Mins = [int][math]::Floor(([long]$ResetsAt - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) / 60)
        if ($Mins -gt 0) {
            $Remain = if ($Mins -ge 60) { "$([math]::Floor($Mins / 60))h$($Mins % 60)m" } else { "${Mins}m" }
            $Limit = "$Limit $Cycle$Remain"
        }
    }
    $Limit = "$Limit$Reset"
}

# ─── session cost ─────────────────────────────────────────────
# InvariantCulture, NOT '{0:N2}': N2 is culture-sensitive (es-MX renders 1234.5
# as "1,234.50") and would drift from the .sh's `printf '%.2f'`. F2 invariant
# gives the same string on every machine. Hidden below a cent, as in the .sh.
$Cost = [string]::Format([cultureinfo]::InvariantCulture, '{0:F2}', [double]$session.cost.total_cost_usd)
$CostSeg = if ($Cost -ne "0.00") { "`$$Cost" } else { "" }

# Query git against the workspace dir (not the process cwd) so the branch is
# correct regardless of where Claude Code spawns this from.
$Branch = ""
if ($Dir -and (git -C $Dir rev-parse --git-dir 2>$null)) {
    $b = git -C $Dir branch --show-current 2>$null
    if ($b) { $Branch = " | $Arrow $b" }
}

# $HOME collapsed to `~`, as in the .sh. StartsWith, not -replace: the path is
# a literal with backslashes, which a regex would read as escapes.
$DirFmt = if ($Dir -and $Dir.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase)) {
    "~" + $Dir.Substring($HOME.Length)
} else { $Dir }

$CtxNum = Format-Tokens $Used
if ($Size -gt 0) { $CtxNum = "$CtxNum/$(Format-Tokens $Size)" }

$ModelSeg = "$NumColor$Chip$Reset $Model"
if ($Effort) { $ModelSeg = "$ModelSeg $Effort" }

# ─── layout: meters flushed right ─────────────────────────────
# See the .sh for why EDGE_RESERVE is empirical and biased toward undershooting.
$EdgeReserve = 8
$Left  = "$ModelSeg | $DirFmt$Branch"
$Right = "ctx $NumColor$CtxNum$Reset"
if ($CostSeg) { $Right = "$Right | $CostSeg" }
if ($Limit)   { $Right = "$Right | $Limit" }

$Out = "$Left | $Right"

# Visible width: strip the zero-width colour escapes before counting.
function Get-VisibleWidth([string]$s) { ($s -replace "$ESC\[[0-9;]*m", "").Length }

# COLUMNS is exported by Claude Code (>= 2.1.153). [Console]::WindowWidth is NOT
# a fallback here: our stdout is a pipe, and with no console attached it throws.
# No width -> the inline ` | ` join, exactly like the .sh.
$Columns = 0
if ($env:COLUMNS) { $Columns = [int]$env:COLUMNS }
if ($Columns -gt 0) {
    $Gap = $Columns - $EdgeReserve - (Get-VisibleWidth $Left) - (Get-VisibleWidth $Right)
    if ($Gap -ge 3) { $Out = $Left + (" " * $Gap) + $Right }
}

Write-Output $Out
Write-Output ""
