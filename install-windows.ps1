# Claude Code pieces for NATIVE Windows (no WSL2 — WSL2 uses
# install-linux.sh, which already detects it and gives specific hints).
#
# Intentionally narrow scope: zsh/tmux/nvim do not run natively on Windows, so
# this script is NOT a port of the rest of the dotfiles — see CLAUDE.md, the
# "per-machine split" section. It covers only:
#   - symlinks for claude/statusline.ps1 and claude/CLAUDE.md
#   - statusLine + base permissions in settings.json (equivalent to the jq
#     blocks in install.sh/install-linux.sh, here with native JSON)
#   - rtk (no official installer for Windows — we download the release zip)
#   - codebase-memory-mcp (official install.ps1 installer)
#   - marketplace plugins (ponytail, andrej-karpathy-skills)
#
# Those four bullets are the three mechanisms of claude/install/ (settings.sh /
# binaries.sh / plugins.sh) replicated by hand: PowerShell cannot source the bash
# scripts. If you touch something over there, check whether it applies here.
#
# Usage: open PowerShell (5.1 or pwsh 7+) in this folder and run
#   ./install-windows.ps1
# If it errors with an execution policy problem:
#   PowerShell -ExecutionPolicy Bypass -File .\install-windows.ps1
#
# Symlinks on Windows require Developer Mode enabled (Settings >
# Privacy & security > For developers) or running as Administrator. If that is
# not available, the script falls back to copying the file (it warns on screen)
# — future `git pull`s will not propagate until you enable Developer Mode and
# re-run the script.

$ErrorActionPreference = "Stop"

$Dotfiles  = $PSScriptRoot
$ClaudeDir = Join-Path $HOME ".claude"
New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null

function Set-DotfileSymlink {
    param([string]$Source, [string]$Destination)

    if (Test-Path $Destination) {
        $existing = Get-Item $Destination -Force
        if ($existing.LinkType -eq "SymbolicLink") {
            Remove-Item $Destination -Force
        } else {
            $backup = "$Destination.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Write-Host "-> backing up existing $Destination to $backup"
            Move-Item $Destination $backup
        }
    }

    try {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $Source -Force -ErrorAction Stop | Out-Null
        Write-Host "OK  $Destination -> $Source"
    } catch {
        Write-Host "!!  could not symlink $Destination (enable Developer Mode or run as Administrator)" -ForegroundColor Yellow
        Write-Host "    copying instead -- future 'git pull's will not propagate until you re-run this script" -ForegroundColor Yellow
        Copy-Item $Source $Destination -Force
    }
}

# ─── symlinks ──────────────────────────────────────────────────
# statusline.PS1, not the .sh: on native Windows there is no bash to run the
# shell script (the only `bash` on PATH is WSL's) and no jq for it to call, so
# the .sh is dead weight here. The .ps1 is a faithful port; mac/Linux still
# symlink the .sh from their own installers.
Set-DotfileSymlink (Join-Path $Dotfiles "claude\statusline.ps1") (Join-Path $ClaudeDir "statusline.ps1")
Set-DotfileSymlink (Join-Path $Dotfiles "claude\CLAUDE.md")      (Join-Path $ClaudeDir "CLAUDE.md")

# ─── settings.json: statusLine + base permissions ──────────────
# Additive-only, same as install.sh/install-linux.sh: if the key already exists
# (you built your own config by hand on this machine) it is not touched.
$SettingsPath = Join-Path $ClaudeDir "settings.json"
$Settings = if (Test-Path $SettingsPath) {
    Get-Content $SettingsPath -Raw | ConvertFrom-Json
} else {
    [PSCustomObject]@{}
}

if ($Settings.PSObject.Properties.Name -contains "statusLine") {
    Write-Host "OK  statusLine already set in settings.json -- leaving it alone"
} else {
    # Invoke the .ps1 through powershell.exe (guaranteed present) with an ABSOLUTE
    # path: unlike the mac/Linux `~/.claude/statusline.sh`, we cannot rely on `~`
    # expanding here (powershell -File does not tilde-expand, and the caller may be
    # cmd). settings.json is per-machine anyway, so baking $HOME\.claude is fine.
    # -NoProfile keeps it fast on every render; -ExecutionPolicy Bypass runs the
    # unsigned script regardless of the machine's policy.
    $StatuslinePs1 = Join-Path $ClaudeDir "statusline.ps1"
    $Settings | Add-Member -NotePropertyName "statusLine" -NotePropertyValue ([PSCustomObject]@{
        type    = "command"
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$StatuslinePs1`""
    })
    Write-Host "OK  statusLine added to settings.json (powershell -> statusline.ps1)"
}

if (-not ($Settings.PSObject.Properties.Name -contains "permissions")) {
    $Settings | Add-Member -NotePropertyName "permissions" -NotePropertyValue ([PSCustomObject]@{})
}

# The lists come from claude/install/permissions.json -- the same file the bash
# side reads with jq. Single source of truth: adding a permission in one place
# used to leave the other platform silently behind.
$Permissions = Get-Content (Join-Path $Dotfiles "claude\install\permissions.json") -Raw | ConvertFrom-Json

if ($Settings.permissions.PSObject.Properties.Name -contains "allow") {
    Write-Host "OK  permissions.allow already set in settings.json -- leaving it alone"
} else {
    $Settings.permissions | Add-Member -NotePropertyName "allow" -NotePropertyValue $Permissions.allow
    Write-Host "OK  permissions.allow added to settings.json"
}

if ($Settings.permissions.PSObject.Properties.Name -contains "deny") {
    Write-Host "OK  permissions.deny already set in settings.json -- leaving it alone"
} else {
    $Settings.permissions | Add-Member -NotePropertyName "deny" -NotePropertyValue $Permissions.deny
    Write-Host "OK  permissions.deny added to settings.json"
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($SettingsPath, ($Settings | ConvertTo-Json -Depth 10), $Utf8NoBom)

# ─── rtk (token-reducing proxy CLI) ─────────────────────────────
# No official installer for Windows (the docs only give the release zip +
# manual extraction) -- we download from GitHub's stable
# "latest/download/<asset>" URL (no API call needed) and drop it in
# %LOCALAPPDATA%\Programs\rtk, the same directory pattern the official
# codebase-memory-mcp installer uses below.
$RtkDir = Join-Path $env:LOCALAPPDATA "Programs\rtk"
$RtkExe = Join-Path $RtkDir "rtk.exe"

$RtkCmd = Get-Command rtk -ErrorAction SilentlyContinue
if (-not $RtkCmd -and -not (Test-Path $RtkExe)) {
    Write-Host ""
    Write-Host "-> Installing rtk"
    $TmpZip = Join-Path $env:TEMP "rtk.zip"
    try {
        Invoke-WebRequest -Uri "https://github.com/rtk-ai/rtk/releases/latest/download/rtk-x86_64-pc-windows-msvc.zip" -OutFile $TmpZip
        New-Item -ItemType Directory -Path $RtkDir -Force | Out-Null
        Expand-Archive -Path $TmpZip -DestinationPath $RtkDir -Force
    } catch {
        Write-Host "!!  rtk install failed: $_" -ForegroundColor Yellow
    } finally {
        Remove-Item $TmpZip -Force -ErrorAction SilentlyContinue
    }
}

if ($RtkCmd) { $RtkExe = $RtkCmd.Source }

if (Test-Path $RtkExe) {
    $UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($UserPath -notlike "*$RtkDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$UserPath;$RtkDir", "User")
        $env:PATH = "$env:PATH;$RtkDir"
        Write-Host "OK  $RtkDir added to the user PATH"
    }
    try {
        & $RtkExe init --global --auto-patch | Out-Null
        Write-Host "OK  rtk Claude Code hook configured (or already there)"
    } catch {
        Write-Host "!!  rtk init --global failed -- check by hand ($RtkExe init --global -v)" -ForegroundColor Yellow
    }
} else {
    Write-Host "!!  rtk could not be installed -- check by hand (https://github.com/rtk-ai/rtk)" -ForegroundColor Yellow
}

# ─── codebase-memory-mcp (code graph MCP server) ────────────────
# Official installer (install.ps1): downloads the binary, runs `install -y` on
# its own (configures Claude Code + adds its own dir to the user PATH), in the
# variant without --ui (headless, the default). It only runs if the binary is
# not already present.
if (-not (Get-Command codebase-memory-mcp -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "-> Installing codebase-memory-mcp"
    $TmpPs1 = Join-Path $env:TEMP "cbm-install.ps1"
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.ps1" -OutFile $TmpPs1
        Unblock-File $TmpPs1
        & $TmpPs1
    } catch {
        Write-Host "!!  codebase-memory-mcp install failed: $_" -ForegroundColor Yellow
    } finally {
        Remove-Item $TmpPs1 -Force -ErrorAction SilentlyContinue
    }
}

# `install -y` runs ALWAYS (mirror of install.sh): it is what registers the MCP
# server + hooks + the `codebase-memory` skill in ~/.claude/. If it lived only
# inside the official install.ps1 above, a ~/.claude deleted by hand would never
# be rebuilt (binary present -> guard false -> zero reinstall).
# Idempotent.
$Cbm = Get-Command codebase-memory-mcp -ErrorAction SilentlyContinue
if ($Cbm) {
    & $Cbm.Source install -y | Out-Null
    Write-Host "OK  codebase-memory-mcp: MCP server + hooks + skill registered"
    & $Cbm.Source config set auto_index true | Out-Null
    Write-Host "OK  codebase-memory-mcp: auto_index=true"
}

# ─── marketplace plugins (mechanism 3) ──────────────────────────
# Port of claude/install/plugins.sh — PowerShell cannot source bash, so it is
# replicated. `claude plugin` is the same cross-platform CLI and it writes
# extraKnownMarketplaces + enabledPlugins into settings.json on its own; we do
# not touch the file here (that is why this block goes AFTER the WriteAllText
# above: if we wrote $Settings afterwards, we would clobber what the CLI put
# there).
#
# Full https:// URL, NOT the owner/repo shorthand: the shorthand clones over SSH
# and fails on a fresh machine with no key registered on GitHub. Idempotent: the
# second run detects "already installed" and does not duplicate.
#
# `$null |` closes stdin: on mac one of these commands hung waiting for an
# invisible interactive prompt (equivalent to the `</dev/null` in plugins.sh).
function Install-ClaudePlugin {
    param([string]$Url, [string]$Plugin, [string]$Label)

    $null | & claude plugin marketplace add $Url 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK  ${Label}: marketplace added (or already there)"
    } else {
        Write-Host "!!  could not add the $Label marketplace -- check by hand" -ForegroundColor Yellow
    }

    # Scope `-s user`: active in ALL projects, not just this repo.
    $null | & claude plugin install $Plugin -s user 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK  ${Label}: plugin installed (or already there)"
    } else {
        Write-Host "!!  could not install $Label -- check by hand (claude plugin install $Plugin)" -ForegroundColor Yellow
    }
}

if (Get-Command claude -ErrorAction SilentlyContinue) {
    # ponytail: 1 install brings the plugin AND its 6 bundled skills. Its hooks are
    # Node.js -- without node it still installs, but automatic activation goes mute.
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host "i   node not detected -- ponytail installs anyway, but its automatic activation hooks will stay mute until node is in PATH"
    }
    Install-ClaudePlugin "https://github.com/DietrichGebert/ponytail" "ponytail@ponytail" "ponytail"

    # andrej-karpathy-skills: 1 skill, no hooks, no node. Names taken from the
    # repo's .claude-plugin/marketplace.json, not from the README (which still has
    # the old name, from before it was transferred to multica-ai).
    Install-ClaudePlugin "https://github.com/multica-ai/andrej-karpathy-skills" "andrej-karpathy-skills@karpathy-skills" "andrej-karpathy-skills"
} else {
    Write-Host "i   claude not detected in PATH -- skipping plugins"
}

Write-Host ""
Write-Host "Done. Next steps:"
Write-Host "  1. Restart the terminal so the new PATH takes effect."
Write-Host "  2. Restart Claude Code."
Write-Host "  3. If the symlinks failed: enable Developer Mode and re-run this script."
