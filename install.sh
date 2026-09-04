#!/usr/bin/env bash
# Symlinks dotfiles into their expected locations.
# Idempotent: backs up existing files before linking.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d_%H%M%S)"

# link(), link_portable(), install_claude() and the bootstraps, shared with
# install-linux.sh.
source "$DOTFILES/scripts/lib.sh"

# zsh, git, nvim, tmux, lazygit, ~/.local/bin tools — the list is in lib.sh so
# both installers link the same set. Only Ghostty is mac-specific, below.
link_portable

# A stale orphaned `config` (no extension) wins over our symlink and loads its
# own inline content, ignoring the dotfiles theme. Defensive backup before
# linking config.ghostty.
GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
if [[ -f "$GHOSTTY_DIR/config" && ! -L "$GHOSTTY_DIR/config" ]]; then
  mv "$GHOSTTY_DIR/config" "$GHOSTTY_DIR/config.backup.$TS"
  echo "→ stale ghostty config moved to config.backup.$TS"
fi
link "$DOTFILES/ghostty/config.ghostty" "$GHOSTTY_DIR/config.ghostty"
# Custom themes (wallpaper sampling, own palettes). CAREFUL: Ghostty looks for
# themes in ~/.config/ghostty/themes/ (XDG path), NOT in the same Application
# Support dir where the config lives — they are different dirs. If you put them
# in Application Support, Ghostty ignores them and errors with "theme not found".
# Symlink the whole dir so new themes are exposed automatically.
# This also exposes the "stack theme" family: new themes in ghostty/themes,
# nvim/lua/themes and tmux/themes ride along for free with the parent dir
# symlinks — no need to link them one by one.
if [[ -d "$DOTFILES/ghostty/themes" ]]; then
  mkdir -p "$HOME/.config/ghostty"
  link "$DOTFILES/ghostty/themes"       "$HOME/.config/ghostty/themes"
fi

# ─── stack theme ──────────────────────────────────────────────
# Nothing to do here. The theme selection is a direct value in each versioned
# config (Ghostty `theme =`, nvim `vim.g.theme`, the palette `source` in
# tmux.conf) and arrives with the clone/pull; the dir symlinks above expose the
# palettes with no extra work. Changing the theme on ALL machines = edit those
# 3 lines + commit + pull.

# Caps Lock → Option: System Settings → Keyboard → Keyboard Shortcuts →
# Modifier Keys → Caps Lock = Option ⌥. It is per-device and per-machine, not
# versionable; that is why it lives in the UI and not in the repo.
# Karabiner-Elements was ruled out for incompatibility with the MacBook built-in
# keyboard + Latin American layout (it swapped <> with |° because its virtual HID
# only supports the generic ansi/iso layouts).

# ~/.gitconfig is NOT symlinked — each machine keeps its own 100%
# (credentials, 1Password vaults, signing keys are per-machine).

# Claude Code: all per-machine, not versioned. settings.json is NOT symlinked
# (it is 100% each host's own, like ~/.gitconfig): permissions/UI diverge per
# machine and it was dragging personal state into a public repo.
#
# skills/ is not symlinked either (since jul-2026). ~/.claude/skills is the REAL
# path where Claude Code reads the user's skills, so the symlink did work — but
# it pointed at the repo, while its content (the `learned` skill that Claude
# writes, `codebase-memory` that the binary rewrites on every install) is 100%
# per-machine: it was never versioned, it lived gitignored. Zero benefit, and a
# `git add -f` or a loosened .gitignore leaked personal state into a public repo.
# Today it is a real dir; the codebase-memory-mcp binary creates it if missing.
#
# memory/ is NOT symlinked, for a DIFFERENT reason: Claude Code derives the
# project-id from the REAL path of the directory (e.g. working in ~/dotfiles it
# uses ...projects/-Users-foo-dotfiles/memory), so there the symlink pointed at
# the wrong path and was ignored. Memory is per-project and Claude Code handles
# it on its own.

# ─── dependencies (Homebrew) ──────────────────────────────────
# Auto-installs whatever is missing. Idempotent: re-runs detect what is already
# installed and skip it. If there is no brew, it prints how to install it and
# ends without failing the script.
# It goes BEFORE the settings.json blocks below: those use jq (installed here) —
# if they ran first, on a fresh machine they would silently skip and only apply
# on the second run.
if command -v brew >/dev/null 2>&1; then
  REQUIRED_FORMULAE=(
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-history-substring-search
    eza
    bat
    fd
    ripgrep
    gomi                  # `rm` with trash + interactive restore (alias `gm`)
    zoxide
    fzf
    jq                    # required by tmux-claude-session-manager (parses `claude agents --json`)
    gh                    # GitHub CLI — host for the gh-stack extension (bootstrap_gh_stack below)
    git-delta
    pyenv
    neovim
    tree-sitter-cli       # parser generator used by nvim-treesitter's `main` branch
    tmux
    lazygit
    rtk                   # token-reducing proxy CLI for Claude Code — see the rtk section below
  )
  REQUIRED_CASKS=(
    ghostty
    1password-cli         # `op` — a cask on Homebrew, not a formula (lives in Caskroom)
    # Fonts referenced by ghostty/config.ghostty.
    # The primary (font-family) is Paper Mono, which has no cask — it is
    # installed by direct download below, right after this block. It is NOT a
    # Nerd Font, so the rest of this list stops being optional coverage and
    # becomes load-bearing: Ghostty pulls every powerline/devicon glyph from
    # the NF families below. Don't prune them while it's the primary.
    # Google Sans Code, 0xProto NF and Maple Mono NF are all former primaries,
    # each one line away from returning (0xProto resolves as its "Mono"
    # family; see the typography block there). PlemolJP Console NF (JP/EN),
    # Monaspace NF and iA Writer Mono round out the fallback chain (Ghostty
    # falls back to them + bundled JBM NF automatically). Every font named in
    # the config must be installed by this list: a font-family pointing at a
    # missing family falls back silently, the exact drift 0430d08 fixed.
    # Monaspace is the `-nf` (Nerd Font) build, not the plain cask, so it
    # ships its own icons instead of leaning on the JBM NF fallback.
    font-google-sans-code
    font-0xproto-nerd-font
    font-maple-mono-nf
    font-plemol-jp-nf
    font-monaspace-nf
    font-ia-writer-mono
  )

  MISSING_FORMULAE=()
  for pkg in "${REQUIRED_FORMULAE[@]}"; do
    brew list --formula "$pkg" >/dev/null 2>&1 || MISSING_FORMULAE+=("$pkg")
  done

  MISSING_CASKS=()
  for pkg in "${REQUIRED_CASKS[@]}"; do
    brew list --cask "$pkg" >/dev/null 2>&1 || MISSING_CASKS+=("$pkg")
  done

  if [[ ${#MISSING_FORMULAE[@]} -gt 0 ]]; then
    echo ""
    echo "→ Installing missing formulae: ${MISSING_FORMULAE[*]}"
    brew install "${MISSING_FORMULAE[@]}"
  fi

  if [[ ${#MISSING_CASKS[@]} -gt 0 ]]; then
    echo ""
    echo "→ Installing missing casks: ${MISSING_CASKS[*]}"
    brew install --cask "${MISSING_CASKS[@]}"
  fi

  if [[ ${#MISSING_FORMULAE[@]} -eq 0 && ${#MISSING_CASKS[@]} -eq 0 ]]; then
    echo "✓ All Homebrew dependencies are already installed"
  fi
  # ─── Paper Mono (font, no cask) ─────────────────────────────
  # The current font-family in ghostty/config.ghostty (it has traded places
  # with Google Sans Code a few times — check that file, not this comment).
  # Paper released it in jul-2026 and Homebrew has no cask yet — so this is
  # the one font here not installed by brew. Same shape as the PlemolJP block
  # in install-windows.ps1: resolve the latest release, grab its asset, drop
  # the file in place.
  # Only the VARIABLE ttf: one file covers Thin→ExtraBold and the family
  # reports as plain "Paper Mono" (verify with `ghostty +list-fonts`).
  # Installing the 8 static otf/ttf too would register the same family twice.
  # Guarded on the file, not on a `brew list` — nothing else knows about it.
  # If a cask ever appears, delete this block and add it to REQUIRED_CASKS.
  if [[ ! -f "$HOME/Library/Fonts/PaperMono[wght].ttf" ]]; then
    echo ""
    echo "→ Installing Paper Mono font (direct download — no Homebrew cask)"
    PM_URL=$(curl -fsSL "https://api.github.com/repos/paper-design/paper-mono/releases/latest" \
      | grep -o '"browser_download_url": *"[^"]*\.zip"' | cut -d'"' -f4 | head -1)
    if [[ -n "$PM_URL" ]]; then
      PM_TMP=$(mktemp -d)
      # The zip nests everything under paper-mono-vX.Y/, hence the leading `*`.
      # Match the DIRECTORY, not the filename: unzip reads `[wght]` in a
      # pattern as a character class, and Info-ZIP's `[[]` escape doesn't work
      # here. fonts/variable/ holds exactly that one file, so this is exact.
      if curl -fsSL "$PM_URL" -o "$PM_TMP/pm.zip" \
         && unzip -q -j -o "$PM_TMP/pm.zip" '*/fonts/variable/*' -d "$HOME/Library/Fonts"; then
        echo "✓ Paper Mono installed ($HOME/Library/Fonts)"
      else
        echo "⚠️  Paper Mono install failed — get it by hand:"
        echo "     https://github.com/paper-design/paper-mono/releases"
      fi
      rm -rf "$PM_TMP"
    else
      echo "⚠️  Could not resolve the Paper Mono release asset — install by hand:"
      echo "     https://github.com/paper-design/paper-mono/releases"
    fi
  fi
else
  echo ""
  echo "⚠️  Homebrew not detected — skipping dependency auto-install."
  echo "   To install it:"
  echo "     /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  echo "   Then re-run: ./install.sh"
fi

# ─── Claude Code ──────────────────────────────────────────────
# Three mechanisms, one per file, split by WHO writes to settings.json: us with
# jq (settings.sh), the external binary in its own setup command (binaries.sh),
# or the plugin CLI (plugins.sh). The full detail — and which mechanism to use
# to add something new — is in claude/install/README.md.
#
# Sourced in a load-bearing order by install_claude (scripts/lib.sh). It goes
# AFTER the Homebrew block: settings.sh needs jq.
install_claude

bootstrap_tmux
bootstrap_gh_stack

# macOS file associations — open config.ghostty in VS Code (not TextEdit).
# .ghostty has no registered UTI, so macOS falls back to TextEdit by default.
# Idempotent: checks whether the entry already exists before adding it.
if [[ -d "/Applications/Visual Studio Code.app" ]]; then
  if ! defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null \
       | grep -q 'LSHandlerContentTag = ghostty'; then
    defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add \
      '{LSHandlerContentTag = "ghostty"; LSHandlerContentTagClass = "public.filename-extension"; LSHandlerRoleAll = "com.microsoft.vscode";}'
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
      -r -domain local -domain system -domain user >/dev/null
    killall lsd 2>/dev/null || true
    echo "✓ VS Code registered as default app for .ghostty files"
  fi
fi


echo ""
echo "✅ Done. Next steps:"
echo "   1. If this machine has its own credentials/env vars: create ~/.zshenv.local"
echo "   2. If this machine has its own aliases/functions: create ~/.zshrc.local"
echo "   3. Open a new shell: exec zsh"
