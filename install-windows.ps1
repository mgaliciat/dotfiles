# Piezas de Claude Code para Windows NATIVO (sin WSL2 — WSL2 usa
# install-linux.sh, que ya lo detecta y da hints específicos).
#
# Alcance intencionalmente chico: zsh/tmux/nvim no corren nativos en
# Windows, así que este script NO es un port del resto del dotfiles —
# ver CLAUDE.md, sección "per-máquina split". Cubre únicamente:
#   - symlinks de claude/statusline.sh y claude/CLAUDE.md
#   - statusLine + permissions base en settings.json (equivalente a los
#     bloques jq de install.sh/install-linux.sh, acá con JSON nativo)
#   - rtk (sin instalador oficial para Windows — bajamos el zip release)
#   - codebase-memory-mcp (instalador oficial install.ps1)
#
# Uso: abrí PowerShell (5.1 o pwsh 7+) parado en esta carpeta y corré
#   ./install-windows.ps1
# Si da error de política de ejecución:
#   PowerShell -ExecutionPolicy Bypass -File .\install-windows.ps1
#
# Symlinks en Windows requieren Developer Mode activado (Settings >
# Privacy & security > For developers) o correr como Administrador. Si
# no está disponible, el script cae a copiar el archivo (avisa en pantalla)
# — no se van a propagar futuros `git pull` hasta que actives Developer Mode
# y re-corras el script.

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
        Write-Host "!!  no se pudo symlinkear $Destination (activa Developer Mode o corre como Administrador)" -ForegroundColor Yellow
        Write-Host "    copiando en su lugar -- futuros 'git pull' no se van a propagar hasta re-correr este script" -ForegroundColor Yellow
        Copy-Item $Source $Destination -Force
    }
}

# ─── symlinks ──────────────────────────────────────────────────
Set-DotfileSymlink (Join-Path $Dotfiles "claude\statusline.sh") (Join-Path $ClaudeDir "statusline.sh")
Set-DotfileSymlink (Join-Path $Dotfiles "claude\CLAUDE.md")     (Join-Path $ClaudeDir "CLAUDE.md")

# ─── settings.json: statusLine + permisos base ─────────────────
# Additive-only, igual que install.sh/install-linux.sh: si la key ya
# existe (armaste tu propia config a mano en esta máquina) no se toca.
$SettingsPath = Join-Path $ClaudeDir "settings.json"
$Settings = if (Test-Path $SettingsPath) {
    Get-Content $SettingsPath -Raw | ConvertFrom-Json
} else {
    [PSCustomObject]@{}
}

if ($Settings.PSObject.Properties.Name -contains "statusLine") {
    Write-Host "OK  statusLine ya configurado en settings.json -- no se toca"
} else {
    $Settings | Add-Member -NotePropertyName "statusLine" -NotePropertyValue ([PSCustomObject]@{
        type    = "command"
        command = "~/.claude/statusline.sh"
    })
    Write-Host "OK  statusLine agregado a settings.json"
}

if (-not ($Settings.PSObject.Properties.Name -contains "permissions")) {
    $Settings | Add-Member -NotePropertyName "permissions" -NotePropertyValue ([PSCustomObject]@{})
}

if ($Settings.permissions.PSObject.Properties.Name -contains "allow") {
    Write-Host "OK  permissions.allow ya configurado en settings.json -- no se toca"
} else {
    $Settings.permissions | Add-Member -NotePropertyName "allow" -NotePropertyValue @(
        "Bash(git add *)",
        "Bash(git commit *)",
        "Bash(npm run *)",
        "Bash(npm test *)",
        "Bash(cargo build *)",
        "Bash(cargo test *)",
        "Bash(make *)",
        "Bash(docker ps *)",
        "Bash(docker images *)",
        "Bash(go build *)",
        "Bash(go test *)",
        "Bash(go vet *)",
        "Bash(go mod *)",
        "Bash(go run *)",
        "Bash(gofmt *)",
        "Bash(kotlinc *)",
        "Bash(ktlint *)",
        "Bash(./gradlew build)",
        "Bash(./gradlew test)",
        "Bash(./gradlew clean)",
        "Bash(gradle build)",
        "Bash(gradle test)",
        "Bash(fzf *)",
        "Bash(rg *)",
        "Bash(fd *)",
        "Bash(eza *)",
        "Bash(bat *)",
        "Bash(jq *)",
        "Bash(tree *)",
        "Bash(delta *)"
    )
    Write-Host "OK  permissions.allow agregado a settings.json"
}

if ($Settings.permissions.PSObject.Properties.Name -contains "deny") {
    Write-Host "OK  permissions.deny ya configurado en settings.json -- no se toca"
} else {
    $Settings.permissions | Add-Member -NotePropertyName "deny" -NotePropertyValue @(
        "Bash(rm -rf *)",
        "Bash(git push --force*)",
        "Bash(sudo *)"
    )
    Write-Host "OK  permissions.deny agregado a settings.json"
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($SettingsPath, ($Settings | ConvertTo-Json -Depth 10), $Utf8NoBom)

# ─── rtk (proxy CLI que reduce tokens) ──────────────────────────
# Sin instalador oficial para Windows (docs solo dan el zip release +
# extracción manual) -- bajamos del URL estable "latest/download/<asset>"
# de GitHub (no requiere consultar la API) y lo dejamos en
# %LOCALAPPDATA%\Programs\rtk, mismo patrón de directorio que usa el
# installer oficial de codebase-memory-mcp más abajo.
$RtkDir = Join-Path $env:LOCALAPPDATA "Programs\rtk"
$RtkExe = Join-Path $RtkDir "rtk.exe"

$RtkCmd = Get-Command rtk -ErrorAction SilentlyContinue
if (-not $RtkCmd -and -not (Test-Path $RtkExe)) {
    Write-Host ""
    Write-Host "-> Instalando rtk"
    $TmpZip = Join-Path $env:TEMP "rtk.zip"
    try {
        Invoke-WebRequest -Uri "https://github.com/rtk-ai/rtk/releases/latest/download/rtk-x86_64-pc-windows-msvc.zip" -OutFile $TmpZip
        New-Item -ItemType Directory -Path $RtkDir -Force | Out-Null
        Expand-Archive -Path $TmpZip -DestinationPath $RtkDir -Force
    } catch {
        Write-Host "!!  rtk install fallo: $_" -ForegroundColor Yellow
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
        Write-Host "OK  $RtkDir agregado al PATH de usuario"
    }
    try {
        & $RtkExe init --global --auto-patch | Out-Null
        Write-Host "OK  rtk hook de Claude Code configurado (o ya estaba)"
    } catch {
        Write-Host "!!  rtk init --global fallo -- revisar a mano ($RtkExe init --global -v)" -ForegroundColor Yellow
    }
} else {
    Write-Host "!!  rtk no se pudo instalar -- revisar a mano (https://github.com/rtk-ai/rtk)" -ForegroundColor Yellow
}

# ─── codebase-memory-mcp (MCP server de grafo de código) ────────
# Instalador oficial (install.ps1): baja el binario, corre
# `install -y` solo (configura Claude Code + agrega su propio dir al
# PATH de usuario), variante sin --ui (headless, default). Solo se
# corre si el binario no está ya presente.
if (-not (Get-Command codebase-memory-mcp -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "-> Instalando codebase-memory-mcp"
    $TmpPs1 = Join-Path $env:TEMP "cbm-install.ps1"
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.ps1" -OutFile $TmpPs1
        Unblock-File $TmpPs1
        & $TmpPs1
    } catch {
        Write-Host "!!  codebase-memory-mcp install fallo: $_" -ForegroundColor Yellow
    } finally {
        Remove-Item $TmpPs1 -Force -ErrorAction SilentlyContinue
    }
}

$Cbm = Get-Command codebase-memory-mcp -ErrorAction SilentlyContinue
if ($Cbm) {
    & $Cbm.Source config set auto_index true | Out-Null
    Write-Host "OK  codebase-memory-mcp: auto_index=true"
}

Write-Host ""
Write-Host "Listo. Próximos pasos:"
Write-Host "  1. Reiniciá la terminal para que el PATH nuevo tome efecto."
Write-Host "  2. Reiniciá Claude Code."
Write-Host "  3. Si los symlinks fallaron: activá Developer Mode y re-corré este script."
