# dotfiles

Personal config for macOS — Ghostty terminal, zsh, Starship prompt.

## What's here

| Path | What |
|---|---|
| `zsh/.zshrc` | Interactive shell config (no Oh My Zsh — startup ~30ms) |
| `zsh/.zshenv` | Env vars and PATH, loaded for all shells |
| `starship/starship.toml` | Starship prompt config — Vesper palette |
| `ghostty/config.ghostty` | Ghostty terminal config — Vesper theme + Monaspace |
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
brew install --cask ghostty
```

## Secrets

Secrets (DB passwords, API keys) live in `~/.zshenv.local` which is **not versioned**. Create it manually on each machine:

```sh
# ~/.zshenv.local — never commit
export PG_FINANCE_PASSWORD="..."
export REDASH_API_KEY="..."
```

`.zshenv` automatically sources `.zshenv.local` if present.
