<p align="center">
  <img src="assets/dotfiles-icon-paper.svg" alt="dotfiles" width="128">
</p>

<h1 align="center">dotfiles</h1>

Personal config for macOS — Ghostty terminal, zsh, Starship prompt, Neovim, tmux, lazygit.

## What's here

| Path | What |
|---|---|
| `zsh/.zshrc` | Interactive shell config (no Oh My Zsh — startup ~30ms) |
| `zsh/.zshenv` | Env vars and PATH, loaded for all shells |
| `starship/starship.toml` | Starship prompt config |
| `ghostty/config.ghostty` | Ghostty terminal config — theme, fonts, keybinds |
| `git/.gitignore_global` | Global gitignore (macOS noise, editor files, build dirs) |
| `nvim/` | Neovim config — lazy.nvim, modular `lua/plugins/*`, solarized-osaka theme |
| `tmux/` | tmux config — prefix `C-t`, popups Alt+c/C/s/g/Enter, modular (theme/statusline/utility) |
| `lazygit/config.yml` | lazygit theme + custom commands |
| `scripts/` | Helpers — `ide` (nvim+lazygit IDE layout), `tmux-claude` (session picker) |
| `install.sh` | Symlinks everything into place + auto-install deps |
| `install-linux.sh` | Portable subset para Ubuntu/Debian/WSL2 |

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

1. Symlinkear configs (`.zshrc`, `.zshenv`, `.gitignore_global`, ghostty, starship, nvim, tmux, lazygit, claude/skills, claude/memory si existen local)
2. Auto-instalar dependencias faltantes vía Homebrew:
   - **Formulae**: `starship`, `zsh-syntax-highlighting`, `zsh-autosuggestions`, `zsh-history-substring-search`, `fzf-tab`, `eza`, `bat`, `fd`, `ripgrep`, `zoxide`, `fzf`, `git-delta`, `pyenv`, `neovim`, `tree-sitter-cli`, `tmux`, `lazygit`
   - **Casks**: `ghostty`, `font-plemol-jp-nf`, `font-ia-writer-mono`, `font-monaspace`
3. Clonar tpm (Tmux Plugin Manager) si falta
4. Recargar tmux config si hay un server corriendo
5. Registrar VS Code como app por defecto para `.ghostty` (si VS Code está instalado)

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

- **`~/.gitconfig.local`** — git identity (`user.name`, `user.email`, signing key). `install.sh` te lo pregunta interactivamente la primera vez y lo crea. `git/.gitconfig` lo incluye automáticamente vía `[include]`.
- **`~/.zshenv.local`** — secrets (DB passwords, API keys). Creado manualmente:

```sh
# ~/.zshenv.local — never commit
export PG_FINANCE_PASSWORD="..."
export REDASH_API_KEY="..."
```

`.zshenv` automatically sources `.zshenv.local` if present.
