<p align="center">
  <img src="assets/dotfiles-icon-paper.svg" alt="dotfiles" width="128">
</p>

<h1 align="center">dotfiles</h1>

Personal config for macOS — Ghostty terminal, zsh, Starship prompt, Neovim, tmux, lazygit.

## What's here

| Path | What |
|---|---|
| `zsh/.zshrc` | Interactive shell config (no Oh My Zsh — startup ~60ms) |
| `zsh/.zshenv` | Env vars and PATH, loaded for all shells |
| `starship/starship.toml` | Starship prompt config |
| `ghostty/config.ghostty` | Ghostty terminal config — theme, fonts, keybinds |
| `git/.gitignore_global` | Global gitignore — macOS noise, editor files, build dirs, **y también scratch de agentes IA** (`.claude/`, `.cursor/`, `.aider*`, `.covenant/`, etc.) que se excluye a propósito en todos los repos |
| `nvim/` | Neovim config — lazy.nvim, modular `lua/plugins/*`; el tema activo es `vim.g.theme` en `lua/config/options.lua` (hoy `solarized-osaka`, parte del tema cross-stack Ghostty+nvim+tmux). Cheatsheets: `NVIM-CHEATSHEET.md` (raíz) es el más al día en cobertura de plugins; `nvim/CHEATSHEET.md` tiene más detalle de vim nativo/LSP pero le faltan plugins |
| `tmux/` | tmux config — prefix `C-t`, popups Alt+c/C/y/u/d/g/Enter, modular (theme/statusline/utility). Cheatsheet en `tmux/CHEATSHEET.md` |
| `lazygit/config.yml` | lazygit theme + custom commands |
| `scripts/` | Helpers — `ide` (layout tmux de 4 panes estilo IDE, `prefix + g`) |
| `claude/` | Config user-level de Claude Code — `CLAUDE.md` (→ `~/.claude/CLAUDE.md`, qué herramientas de este dotfiles usar) y `statusline.sh`. `settings.json`, `skills/` y `memory/` son **per-máquina**: ni versionados ni symlinkeados |
| `install.sh` | Entry point macOS — symlinks + auto-install deps |
| `install-linux.sh` | Portable subset para Ubuntu/Debian/WSL2 |
| `install-windows.ps1` | Windows nativo (sin WSL2) — alcance angosto, solo piezas de Claude Code (ver comentario en el script) |

## Setup on a new machine

Pre-requisito: **Homebrew** instalado. Si no lo tenés:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Después:

```bash
git clone https://github.com/mgaliciat/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` se encarga de:

1. Symlinkear configs (`.zshrc`, `.zshenv`, `.gitignore_global`, ghostty, starship, nvim, tmux, lazygit, `claude/CLAUDE.md`, `claude/statusline.sh`)
2. Auto-instalar dependencias faltantes vía Homebrew:
   - **Formulae**: `starship`, `zsh-syntax-highlighting`, `zsh-autosuggestions`, `zsh-history-substring-search`, `eza`, `bat`, `fd`, `ripgrep`, `gomi`, `zoxide`, `fzf`, `jq`, `git-delta`, `pyenv`, `neovim`, `tree-sitter-cli`, `tmux`, `lazygit`, `rtk`
   - **Casks**: `ghostty`, `font-plemol-jp-nf`, `font-ia-writer-mono`, `font-monaspace`
3. Configurar Claude Code (todo idempotente, y **additive-only**: si ya armaste algo a mano en esa máquina, no se pisa):
   - `statusLine` + `permissions` base en el `settings.json` real (que NO se versiona)
   - [`rtk`](https://github.com/rtk-ai/rtk) — proxy CLI que reescribe comandos Bash a su equivalente comprimido para ahorrar tokens. Transparente vía hook `PreToolUse`
   - [`codebase-memory-mcp`](https://github.com/DeusData/codebase-memory-mcp) — MCP server que indexa el código en un grafo consultable
   - Plugins [`ponytail`](https://github.com/DietrichGebert/ponytail) (lazy senior dev) y [`andrej-karpathy-skills`](https://github.com/multica-ai/andrej-karpathy-skills) (guidelines) — solo en macOS por ahora
4. Clonar tpm (Tmux Plugin Manager) si falta
5. Recargar tmux config si hay un server corriendo
6. Registrar VS Code como app por defecto para `.ghostty` (si VS Code está instalado)

**`~/.gitconfig` NO se versiona ni symlinkea** — cada máquina mantiene el suyo 100% propio (credenciales, 1Password vaults, signing keys son per-máquina). Cuando configures una Mac nueva, copiá tu `.gitconfig` desde donde lo tengas backupeado.

**Caps Lock → Option** se configura en System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys (no se versiona, es per-device).

## Sync existing machine

Después de `git pull` en una Mac que ya está configurada, los archivos quedan actualizados vía symlinks, **pero las herramientas que ya están corriendo siguen con la config vieja en memoria**. Para aplicar:

| Herramienta cambió | Cómo aplicar |
|---|---|
| `zsh/*` | `exec zsh` en cada terminal abierta |
| `starship/*` | Automático — se relee en cada prompt |
| `ghostty/*` | `Cmd+Shift+R` recarga la mayoría de settings. **Para `keybind` nuevos: quit completo (`Cmd+Q`) + relanzar** — el reload no siempre los aplica |
| `tmux/*` | `./install.sh` ya lo hace; o manual: `tmux source ~/.config/tmux/tmux.conf` |
| `nvim/*` | Reiniciar nvim (o `:Lazy reload <plugin>` para plugins puntuales) |
| `lazygit/*` | Cerrar y reabrir lazygit |

Atajo: correr `./install.sh` después del pull es idempotente y aplica lo que puede aplicarse sin reiniciar procesos GUI.

## macOS tweaks

`install.sh` también registra **VS Code** como app por defecto para archivos `.ghostty` (sin esto, `⌘,` dentro de Ghostty abre `config.ghostty` en TextEdit porque la extensión no tiene UTI registrada en macOS). Se hace vía `defaults write` sobre `com.apple.LaunchServices` y un rebuild de la DB. Idempotente.

## Per-machine config (not versioned)

- **`~/.gitconfig.local`** — git identity (`user.name`, `user.email`, signing key). Se crea a mano; tu `~/.gitconfig` (que tampoco se versiona) lo incluye vía `[include]` al final para que gane sobre cualquier default.
- **`~/.zshenv.local`** — secrets (DB passwords, API keys). Creado manualmente:

```sh
# ~/.zshenv.local — never commit
export PG_PASSWORD="..."
export REDASH_API_KEY="..."
```

`.zshenv` automatically sources `.zshenv.local` if present.

- **`~/.claude/settings.json`**, **`~/.claude/skills/`**, **`~/.claude/projects/*/memory/`** — estado de Claude Code. Ni versionado ni symlinkeado: los permisos/UI divergen por host, y las skills y memorias las escriben Claude Code y sus binarios en runtime. `install.sh` solo hace merges puntuales y additive-only sobre `settings.json` (statusLine, permisos base, hooks de rtk/codebase-memory) — nunca lo pisa entero.
