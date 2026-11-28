# Claude Code status line for NATIVE Windows -- port of
# claude/statusline-command.sh (craftzdog's tmux pills). The .sh is the
# CANONICAL file: the design and its reasons are written there and not repeated
# here. Comments below are only what is Windows-specific. `/statusline` edits
# whichever of the two the machine's statusLine points at, so a change made
# from the chat lands in one file only: carry it to the other by hand.
#
# ~/.claude/statusline-command.ps1 is a symlink to this file (install-windows.ps1),
# so, as on the Mac, an edit through `/statusline` shows up as a diff in the repo.
#
# No bash and no jq on native Windows, hence PowerShell + ConvertFrom-Json.
# The file is pure ASCII on purpose: it has no BOM, so Windows PowerShell 5.1
# reads it as the ANSI codepage. Every glyph is built from its codepoint.
# Needs git, a 24-bit colour terminal (Windows Terminal) and a Nerd Font.

# PS 5.1 writes stdout in the OEM codepage, which mangles the caps. Force UTF-8.
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false

$session = [Console]::In.ReadToEnd() | ConvertFrom-Json

# The jq `//` fallbacks: a missing property is $null, and casting $null to a
# number gives 0. [math]::Floor, not an [int] cast, which would round 42.7 up.
$Model = $session.model.display_name
if (-not $Model) { $Model = $session.model.id }
$Dir = $session.workspace.current_dir
if (-not $Dir) { $Dir = $session.cwd }
$Pct    = [int][math]::Floor([double]$session.context_window.used_percentage)
$Effort = $session.effort.level
$FiveH  = $session.rate_limits.five_hour.used_percentage
$ResetsAt = $session.rate_limits.five_hour.resets_at

$ESC = [char]27
function Get-Fg([string]$hex) { "$ESC[38;2;$([Convert]::ToInt32($hex.Substring(0,2),16));$([Convert]::ToInt32($hex.Substring(2,2),16));$([Convert]::ToInt32($hex.Substring(4,2),16))m" }
function Get-Bg([string]$hex) { "$ESC[48;2;$([Convert]::ToInt32($hex.Substring(0,2),16));$([Convert]::ToInt32($hex.Substring(2,2),16));$([Convert]::ToInt32($hex.Substring(4,2),16))m" }
$Base2 = 'eee8d5'; $Base02 = '073642'; $Base1 = '93a1a1'; $Ink = '15161e'
$Blue = '278bd3'; $Magenta = 'd33682'
$Bold = "$ESC[1m"; $Reset = "$ESC[0m"
$L     = [char]0xE0B6  # left rounded cap
$R     = [char]0xE0B4  # right rounded cap
$Dot   = [char]0x00B7  # middle dot
$Cycle = [char]0x21BB  # reset countdown

function Get-Pill([string]$bgc, [string]$fgc, [string]$text, [string]$next) {
    $out = "$(Get-Bg $bgc)$(Get-Fg $fgc)$Bold $text $Reset"
    if ($next) { $out + "$(Get-Bg $next)$(Get-Fg $bgc)$R" }
    else       { $out + "$(Get-Fg $bgc)$R$Reset" }
}
function Get-Cap([string]$c) { "$(Get-Fg $c)$L$Reset" }

if ($Effort) {
    $Left = (Get-Cap $Base2) + (Get-Pill $Base2 $Base02 $Model $Base1) + (Get-Pill $Base1 $Ink $Effort)
} else {
    $Left = (Get-Cap $Base2) + (Get-Pill $Base2 $Base02 $Model)
}

$Accent = $Blue; $MeterBg = $Base1; $MeterFg = $Ink
if ($Pct -ge 90) { $Accent = $Magenta; $MeterBg = $Magenta; $MeterFg = $Base2 }

# Guarded: a missing git is a terminating CommandNotFound in PowerShell, which
# 2>$null does not silence.
$Branch = ""
if ($Dir -and (Get-Command git -ErrorAction SilentlyContinue)) {
    $Branch = git --no-optional-locks -C $Dir branch --show-current 2>$null
}
# Both separators: Windows paths use `\`, and Claude Code may report `/`.
$Leaf = ($Dir -split '[\\/]' | Where-Object { $_ }) | Select-Object -Last 1
if (-not $Leaf) { $Leaf = $Dir }
if ($Branch) {
    $Win = (Get-Cap $Accent) + (Get-Pill $Accent $Base2 $Branch $Base2) + (Get-Pill $Base2 $Base02 $Leaf)
} else {
    $Win = (Get-Cap $Base2) + (Get-Pill $Base2 $Base02 $Leaf)
}

$Meter = "ctx $Pct%"
if ($null -ne $FiveH -and "$FiveH" -ne "") {
    $Meter = "$Meter $Dot 5h $([int][math]::Floor([double]$FiveH))%"
    if ($null -ne $ResetsAt -and "$ResetsAt" -ne "") {
        $Mins = [int][math]::Floor(([long]$ResetsAt - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) / 60)
        $Remain = if ($Mins -ge 60) { "$([math]::Floor($Mins / 60))h$($Mins % 60)m" } else { "${Mins}m" }
        if ($Mins -gt 0) { $Meter = "$Meter $Cycle$Remain" }
    }
}
$Right = (Get-Cap $MeterBg) + (Get-Pill $MeterBg $MeterFg $Meter)

# COLUMNS is exported by Claude Code. [Console]::WindowWidth is no fallback:
# stdout is a pipe, and with no console attached it throws.
$EdgeReserve = 8
function Get-VisibleWidth([string]$s) { ($s -replace "$ESC\[[0-9;]*m", "").Length }

$Main = "$Left $Win"
$Out = "$Main $Right"
$Columns = 0
if ($env:COLUMNS) { $Columns = [int]$env:COLUMNS }
if ($Columns -gt 0) {
    $Gap = $Columns - $EdgeReserve - (Get-VisibleWidth $Main) - (Get-VisibleWidth $Right)
    if ($Gap -ge 3) { $Out = $Main + (" " * $Gap) + $Right }
}

Write-Output $Out
