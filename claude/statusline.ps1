# Claude Code status line for NATIVE Windows: model, cwd, git branch,
# context-usage bar, session cost. Faithful port of claude/statusline.sh —
# same output, but no bash and no jq (both absent on native Windows: the only
# `bash` on PATH is WSL's, and Git Bash bundles no jq). mac/Linux keep using
# the .sh; this file is what install-windows.ps1 points the statusLine at.
# JSON session data arrives on stdin (see: https://code.claude.com/docs/en/statusline).
#
# Every non-ASCII glyph is built with [char] on purpose: this file has no BOM,
# so Windows PowerShell 5.1 reads it as the ANSI codepage — a literal █/░/⎇ in
# source would be corrupted on read. Codepoints survive that; literals don't.

# UTF-8 out is load-bearing too: PS 5.1 defaults stdout to the OEM codepage,
# which mangles those same glyphs on the way to Claude Code. Force UTF-8.
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false

$session = [Console]::In.ReadToEnd() | ConvertFrom-Json

$Model = $session.model.id
$Dir   = $session.workspace.current_dir
# `// 0` equivalents: a missing/null property is $null, and [int]$null is 0.
$Pct   = [int]$session.context_window.used_percentage
$Cost  = [double]$session.cost.total_cost_usd

$ESC   = [char]27
$Green = "$ESC[32m"; $Yellow = "$ESC[33m"; $Red = "$ESC[31m"; $Reset = "$ESC[0m"
$Chip  = [char]0xf2db  # nf-fa-microchip

$BarColor = if ($Pct -ge 90) { $Red } elseif ($Pct -ge 70) { $Yellow } else { $Green }

$BarWidth = 10
$Filled   = [int][math]::Floor($Pct * $BarWidth / 100)
$Empty    = $BarWidth - $Filled
$Full     = [char]0x2588  # █
$Light    = [char]0x2591  # ░
$Bar      = ("$Full" * $Filled) + ("$Light" * $Empty)

# Query git against the workspace dir (not the process cwd) so the branch is
# correct regardless of where Claude Code spawns this from.
$Branch = ""
if ($Dir -and (git -C $Dir rev-parse --git-dir 2>$null)) {
    $b = git -C $Dir branch --show-current 2>$null
    if ($b) { $Branch = " | $([char]0x2387) $b" }  # ⎇
}

$DirName = Split-Path $Dir -Leaf
$CostFmt = '$' + ('{0:N2}' -f $Cost)

Write-Output "$BarColor$Chip $Model$Reset | $DirName$Branch | ctx $BarColor$Bar$Reset $Pct% | $CostFmt"
Write-Output ""
