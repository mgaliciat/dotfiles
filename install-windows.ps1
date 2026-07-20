# Claude Code pieces for NATIVE Windows (no WSL2 — WSL2 uses
# install-linux.sh, which already detects it and gives specific hints).
#
# Intentionally narrow scope: zsh/tmux/nvim do not run natively on Windows, so
# this script is NOT a port of the rest of the dotfiles — see CLAUDE.md, the
# "per-machine split" section. It covers only:
#   - symlinks for claude/statusline.ps1, claude/CLAUDE.md, and the per-item
#     skills we author (bitacora, wiki)
#   - statusLine + base permissions in settings.json (equivalent to the jq
#     blocks in install.sh/install-linux.sh, here with native JSON)
#   - rtk (no official installer for Windows — we download the release zip)
#   - codebase-memory-mcp (official install.ps1 installer)
#   - marketplace plugins (ponytail, andrej-karpathy-skills)
#   - HTTP-endpoint MCPs (context7, obsidian) — mechanism 2, key from env vars
#   - Nerd Fonts (the ONE stack layer that DOES exist on Windows: Windows
#     Terminal, unlike zsh/tmux/nvim — so the fonts install.sh puts on the Mac
#     are useful here too). Maple + Monaspace via scoop; PlemolJP by direct
#     download (not in any scoop bucket). Best-effort, both guarded/try-catch.
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

# True if $a and $b have identical content (recursively for dirs) -- used to make
# the no-Developer-Mode copy path IDEMPOTENT: without it, every re-run backs up and
# re-copies our own prior copy, and for the skill DIRS those `.backup` copies land
# inside ~/.claude/skills/ and get loaded as phantom skills. Same content -> no-op.
function Test-SameContent {
    param([string]$A, [string]$B)
    $la = Test-Path $A -PathType Leaf; $lb = Test-Path $B -PathType Leaf
    if ($la -and $lb) { return (Get-FileHash $A).Hash -eq (Get-FileHash $B).Hash }
    if ((Test-Path $A -PathType Container) -and (Test-Path $B -PathType Container)) {
        $h = { param($root) Get-ChildItem $root -Recurse -File | ForEach-Object {
            "$($_.FullName.Substring($root.Length))|$((Get-FileHash $_.FullName).Hash)" } | Sort-Object }
        return ((& $h $A) -join "`n") -eq ((& $h $B) -join "`n")
    }
    return $false
}

function Set-DotfileSymlink {
    param([string]$Source, [string]$Destination)

    if (Test-Path $Destination) {
        $existing = Get-Item $Destination -Force
        if ($existing.LinkType -eq "SymbolicLink") {
            # .Delete() drops a DIRECTORY symlink's reparse point WITHOUT recursing
            # into the target -- `Remove-Item` on a dir symlink can delete the target's
            # contents (here: the versioned skill files in the repo). Safe for files too.
            $existing.Delete()
        } elseif (Test-SameContent $Destination $Source) {
            # Our own prior copy, unchanged (no Developer Mode -> we copy, not link).
            Write-Host "OK  $Destination already up to date (copy -- enable Developer Mode for a real symlink)"
            return
        } else {
            # Back up into ~/.claude/backups/, NOT next to $Destination: a `.backup`
            # sitting beside a symlinked skill dir would itself be loaded as a skill.
            $backupRoot = Join-Path $ClaudeDir "backups"
            New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
            $backup = Join-Path $backupRoot "$(Split-Path $Destination -Leaf).backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
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
        # -Recurse so a directory target (the bitacora/wiki skills) copies its contents,
        # not just an empty dir. Harmless/ignored for a single-file target.
        Copy-Item $Source $Destination -Recurse -Force
    }
}

# Run a native command (claude/rtk) reporting success via its exit code, WITHOUT
# letting stderr kill the script. Under this script's $ErrorActionPreference='Stop',
# PowerShell 5.1 turns ANY stderr write by a native exe into a TERMINATING
# NativeCommandError -- even through 2>&1 -- and `claude mcp get` (server absent) /
# `claude plugin add` ("already installed") write to stderr on perfectly benign
# paths. Flip EAP to Continue for just the call, swallow all output, return $LASTEXITCODE.
function Invoke-Native {
    param([scriptblock]$Cmd)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try { & $Cmd 2>&1 | Out-Null; return $LASTEXITCODE }
    finally { $ErrorActionPreference = $prev }
}

# ─── symlinks ──────────────────────────────────────────────────
# statusline.PS1, not the .sh: on native Windows there is no bash to run the
# shell script (the only `bash` on PATH is WSL's) and no jq for it to call, so
# the .sh is dead weight here. The .ps1 is a faithful port; mac/Linux still
# symlink the .sh from their own installers.
Set-DotfileSymlink (Join-Path $Dotfiles "claude\statusline.ps1") (Join-Path $ClaudeDir "statusline.ps1")
Set-DotfileSymlink (Join-Path $Dotfiles "claude\CLAUDE.md")      (Join-Path $ClaudeDir "CLAUDE.md")

# Per-ITEM skills we author (bitacora, wiki) -- mirror of settings.sh's per-item
# symlinks. NOT the whole skills/ dir: that stays per-machine (`learned`,
# `codebase-memory`) and versioning it risks leaking personal state. These two we
# control and version, so they symlink in beside the others. `wiki` is a skills-dir
# plugin (.claude-plugin/plugin.json), but installs by THIS symlink alone --
# referenced in place, so `git pull` propagates edits with no copy, no marketplace.
# skills/ may not exist yet (codebase-memory-mcp creates it later), so make it first.
# Runtime note: both lean on the obsidian MCP, wired below.
$SkillsDir = Join-Path $ClaudeDir "skills"
New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
Set-DotfileSymlink (Join-Path $Dotfiles "claude\skills\bitacora") (Join-Path $SkillsDir "bitacora")
Set-DotfileSymlink (Join-Path $Dotfiles "claude\skills\wiki")     (Join-Path $SkillsDir "wiki")

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

    if ((Invoke-Native { $null | claude plugin marketplace add $Url }) -eq 0) {
        Write-Host "OK  ${Label}: marketplace added (or already there)"
    } else {
        Write-Host "!!  could not add the $Label marketplace -- check by hand" -ForegroundColor Yellow
    }

    # Scope `-s user`: active in ALL projects, not just this repo.
    if ((Invoke-Native { $null | claude plugin install $Plugin -s user }) -eq 0) {
        Write-Host "OK  ${Label}: plugin installed (or already there)"
    } else {
        Write-Host "!!  could not install $Label -- check by hand (claude plugin install $Plugin)" -ForegroundColor Yellow
    }
}

# ─── context7 MCP (mechanism 2 — twin of binaries.sh) ───────────
# Hosted HTTP server (current library docs) — register the endpoint, no binary.
# Key from the ENVIRONMENT (a Windows user env var: `setx CONTEXT7_API_KEY <key>`),
# never the repo. Header is `CONTEXT7_API_KEY: <key>` (not Authorization/Bearer —
# that shape is obsidian's). No key -> skip cleanly. Idempotent via `claude mcp
# get`; a ROTATED key needs `claude mcp remove context7 -s user` first.
if ((Get-Command claude -ErrorAction SilentlyContinue) -and $env:CONTEXT7_API_KEY) {
    if ((Invoke-Native { claude mcp get context7 }) -eq 0) {
        Write-Host "OK  context7: already registered"
    } elseif ((Invoke-Native { $null | claude mcp add --transport http context7 https://mcp.context7.com/mcp -s user --header "CONTEXT7_API_KEY: $env:CONTEXT7_API_KEY" }) -eq 0) {
        Write-Host "OK  context7: MCP server registered (user scope)"
    } else {
        Write-Host "!!  context7 registration failed -- check by hand (claude mcp add ...)" -ForegroundColor Yellow
    }
} elseif (-not $env:CONTEXT7_API_KEY) {
    Write-Host "i   context7: skipped (no CONTEXT7_API_KEY env var -- setx CONTEXT7_API_KEY <key>)"
}

# ─── obsidian MCP (mechanism 2 — twin of binaries.sh) ───────────
# Same as binaries.sh: `claude mcp add` an HTTP endpoint, no binary, nothing to
# install. The Obsidian "Local REST API" plugin ships its own MCP at /mcp/ on
# 127.0.0.1:27123 — so this only makes sense on a box where you actually OPEN
# Obsidian with that plugin + its HTTP server enabled. Registration succeeds even
# with Obsidian closed (it just stores the URL); the tools only WORK when it is up.
#
# The key is per-machine, from the ENVIRONMENT — a Windows user env var here
# (`setx OBSIDIAN_API_KEY <hex>`), since native Windows has no ~/.zshenv.local.
# We strip a leading "Bearer " the plugin's copy button adds, else the header
# doubles to "Bearer Bearer <hex>" and 401s. No key -> skip cleanly. Idempotent:
# `claude mcp get` short-circuits (a ROTATED key needs `claude mcp remove obsidian
# -s user` first). It writes ~/.claude.json, not settings.json, so order vs the
# WriteAllText above does not matter — only `claude` in PATH does.
if ((Get-Command claude -ErrorAction SilentlyContinue) -and $env:OBSIDIAN_API_KEY) {
    $ObsKey = $env:OBSIDIAN_API_KEY -replace '^Bearer '
    if ((Invoke-Native { claude mcp get obsidian }) -eq 0) {
        Write-Host "OK  obsidian: already registered"
    } elseif ((Invoke-Native { $null | claude mcp add --transport http obsidian http://127.0.0.1:27123/mcp/ -s user --header "Authorization: Bearer $ObsKey" }) -eq 0) {
        Write-Host "OK  obsidian: MCP server registered (user scope)"
    } else {
        Write-Host "!!  obsidian registration failed -- check by hand (claude mcp add ...)" -ForegroundColor Yellow
    }
} elseif (-not $env:OBSIDIAN_API_KEY) {
    Write-Host "i   obsidian: skipped (no OBSIDIAN_API_KEY env var -- setx OBSIDIAN_API_KEY <hex>)"
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

# ─── Nerd Fonts via scoop ───────────────────────────────────────
# The subset of install.sh's REQUIRED_CASKS that (a) is an actual Nerd Font and
# (b) exists in scoop's `nerd-fonts` bucket: Maple Mono NF (the primary, the one
# ghostty sets as font-family) and Monaspace NF. Manifest names verified against
# the bucket, not guessed — a typo would 404, not silently fall back. PlemolJP NF
# is NOT in the bucket (it self-patches, it is not one of ryanoasis's fonts), so
# it is installed separately below by direct download. iA Writer Mono is dropped
# entirely — it is not a Nerd Font.
#
# Guarded on scoop, NOT auto-installed: scoop's own installer refuses to run
# under an elevated shell, and this script may be running as Administrator (for
# the symlinks). Installing it here would break exactly when symlinks needed
# admin. If scoop is missing we print the one-liner and skip — best-effort, same
# tone as the rest of the script. scoop itself is idempotent (re-runs say
# "already installed"), so no guard around the install call.
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Host ""
    Write-Host "-> Installing Nerd Fonts via scoop"
    scoop bucket add nerd-fonts 2>&1 | Out-Null   # idempotent: "already added" if present
    scoop install nerd-fonts/Maple-Mono-NF nerd-fonts/Monaspace-NF
    Write-Host "OK  Nerd Fonts installed (or already there)"
    Write-Host "    Set one in Windows Terminal: Settings > profile > Appearance > Font face"
    Write-Host "    Family names: 'Maple Mono NF', 'Monaspace ... NF' (check the exact"
    Write-Host "    name in the font viewer -- Nerd Fonts sometimes rename, e.g. MonaspiceNe)"
} else {
    Write-Host "i   scoop not found -- skipping Nerd Fonts. To get them, install scoop"
    Write-Host "    (https://scoop.sh) in a NON-admin shell, then re-run this script:"
    Write-Host "      Set-ExecutionPolicy -Scope CurrentUser RemoteSigned; irm get.scoop.sh | iex"
}

# ─── PlemolJP NF (font, not in scoop) ───────────────────────────
# PlemolJP self-patches its Nerd Font build, so it is absent from scoop's
# nerd-fonts bucket. We install it the rtk way: download the official release
# zip and register the .ttf per-user under %LOCALAPPDATA% (no admin needed,
# unlike copying into the system Fonts dir). Independent of scoop — runs either
# way. Best-effort: on any failure we print the manual link and continue.
#
# The asset name embeds the version (PlemolJP_NF_vX.Y.Z.zip), so — unlike rtk's
# fixed asset name — we cannot use latest/download/<fixed-name>; we ask the API
# for the latest asset matching the pattern. The registry VALUE name is just a
# label; the family name Windows Terminal shows comes from the font's own name
# table, so the file basename as label is fine.
$PlemolZip = $null; $PlemolDst = $null
try {
    Write-Host ""
    Write-Host "-> Installing PlemolJP NF font (direct download)"
    $rel = Invoke-RestMethod "https://api.github.com/repos/yuru7/PlemolJP/releases/latest" -Headers @{ "User-Agent" = "dotfiles" }
    $asset = $rel.assets | Where-Object { $_.name -match '^PlemolJP_NF_.*\.zip$' } | Select-Object -First 1
    if (-not $asset) { throw "no PlemolJP_NF asset in the latest release" }
    $PlemolZip = Join-Path $env:TEMP $asset.name
    $PlemolDst = Join-Path $env:TEMP "PlemolJP_NF"
    Invoke-WebRequest $asset.browser_download_url -OutFile $PlemolZip
    Expand-Archive $PlemolZip -DestinationPath $PlemolDst -Force

    $FontsDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    New-Item -ItemType Directory -Path $FontsDir -Force | Out-Null
    $RegKey = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
    Get-ChildItem $PlemolDst -Recurse -Include *.ttf, *.otf | ForEach-Object {
        $target = Join-Path $FontsDir $_.Name
        Copy-Item $_.FullName $target -Force
        $title = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        New-ItemProperty -Path $RegKey -Name "$title (TrueType)" -Value $target -PropertyType String -Force | Out-Null
    }
    Write-Host "OK  PlemolJP NF installed per-user ($FontsDir)"
} catch {
    Write-Host "!!  PlemolJP NF install failed: $_" -ForegroundColor Yellow
    Write-Host "    Get it by hand: https://github.com/yuru7/PlemolJP/releases" -ForegroundColor Yellow
} finally {
    if ($PlemolZip) { Remove-Item $PlemolZip -Force -ErrorAction SilentlyContinue }
    if ($PlemolDst) { Remove-Item $PlemolDst -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "Done. Next steps:"
Write-Host "  1. Restart the terminal so the new PATH takes effect."
Write-Host "  2. Restart Claude Code."
Write-Host "  3. If the symlinks failed: enable Developer Mode and re-run this script."
Write-Host "  4. Fonts: set 'Maple Mono NF' in Windows Terminal (Appearance > Font face)."
Write-Host "     PlemolJP appears as 'PlemolJP Console NF' / 'PlemolJP NF'."
