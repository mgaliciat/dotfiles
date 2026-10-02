# Claude Code status line for NATIVE Windows — faithful port of
# claude/statusline.sh: same two zones, same segments, same colour ladder.
#   left  — WHERE you are:    model + effort, cwd, git branch
#   right — WHAT you've spent: the context bar, 5h quota
# The .sh is the CANONICAL file: every design decision (the bar's glyphs, why
# the quota is unlabelled, why EDGE_RESERVE exists)
# is documented there and deliberately NOT duplicated here. Comments below are
# only what is Windows-specific. If you change one file, change both.
#
# The one deliberate difference: the bar does NOT animate here. The animation
# needs a run per second, and a PowerShell start per second costs far more
# than the .sh's bash + jq, so install-windows.ps1 keeps refreshInterval at 60.
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
$Accent = "$ESC[94m"; $Red = "$ESC[31m"; $Reset = "$ESC[0m"
$Faint = "$ESC[2m"
# nf-md-brain sits above the BMP, past what one [char] holds, so it arrives as a
# surrogate pair that Get-VisibleWidth counts as 2. The right block lands one
# column further left than the .sh's — the undershooting side, which is safe.
$Brain = [char]::ConvertFromUtf32(0xF09D1)  # nf-md-brain
$Arrow = [char]0x2387  # ⎇
$Cycle = [char]0x21BB  # ↻ (reset countdown)
$Slab  = [char]0x2584  # ▄ filled cell of the context bar
$Rail  = [char]0x2581  # ▁ empty cell

# One ladder for every gauge on the line (ctx, quota), same as hue() in the .sh.
function Get-Hue([int]$v) {
    if ($v -ge 90) { $Red } else { $Accent }
}

$CtxColor = Get-Hue $Pct

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

# Query git against the workspace dir (not the process cwd) so the branch is
# correct regardless of where Claude Code spawns this from.
$Branch = ""
if ($Dir -and (git -C $Dir rev-parse --git-dir 2>$null)) {
    $b = git -C $Dir branch --show-current 2>$null
    if ($b) { $Branch = " | $Arrow $b" }
}

# $HOME collapsed to `~`, as in the .sh. StartsWith, not -replace: the path is
# a literal with backslashes, which a regex would read as escapes. StartsWith
# alone would also match C:\Users\bobby for HOME=C:\Users\bob and print
# `~by`, so the next character has to be a separator or the end of the path.
$DirFmt = if ($Dir -and $Dir.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase) -and
    ($Dir.Length -eq $HOME.Length -or ('\', '/') -contains [string]$Dir[$HOME.Length])) {
    "~" + $Dir.Substring($HOME.Length)
} else { $Dir }

# Filled cells: rounded, and never zero once the window holds anything.
function Get-Bar([int]$width) {
    $filled = 0
    if ($Size -gt 0) {
        $filled = [int][math]::Floor(($Used * $width * 2 + $Size) / ($Size * 2))
        if ($Used -gt 0 -and $filled -eq 0) { $filled = 1 }
        if ($filled -gt $width) { $filled = $width }
    }
    $out = ""
    if ($filled -gt 0)      { $out += "$CtxColor$([string]$Slab * $filled)$Reset" }
    if ($width -gt $filled) { $out += "$Faint$([string]$Rail * ($width - $filled))$Reset" }
    $out
}

$ModelSeg = "$CtxColor$Brain$Reset $Model"
if ($Effort) { $ModelSeg = "$ModelSeg $Effort" }

# ─── layout: meters flushed right ─────────────────────────────
# See the .sh for why EDGE_RESERVE is empirical and biased toward undershooting.
$EdgeReserve = 8
$Left  = "$ModelSeg | $DirFmt$Branch"
$Tail  = if ($Limit) { " | $Limit" } else { "" }

# Visible width: strip the zero-width colour escapes before counting.
function Get-VisibleWidth([string]$s) { ($s -replace "$ESC\[[0-9;]*m", "").Length }

# Bar between 8 and 20 cells, from whatever the rest of the line leaves.
$BarMax = 20; $BarMin = 8

# COLUMNS is exported by Claude Code (>= 2.1.153). [Console]::WindowWidth is NOT
# a fallback here: our stdout is a pipe, and with no console attached it throws.
# No width -> the inline ` | ` join, exactly like the .sh.
$Columns = 0
if ($env:COLUMNS) { $Columns = [int]$env:COLUMNS }
if ($Columns -gt 0) {
    $Room = [math]::Min($BarMax, $Columns - $EdgeReserve - (Get-VisibleWidth $Left) - (Get-VisibleWidth $Tail) - 3)
    $Right = if ($Room -ge $BarMin) { "$(Get-Bar $Room)$Tail" } else { $Limit }
    $Gap = $Columns - $EdgeReserve - (Get-VisibleWidth $Left) - (Get-VisibleWidth $Right)
    $Out = if (-not $Right) { $Left } elseif ($Gap -ge 3) { $Left + (" " * $Gap) + $Right } else { "$Left | $Right" }
} else {
    $Out = "$Left | $(Get-Bar 12)$Tail"
}

Write-Output $Out
Write-Output ""
