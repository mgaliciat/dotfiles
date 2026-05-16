# dotfiles

Personal config for macOS — Ghostty terminal, zsh, Starship prompt.

## What's here

| Path | What |
|---|---|
| `zsh/.zshrc` | Interactive shell config (no Oh My Zsh — startup ~30ms) |
| `zsh/.zshenv` | Env vars and PATH, loaded for all shells |
| `starship/starship.toml` | Starship prompt config — Vesper palette |
| `ghostty/config.ghostty` | Ghostty terminal config — Vesper theme + Monaspace |
| `git/.gitconfig` | Git config with delta pager + aliases |
| `git/.gitignore_global` | Global gitignore (macOS noise, editor files, build dirs) |
| `nvim/` | Neovim config (legacy from 2022 — not currently in use) |
| `install.sh` | Symlinks everything into place |

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

1. Symlinkear configs (`.zshrc`, `.zshenv`, `.gitconfig`, ghostty, starship, claude/skills, claude/memory si existen local)
2. Heredar/crear `~/.gitconfig.local` con tu identidad git (interactivo solo si la máquina está virgen)
3. Auto-instalar dependencias faltantes vía Homebrew:
   - **Formulae**: `starship`, `zsh-syntax-highlighting`, `zsh-autosuggestions`, `zsh-history-substring-search`, `eza`, `bat`, `fd`, `ripgrep`, `zoxide`, `fzf`, `git-delta`, `pyenv`
   - **Casks**: `ghostty`
4. Registrar VS Code como app por defecto para `.ghostty` (si VS Code está instalado)

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
