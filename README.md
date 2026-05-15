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
| `claude/settings.json` | Claude Code global settings |
| `claude/skills/` | Custom Claude Code skills |
| `nvim/` | Neovim config (legacy from 2022 — not currently in use) |
| `install.sh` | Symlinks everything into place |

## Setup on a new machine

```bash
git clone git@github.com:mgaliciat/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Required packages:

```bash
brew install starship zsh-syntax-highlighting zsh-autosuggestions
brew install eza bat fd ripgrep zoxide fzf git-delta
brew install --cask ghostty
```

## macOS tweaks

`install.sh` también registra **VS Code** como app por defecto para archivos `.ghostty` (sin esto, `⌘,` dentro de Ghostty abre `config.ghostty` en TextEdit porque la extensión no tiene UTI registrada en macOS). Se hace vía `defaults write` sobre `com.apple.LaunchServices` y un rebuild de la DB. Idempotente.

## Secrets

Secrets (DB passwords, API keys) live in `~/.zshenv.local` which is **not versioned**. Create it manually on each machine:

```sh
# ~/.zshenv.local — never commit
export PG_FINANCE_PASSWORD="..."
export REDASH_API_KEY="..."
```

`.zshenv` automatically sources `.zshenv.local` if present.
