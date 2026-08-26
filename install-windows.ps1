# Claude Code pieces for NATIVE Windows (no WSL2 — WSL2 uses
# install-linux.sh, which already detects it and gives specific hints).
#
# Intentionally narrow scope: zsh/tmux/nvim do not run natively on Windows, so
# this script is NOT a port of the rest of the dotfiles — see CLAUDE.md, the
# "per-machine split" section. It covers only:
#   - symlinks for claude/statusline.ps1, claude/CLAUDE.md, the per-item skills
#     we author (bitacora, wiki), and git/.gitignore_global
#   - statusLine (+ refreshInterval) and base permissions in settings.json
#     (equivalent to the jq blocks in install.sh/install-linux.sh, native JSON here)
#   - rtk (no official installer for Windows — we download the release zip) and
#     its versioned config.toml, COPIED like on mac/Linux
#   - codebase-memory-mcp (official install.ps1 installer)
#   - HTTP-endpoint MCPs (context7, obsidian) — mechanism 2, key from env vars
#   - gh-stack: the `gh` extension + its skill (npx skills) — mirror of
#     bootstrap_gh_stack in scripts/lib.sh and the block in binaries.sh
#   - Nerd Fonts (the ONE stack layer that DOES exist on Windows: Windows
#     Terminal, unlike zsh/tmux/nvim — so the fonts install.sh puts on the Mac
#     are useful here too). Maple + Monaspace via scoop; PlemolJP by direct
#     download (not in any scoop bucket). Best-effort, both guarded/try-catch.
#   - the stack theme on that same layer: a Windows Terminal colour scheme
#     GENERATED from ghostty/themes/<id> (its `schemes` are the same 16 ANSI +
#     bg/fg/cursor/selection), with its own versioned selection line, $WtTheme.
#   - Windows Terminal keybindings for Claude (ctrl+shift+l / ctrl+shift+y), the
#     moral equivalent of tmux's M-c / M-C on the one layer this box shares.
#     ctrl+shift+ is the ONLY safe family in a terminal — see $WtBinds.
#
# Those bullets are the three mechanisms of claude/install/ (settings.sh /
# binaries.sh / plugins.sh) replicated by hand: PowerShell cannot source the bash
# scripts. If you touch something over there, check whether it applies here.
#
# What is still deliberately ABSENT vs install.sh, and why: zsh/tmux/nvim/ghostty
# and their symlinks (do not run natively), the shell tools behind their aliases
# (eza/bat/fd/gomi/zoxide/fzf — no zsh to alias them from), 1password-cli
# (nothing in this repo references `op`), and Paper Mono (the ghostty font-family;
# no ghostty here, and the NF families below are what Windows Terminal needs).
# Note the theme block reads ghostty/themes/ anyway — that dir is just where the
# palettes are versioned, and needing them here is not the same as running ghostty.
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
            # DELETE rather than return: enabling Developer Mode later has to be able to
            # UPGRADE that copy into a real symlink, and an early return froze it as a
            # copy forever (the re-run kept reporting "already up to date"). No backup --
            # the content is identical to the repo by definition, and if the symlink
            # below still fails, the catch copies it straight back.
            Remove-Item $Destination -Recurse -Force
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

    # `mklink`, NOT `New-Item -ItemType SymbolicLink`: Windows PowerShell 5.1 (the
    # only PowerShell guaranteed present) predates the unprivileged-symlink flag, so
    # New-Item demands Administrator even with Developer Mode ON -- which is the whole
    # point of turning it on. cmd's mklink does pass SYMBOLIC_LINK_FLAG_ALLOW_
    # UNPRIVILEGED_CREATE, so it is the only way a normal user gets a real link here.
    # /D for a directory target (the bitacora/wiki skills).
    $mkArgs = @()
    if (Test-Path $Source -PathType Container) { $mkArgs += "/D" }
    $mkArgs += @($Destination, $Source)

    # mklink reports failure on stderr, which this script's $ErrorActionPreference
    # ='Stop' would turn into a terminating NativeCommandError (see Invoke-Native).
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    cmd /c mklink @mkArgs 2>&1 | Out-Null
    $ErrorActionPreference = $prevEap

    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK  $Destination -> $Source"
    } else {
        Write-Host "!!  could not symlink $Destination (enable Developer Mode: Settings > System > For developers)" -ForegroundColor Yellow
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

# The one NON-Claude symlink from install.sh that is portable here: git runs
# natively on Windows, unlike zsh/tmux/nvim/ghostty. Inert on its own -- it only
# takes effect once ~/.gitconfig points at it (`[core] excludesfile`), which is
# per-machine and NOT versioned, exactly as on mac. Linking it anyway means that
# when you do write that gitconfig, the file is already there and tracks the repo.
Set-DotfileSymlink (Join-Path $Dotfiles "git\.gitignore_global") (Join-Path $HOME ".gitignore_global")

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

# Keyed on the NESTED field, not on `.statusLine` -- mirror of settings.sh. The
# guard above is satisfied by ANY pre-existing statusLine, so a machine that
# already had one would otherwise never get the interval. Runs second so it lands
# on the object the block above may have just created.
#
# Without it the status line re-renders on EVENTS only, and the `↻` countdown to
# the 5h rate-limit reset freezes while the session is idle -- which is exactly
# when you are looking at it. 60s because the countdown is rendered in minutes.
#
# The type check is not paranoia about our own write: it guards a hand-edited
# settings.json where statusLine is a bare string. Add-Member on a string throws,
# and with $ErrorActionPreference='Stop' that kills the whole installer.
if ($Settings.statusLine -isnot [PSCustomObject]) {
    Write-Host "i   statusLine is not an object in settings.json -- skipping refreshInterval"
} elseif ($Settings.statusLine.PSObject.Properties.Name -contains "refreshInterval") {
    Write-Host "OK  statusLine.refreshInterval already set in settings.json -- leaving it alone"
} else {
    $Settings.statusLine | Add-Member -NotePropertyName "refreshInterval" -NotePropertyValue 60
    Write-Host "OK  statusLine.refreshInterval added to settings.json (60s)"
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

# ─── attribution: no Co-Authored-By trailer (mirror of settings.sh) ───
# `attribution.commit` / `.pr` override the text Claude Code appends to commit
# messages and PR bodies; an EMPTY STRING is the documented sentinel for "hide it
# entirely", not a no-op and not the same as omitting the key (which means "use
# the default trailer"). Supersedes `includeCoAuthoredBy`, now deprecated in the
# CLI -- don't add that one back beside it. The prose half of this rule lives in
# claude/CLAUDE.md, symlinked above; both are needed (setting stops the harness
# injecting the trailer, prose stops it being written by hand).
#
# Per-FIELD guard for the same reason as refreshInterval: a settings.json that
# already has the object for one field would otherwise never get the other. The
# type check guards a hand-edited file where `attribution` is not an object --
# Add-Member would throw and, under $ErrorActionPreference='Stop', kill the run.
if (-not ($Settings.PSObject.Properties.Name -contains "attribution")) {
    $Settings | Add-Member -NotePropertyName "attribution" -NotePropertyValue ([PSCustomObject]@{})
}
if ($Settings.attribution -isnot [PSCustomObject]) {
    Write-Host "i   attribution is not an object in settings.json -- leaving it alone"
} else {
    foreach ($AttrField in @("commit", "pr")) {
        if ($Settings.attribution.PSObject.Properties.Name -contains $AttrField) {
            Write-Host "OK  attribution.$AttrField already set in settings.json -- leaving it alone"
        } else {
            $Settings.attribution | Add-Member -NotePropertyName $AttrField -NotePropertyValue ""
            Write-Host "OK  attribution.$AttrField added to settings.json (empty = no trailer)"
        }
    }
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

    # ── rtk config.toml: COPIED, not symlinked (port of binaries.sh) ──
    # The only copy-instead-of-link in the repo, and the exception is earned: rtk
    # does a load -> mutate -> serialize round-trip on its config (`rtk telemetry
    # disable` alone drops every comment and appends a consent_date timestamp), so
    # through a symlink that per-machine state lands in this PUBLIC repo -- the
    # same failure that keeps settings.json unversioned. Repo file = source of
    # truth, installed copy = disposable. WHY the values (raised caps, tee=always,
    # diff/curl excluded) is commented in claude/install/rtk-config.toml itself.
    #
    # The path is NOT hardcoded. binaries.sh can afford an OS branch because it
    # only has two arms (Application Support / XDG), but rtk's README documents no
    # Windows location -- so we ask rtk itself: `rtk config` prints "Config: <path>"
    # as its first line. Self-correcting if the convention ever changes, and a
    # clean skip if the output shape does.
    #
    # Unconditional copy (convergent): a `git pull` + re-run realigns a machine
    # whose copy rtk has since rewritten. Only a DIVERGED copy is backed up first,
    # matching link()'s contract on the bash side -- the steady state (our file,
    # comment-stripped by rtk) must not spawn a backup on every run.
    $RtkCfgSrc = Join-Path $Dotfiles "claude\install\rtk-config.toml"
    $RtkCfg = $null
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try { $RtkCfgOut = @(& $RtkExe config 2>&1) } finally { $ErrorActionPreference = $prevEap }
    foreach ($ln in $RtkCfgOut) {
        if ("$ln" -match '^\s*Config:\s*(.+?)\s*$') { $RtkCfg = $Matches[1]; break }
    }
    if ($RtkCfg) {
        if ((Test-Path $RtkCfg) -and -not (Test-SameContent $RtkCfg $RtkCfgSrc)) {
            $RtkCfgBackup = "$RtkCfg.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item $RtkCfg $RtkCfgBackup -Force
            Write-Host "-> backing up diverged $RtkCfg to $RtkCfgBackup"
        }
        New-Item -ItemType Directory -Path (Split-Path $RtkCfg -Parent) -Force | Out-Null
        Copy-Item $RtkCfgSrc $RtkCfg -Force
        Write-Host "OK  rtk config.toml installed (copy -- rtk rewrites it, cannot be a symlink)"
    } else {
        Write-Host "!!  could not resolve rtk's config path from 'rtk config' -- config.toml not installed" -ForegroundColor Yellow
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

# No plugins installed right now: ponytail and andrej-karpathy-skills lived here
# until aug-2026 and were dropped. Install-ClaudePlugin stays for the next one --
# same reasoning as the bash side (claude/install/plugins.sh).

# ─── gh-stack: the `gh` extension ───────────────────────────────
# Port of bootstrap_gh_stack (scripts/lib.sh). gh-stack is stacked branches/PRs as
# a `gh` extension -- `gh extension install` is its only supported install, which
# is why it cannot ride along in a package list like everything else.
#
# `gh` is NOT auto-installed, same call as scoop below: pulling in winget here
# would run a package manager inside a script that may be elevated for the
# symlinks. Missing gh is a skip with a hint, never a failure.
#
# Guarded on the extension already being listed -- `gh extension install` errors
# out on a re-run. Deliberately NOT convergent (no `gh extension upgrade`):
# bumping the version is the user's call, unlike the tmux plugin on the bash side,
# which is SHA-pinned precisely so every machine runs the same bytes.
if (Get-Command gh -ErrorAction SilentlyContinue) {
    # Needs the OUTPUT, so Invoke-Native (which swallows it) is no use here --
    # same EAP dance by hand so a stderr write cannot kill the script.
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try { $GhExts = @(gh extension list 2>&1) } finally { $ErrorActionPreference = $prevEap }

    if ($GhExts -match 'github/gh-stack') {
        Write-Host "OK  gh-stack extension already installed"
    } elseif ((Invoke-Native { $null | gh extension install github/gh-stack }) -eq 0) {
        Write-Host "OK  gh-stack installed (gh stack --help)"
    } else {
        Write-Host "!!  gh extension install github/gh-stack failed" -ForegroundColor Yellow
    }
} else {
    Write-Host "i   gh-stack: skipped (no gh on PATH). Get the GitHub CLI with:"
    Write-Host "      winget install --id GitHub.cli"
}

# ─── gh-stack skill (mechanism 2 — twin of binaries.sh) ─────────
# The skill lives INSIDE github/gh-stack (skills/gh-stack/ + references/): it
# teaches the agent the stacked model and the `gh stack` commands. The external
# tool here is not a binary but `npx skills` (skills.sh), which resolves the skill
# from the repo and writes it into ~/.claude/skills/ -- same mechanism-2 contract,
# it owns the file layout. Skill without extension is useless, so keep both or
# drop both.
#
# Every flag is load-bearing:
#   -g              global (~/.claude/skills) -- a workflow tool for every repo,
#                   not a skill of the project the installer happens to run in
#                   (the CLI's default scope is the CURRENT project: the same
#                   `--scope user` trap as the MCP registrations above)
#   -a claude-code  only Claude Code; without it the CLI prompts per detected agent
#   -s gh-stack     the repo ships one skill, but naming it skips the picker
#   -y + npx -y     no prompts, and `$null |` on top to close stdin: an installer
#                   that blocks on invisible stdin is the rtk footgun all over again
#
# Idempotence is OURS (the CLI re-downloads and re-copies on every `add`), so the
# guard is the destination dir. That also means it never updates: for that,
# `npx skills update gh-stack -g`.
$GhStackSkill = Join-Path $SkillsDir "gh-stack"
if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    Write-Host "i   gh-stack skill: skipped (no npx on PATH -- install Node.js)"
} elseif (Test-Path $GhStackSkill) {
    Write-Host "OK  gh-stack skill already installed"
} else {
    Write-Host ""
    Write-Host "-> Installing the gh-stack skill (npx skills)"
    if ((Invoke-Native { $null | npx -y skills@latest add https://github.com/github/gh-stack -s gh-stack -a claude-code -g -y }) -eq 0) {
        Write-Host "OK  gh-stack skill installed ($GhStackSkill)"
    } else {
        Write-Host "!!  gh-stack skill failed -- by hand: npx skills add https://github.com/github/gh-stack -s gh-stack -a claude-code -g -y" -ForegroundColor Yellow
    }
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

# ─── fonts by direct download (not in scoop) ────────────────────
# Two fonts this repo wants are absent from scoop's nerd-fonts bucket, for
# opposite reasons: PlemolJP self-patches its own Nerd Font build (it is not one
# of ryanoasis's), and Google Sans Code is not a Nerd Font at all. Both install
# the rtk way: download the official release zip and register the .ttf per-user
# under %LOCALAPPDATA% (no admin needed, unlike the system Fonts dir).
# Independent of scoop — runs either way. Best-effort: on failure, print the
# manual link and continue.
#
# Both asset names embed the version, so — unlike rtk's fixed asset name — we
# cannot use latest/download/<fixed-name>; we ask the API for the latest asset
# matching a pattern. The registry VALUE name is just a label; the family name
# Windows Terminal shows comes from the font's own name table, so the file
# basename as label is fine.
#
# ⚠️ Re-running while the font is IN USE (the terminal you are typing in is
# rendering with it) fails on Copy-Item with "being used by another process".
# That is benign — the file on disk is already the one we would copy — and it is
# why this is best-effort rather than a hard failure.
function Install-FontFromRelease {
    param(
        [string]$Repo,          # owner/name on GitHub
        [string]$AssetPattern,  # regex matched against the release asset names
        [string]$Label          # human name for the log lines
    )
    $Zip = $null; $Dst = $null
    try {
        Write-Host ""
        Write-Host "-> Installing $Label font (direct download)"
        $rel = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ "User-Agent" = "dotfiles" }
        $asset = $rel.assets | Where-Object { $_.name -match $AssetPattern } | Select-Object -First 1
        if (-not $asset) { throw "no asset matching $AssetPattern in the latest release" }
        $Zip = Join-Path $env:TEMP $asset.name
        $Dst = Join-Path $env:TEMP ([System.IO.Path]::GetFileNameWithoutExtension($asset.name))
        Invoke-WebRequest $asset.browser_download_url -OutFile $Zip
        Expand-Archive $Zip -DestinationPath $Dst -Force

        $FontsDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
        New-Item -ItemType Directory -Path $FontsDir -Force | Out-Null
        $RegKey = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
        # foreach, NOT ForEach-Object: `$Installed +=` inside a pipeline block
        # assigns to a block-scoped copy and the list comes out empty.
        $Installed = @()
        foreach ($FontFile in (Get-ChildItem $Dst -Recurse -Include *.ttf, *.otf)) {
            $target = Join-Path $FontsDir $FontFile.Name
            # -LiteralPath is NOT optional here, and the failure is SILENT: a
            # variable font ships as `GoogleSansCode[MONO,wght].ttf`, and `[...]`
            # is a WILDCARD character class to PowerShell's -Path. The pattern
            # matches nothing, a wildcard matching zero items is not an error,
            # so Copy-Item copies nothing and returns clean -- while the
            # New-ItemProperty below still registers a path to a file that was
            # never written. Symptom: the font is in the registry, absent from
            # disk, and invisible to every app. PlemolJP never hit this because
            # its filenames have no brackets.
            Copy-Item -LiteralPath $FontFile.FullName -Destination $target -Force
            $title = [System.IO.Path]::GetFileNameWithoutExtension($FontFile.Name)
            New-ItemProperty -Path $RegKey -Name "$title (TrueType)" -Value $target -PropertyType String -Force | Out-Null
            $Installed += $target
        }
        # The HKCU entry above makes the font permanent, but ONLY from the next
        # logon: nothing running now knows the font table changed. AddFontResourceW
        # loads each face into the session and the WM_FONTCHANGE broadcast tells
        # every open app to re-read, which is what makes the font usable in the
        # terminal you are typing in RIGHT NOW instead of after a logout. Verified:
        # before the broadcast a fresh process enumerated zero of these families,
        # after it, all of them.
        if (-not ('W32.Fonts' -as [type])) {
            Add-Type -Name Fonts -Namespace W32 -MemberDefinition @'
[DllImport("gdi32.dll", CharSet=CharSet.Unicode)] public static extern int AddFontResourceW(string f);
[DllImport("user32.dll", CharSet=CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr h, uint m, IntPtr w, IntPtr l, uint fl, uint t, out IntPtr r);
'@
        }
        foreach ($f in $Installed) { [void][W32.Fonts]::AddFontResourceW($f) }
        $BroadcastResult = [IntPtr]::Zero
        [void][W32.Fonts]::SendMessageTimeout([IntPtr]0xffff, 0x001D, [IntPtr]::Zero, [IntPtr]::Zero, 2, 1000, [ref]$BroadcastResult)

        Write-Host "OK  $Label installed per-user ($FontsDir)"
    } catch {
        Write-Host "!!  $Label install failed: $_" -ForegroundColor Yellow
        Write-Host "    Get it by hand: https://github.com/$Repo/releases" -ForegroundColor Yellow
    } finally {
        if ($Zip) { Remove-Item $Zip -Force -ErrorAction SilentlyContinue }
        if ($Dst) { Remove-Item $Dst -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Install-FontFromRelease -Repo "yuru7/PlemolJP" -AssetPattern '^PlemolJP_NF_.*\.zip$' -Label "PlemolJP NF"

# The mac primary since `250235e`, and the reason this box gets it too: it is
# what $WtFont below points at. NOT a Nerd Font — the powerline/devicon glyphs
# (and the statusline's nf-fa-microchip) come from DirectWrite falling back to
# the NF families above, exactly as ghostty falls back on the Mac. That is why
# the PlemolJP/Maple/Monaspace installs stay even when nothing selects them.
# The desktop zip, NOT the -Android one, which ships a different name table.
Install-FontFromRelease -Repo "googlefonts/googlesans-code" -AssetPattern '^GoogleSansCode-v[\d.]+\.zip$' -Label "Google Sans Code"

# ─── Windows Terminal: colour scheme + font (stack theme, 4th layer) ────
# The stack theme is normally 3 layers (ghostty + nvim + tmux), NONE of which
# runs natively on Windows. Windows Terminal is the one layer that does exist
# here, and its `schemes` are the same data as a ghostty theme: 16 ANSI +
# bg/fg/cursor/selection. So the family reaches this machine after all.
#
# GENERATED from ghostty/themes/<id>, never a second copy of the palette in the
# repo. That is the whole point: the repo's rule for this theme is that the
# craftzdog plugin is the source of truth and the ghostty file is its hand-baked
# mirror -- a third hand-maintained copy is exactly how mirrors drift. Parsing
# 20 lines of `key = #hex` is cheaper than keeping a .json in sync forever.
#
# $WtTheme IS the selection line for Windows, versioned and direct, same shape
# as ghostty's `theme =` / tmux's `source themes/<id>.conf`. It does NOT read
# ghostty's line. That both happen to say `solarized-osaka` today is a
# coincidence, not a coupling: a native-Windows box shares NONE of the other
# three layers, so following ghostty would mean a mac theme change silently
# repainting a machine that has no ghostty installed. Change the look by editing
# this line and re-running -- no switcher, no pointer.
$WtTheme = "solarized-osaka"

# $WtFont is the font half of the same idea, and it DOES track the Mac: it is
# ghostty's `font-family` (`250235e`). Kept as its own line rather than parsed
# out of config.ghostty because the two boxes have different font inventories --
# a family the Mac has via brew may simply not exist here, and a `font-family`
# WT cannot resolve falls back SILENTLY (same trap as ghostty's, which is why
# the repo's rule is to verify the family name, never to trust the config).
# $WtFonts is what we are allowed to overwrite: the families this installer
# itself puts on the box. Anything else in that field was chosen by hand.
# ⚠️ NOT "Google Sans Code" — that family does not exist on Windows, and asking
# for it renders the fallback with no error at all. The GitHub release ships ONE
# variable font with a `MONO` axis, and DirectWrite splits its named instances
# into TWO families: `Google Sans Code Monospace` and `... Proportional`. The Mac
# gets away with the bare name because brew's cask is a different build. Enumerated,
# not guessed: `[System.Windows.Media.Fonts]::SystemFontFamilies` is the DirectWrite
# view, i.e. what WT actually resolves against — GDI+ (System.Drawing) reports a
# third set of names ("Google Sans Code ExtraBold Mono") and is the wrong oracle here.
# Naming the Monospace instance also settles the mono/proportional choice explicitly,
# which is not something to leave to a fallback in a terminal.
$WtFont  = "Google Sans Code Monospace"
$WtFonts = @("Google Sans Code Monospace", "Google Sans Code", "Maple Mono NF", "PlemolJP Console NF", "PlemolJP35 Console NF", "Monaspace Neon", "MonaspiceNe NF")

# Claude launchers -- the moral equivalent of tmux's `M-c` / `M-C`
# (utility.conf), on the one layer this box shares with the rest of the stack.
# NOT the same chords, and the reason is a hard rule about terminal keys:
#
#   - `ctrl+<letter>` is free as far as WT is concerned (its defaults.json
#     reserves ZERO of them) and is still the wrong place to bind. That chord IS
#     a control character: binding it in WT eats it before the shell, and every
#     app inside loses a key -- PSReadLine's ctrl+r, nvim's ctrl+w, Claude
#     Code's own ctrl+r / ctrl+b / ctrl+o. ctrl+c is only the loudest example.
#   - `ctrl+shift+<letter>` cannot be encoded as a control character at all, so
#     no app inside the terminal ever receives one. Nothing is stolen. That is
#     why WT's own shortcuts live there, and why ours do too.
#   - `ctrl+alt+<letter>` is AltGr on an ISO-LA keyboard (this box). Taking it
#     costs you a character you type daily -- ctrl+alt+q IS `@`. Never.
#
# So the with/without-Shift pair the tmux binds use cannot exist here (its
# no-Shift half would be a control char) and yolo gets its own letter instead.
# Occupied by WT 1.24: a c d f k m n p t v w. Enumerated, not guessed --
# `(Get-AppxPackage Microsoft.WindowsTerminal).InstallLocation\defaults.json`
# is readable, and it is JSONC, so regex it rather than ConvertFrom-Json.
#
# `sendInput` TYPES at the prompt, it does not spawn: no popup, no dedicated
# session, no md5-of-path reuse like the tmux binds -- WT has no equivalent of
# any of that. Press it mid-command and you inject text into that command's
# stdin, which is the whole (small) cost of doing this with 2 lines of config.
#
# Two arrays, not one: since WT 1.19 an `actions` entry DEFINES a command under
# an `id` and `keybindings` maps a chord to that id. The old shape (inline
# `keys` inside `actions`) still parses, but WT rewrites it into the split one
# the next time it saves settings itself -- at which point an upsert keyed on
# `keys` no longer recognises its own entry and appends a duplicate on every
# re-run. Keyed on the id instead, both halves survive that migration.
$WtBinds = @(
    @{ id = "User.claude";     keys = "ctrl+shift+l"; input = "claude`r" },
    @{ id = "User.claudeYolo"; keys = "ctrl+shift+y"; input = "claude --dangerously-skip-permissions`r" }
)

$ThemesDir    = Join-Path $Dotfiles "ghostty\themes"
$GhosttyTheme = Join-Path $ThemesDir $WtTheme

Write-Host ""
Write-Host "-> Windows Terminal: scheme $WtTheme, font $WtFont"

# Anchored on the key NAMES, so a `#`-comment line can never match: every line
# of prose in those files starts with `#`, and `#001419` only ever appears after
# a `key =`. cursor-text and selection-foreground are parsed by nobody -- WT has
# no equivalent for either, and that is the only loss in the port.
$Pal = @{}
if (Test-Path $GhosttyTheme) {
    foreach ($ThemeLine in (Get-Content $GhosttyTheme)) {
        if ($ThemeLine -match '^\s*palette\s*=\s*(\d+)\s*=\s*(#[0-9a-fA-F]{6})') {
            $Pal[[int]$Matches[1]] = $Matches[2]
        } elseif ($ThemeLine -match '^\s*(background|foreground|cursor-color|selection-background)\s*=\s*(#[0-9a-fA-F]{6})') {
            $Pal[$Matches[1]] = $Matches[2]
        }
    }
}

# WT's own order for the 16: index 5 is `purple`, not magenta.
$AnsiNames = @("black", "red", "green", "yellow", "blue", "purple", "cyan", "white",
               "brightBlack", "brightRed", "brightGreen", "brightYellow",
               "brightBlue", "brightPurple", "brightCyan", "brightWhite")

$Missing = @(0..15 | Where-Object { -not $Pal.ContainsKey($_) }) +
           @("background", "foreground", "cursor-color", "selection-background" | Where-Object { -not $Pal.ContainsKey($_) })

if (-not (Test-Path $GhosttyTheme)) {
    Write-Host "!!  no such theme: ghostty\themes\$WtTheme -- skipping" -ForegroundColor Yellow
} elseif ($Missing.Count -gt 0) {
    Write-Host "!!  $WtTheme is missing $($Missing -join ', ') -- skipping" -ForegroundColor Yellow
} else {
    $Scheme = [ordered]@{ name = $WtTheme }
    for ($i = 0; $i -lt 16; $i++) { $Scheme[$AnsiNames[$i]] = $Pal[$i] }
    $Scheme["background"]          = $Pal["background"]
    $Scheme["foreground"]          = $Pal["foreground"]
    $Scheme["cursorColor"]         = $Pal["cursor-color"]
    $Scheme["selectionBackground"] = $Pal["selection-background"]

    # Every WT install on the box: Store, Preview, and unpackaged all keep their
    # own settings.json and none of them is authoritative.
    $WtPaths = @(
        (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
        (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"),
        (Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json")
    ) | Where-Object { Test-Path $_ }

    if (-not $WtPaths) {
        Write-Host "i   Windows Terminal settings.json not found -- skipping (WT not installed?)"
    }

    foreach ($WtPath in $WtPaths) {
        # WT's settings.json is JSONC and ships with `//` comments; ConvertFrom-Json
        # rejects those. NOT stripped with a regex -- `"https://aka.ms/..."` is a
        # `//` inside a string and a naive strip would corrupt the user's file. Once
        # WT saves the file itself (any UI change) the comments are gone and this
        # works; until then we say so and touch nothing.
        try {
            $Wt = Get-Content $WtPath -Raw | ConvertFrom-Json
        } catch {
            Write-Host "!!  could not parse $WtPath (JSON comments?) -- skipping" -ForegroundColor Yellow
            Write-Host "    change any setting from the WT UI once, then re-run" -ForegroundColor Yellow
            continue
        }

        # Upsert by name, NOT append: this is our own named scheme, so a palette
        # edit upstream has to propagate on re-run. Anything else in the array is
        # the user's and is carried over untouched.
        if (-not ($Wt.PSObject.Properties.Name -contains "schemes")) {
            $Wt | Add-Member -NotePropertyName "schemes" -NotePropertyValue @()
        }
        $Wt.schemes = @(@($Wt.schemes | Where-Object { $_.name -ne $WtTheme }) + [PSCustomObject]$Scheme)

        # profiles.defaults so it covers every profile, present and future.
        if (-not ($Wt.PSObject.Properties.Name -contains "profiles")) {
            $Wt | Add-Member -NotePropertyName "profiles" -NotePropertyValue ([PSCustomObject]@{})
        }
        if (-not ($Wt.profiles.PSObject.Properties.Name -contains "defaults")) {
            $Wt.profiles | Add-Member -NotePropertyName "defaults" -NotePropertyValue ([PSCustomObject]@{})
        }

        # The one write here that is NOT additive-only, and deliberately so: the
        # selection line above is useless if a re-run cannot switch the theme. It
        # is bounded to values WE could have written -- any id in ghostty/themes/
        # -- so a scheme you picked by hand ("Campbell", a downloaded one) is left
        # alone and reported instead of being clobbered.
        $Family  = @(Get-ChildItem $ThemesDir -File | Select-Object -ExpandProperty Name)
        $Current = $Wt.profiles.defaults.colorScheme
        if ($Current -and ($Family -notcontains $Current)) {
            Write-Host "i   $WtPath keeps its own colorScheme ('$Current') -- scheme installed, not applied"
        } elseif ($Wt.profiles.defaults.PSObject.Properties.Name -contains "colorScheme") {
            $Wt.profiles.defaults.colorScheme = $WtTheme
        } else {
            $Wt.profiles.defaults | Add-Member -NotePropertyName "colorScheme" -NotePropertyValue $WtTheme
        }

        # Font. Same bounded-clobber rule as colorScheme, against $WtFonts.
        # `font` is an OBJECT in the modern schema (`font.face`); the flat
        # `fontFace` string is the deprecated one. We only write the modern
        # shape, and if a hand-edited file still carries the legacy key we say
        # so instead of writing both -- two keys for one setting is how a
        # config starts lying about what is actually rendering.
        if ($Wt.profiles.defaults.PSObject.Properties.Name -contains "fontFace") {
            Write-Host "i   $WtPath uses the deprecated 'fontFace' -- leaving the font alone"
        } else {
            if (-not ($Wt.profiles.defaults.PSObject.Properties.Name -contains "font")) {
                $Wt.profiles.defaults | Add-Member -NotePropertyName "font" -NotePropertyValue ([PSCustomObject]@{})
            }
            $CurrentFace = $Wt.profiles.defaults.font.face
            if ($CurrentFace -and ($WtFonts -notcontains $CurrentFace)) {
                Write-Host "i   $WtPath keeps its own font ('$CurrentFace') -- not applied"
            } elseif ($Wt.profiles.defaults.font.PSObject.Properties.Name -contains "face") {
                $Wt.profiles.defaults.font.face = $WtFont
            } else {
                $Wt.profiles.defaults.font | Add-Member -NotePropertyName "face" -NotePropertyValue $WtFont
            }
        }

        # Keybindings. Upsert by id in BOTH arrays -- same by-name rule as
        # `schemes`, for the same reason: editing $WtBinds above has to actually
        # propagate on re-run instead of appending a second entry.
        # Bounded clobber, again: a chord already bound to someone else's id is
        # reported and left alone, never stolen. WT resolves a duplicate chord to
        # the last entry, so appending blindly would silently win that fight.
        foreach ($Arr in @("actions", "keybindings")) {
            if (-not ($Wt.PSObject.Properties.Name -contains $Arr)) {
                $Wt | Add-Member -NotePropertyName $Arr -NotePropertyValue @()
            }
        }
        foreach ($Bind in $WtBinds) {
            $Clash = @($Wt.keybindings | Where-Object { $_.keys -eq $Bind.keys -and $_.id -ne $Bind.id })[0]
            if ($Clash) {
                Write-Host "i   $WtPath binds $($Bind.keys) to '$($Clash.id)' -- not applied"
                continue
            }
            $Wt.actions = @(@($Wt.actions | Where-Object { $_.id -ne $Bind.id }) +
                [PSCustomObject]@{
                    id      = $Bind.id
                    command = [PSCustomObject]@{ action = "sendInput"; input = $Bind.input }
                })
            $Wt.keybindings = @(@($Wt.keybindings | Where-Object { $_.id -ne $Bind.id }) +
                [PSCustomObject]@{ id = $Bind.id; keys = $Bind.keys })
        }

        [System.IO.File]::WriteAllText($WtPath, ($Wt | ConvertTo-Json -Depth 100), $Utf8NoBom)
        Write-Host "OK  $WtTheme applied to $WtPath"
    }
}

Write-Host ""
Write-Host "Done. Next steps:"
Write-Host "  1. Restart the terminal so the new PATH takes effect."
Write-Host "  2. Restart Claude Code."
Write-Host "  3. If the symlinks failed: enable Developer Mode and re-run this script."
Write-Host "  4. Windows Terminal already has the scheme and the font applied. If the"
Write-Host "     text looks unchanged, the family name did not resolve and WT fell back"
Write-Host "     SILENTLY -- check Appearance > Font face for what it really picked."
