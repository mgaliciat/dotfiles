#!/usr/bin/env bash
# Symlinks dotfiles into their expected locations.
# Idempotent: backs up existing files before linking.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d_%H%M%S)"

# link(), link_portable(), install_claude() and the bootstraps, shared with
# install-linux.sh.
source "$DOTFILES/scripts/lib.sh"

# zsh, git, nvim, lazygit, ~/.local/bin tools — the list is in lib.sh so
# both installers link the same set. Ghostty and tmux are mac-specific, below.
link_portable

# tmux exists here only to host tmux-claude-hatch (see tmux/tmux.conf). The
# whole dir, like nvim: the pinned plugin clone below lands in tmux/plugins/,
# which .gitignore keeps out of the repo.
link "$DOTFILES/tmux" "$HOME/.config/tmux"

# A stale orphaned `config` (no extension) wins over our symlink and loads its
# own inline content, ignoring the dotfiles theme. Defensive backup before
# linking config.ghostty.
GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
if [[ -f "$GHOSTTY_DIR/config" && ! -L "$GHOSTTY_DIR/config" ]]; then
  mv "$GHOSTTY_DIR/config" "$GHOSTTY_DIR/config.backup.$TS"
  echo "→ stale ghostty config moved to config.backup.$TS"
fi
link "$DOTFILES/ghostty/config.ghostty" "$GHOSTTY_DIR/config.ghostty"
# Shaders sit BESIDE the config, not in the XDG dir the themes use: a relative
# `custom-shader = shaders/<name>.glsl` resolves against the config file's own
# directory, and Application Support is where that file lives.
link "$DOTFILES/ghostty/shaders"        "$GHOSTTY_DIR/shaders"
# Custom themes (wallpaper sampling, own palettes). CAREFUL: Ghostty looks for
# themes in ~/.config/ghostty/themes/ (XDG path), NOT in the same Application
# Support dir where the config lives — they are different dirs. If you put them
# in Application Support, Ghostty ignores them and errors with "theme not found".
# Symlink the whole dir so new themes are exposed automatically.
# This also exposes the "stack theme" family: new themes in ghostty/themes and
# nvim/lua/themes ride along for free with the parent dir symlinks — no need
# to link them one by one.
if [[ -d "$DOTFILES/ghostty/themes" ]]; then
  mkdir -p "$HOME/.config/ghostty"
  link "$DOTFILES/ghostty/themes"       "$HOME/.config/ghostty/themes"
fi
# Per-machine keys (the font and its size), included by config.ghostty's
# `config-file`. Copied, never linked, so editing it never shows up as a diff
# here: seeded whole when missing, and a file from before the font moved there
# (font-size only) gets the seed appended once. With `font-family` already in
# it, it is left alone.
GHOSTTY_LOCAL="$HOME/.config/ghostty/config.local"
mkdir -p "$HOME/.config/ghostty"
if [[ ! -e "$GHOSTTY_LOCAL" ]]; then
  cp "$DOTFILES/ghostty/config.local.default" "$GHOSTTY_LOCAL"
  echo "✓ ghostty config.local seeded with Recursive — set font-size there"
elif ! grep -qE '^[[:space:]]*font-family[[:space:]]*=' "$GHOSTTY_LOCAL"; then
  { echo; cat "$DOTFILES/ghostty/config.local.default"; } >> "$GHOSTTY_LOCAL"
  echo "→ ghostty config.local had no font-family: appended the Recursive block"
fi

# ─── stack theme ──────────────────────────────────────────────
# Nothing to do here. The theme selection is a direct value in each versioned
# config (Ghostty `theme =`, nvim `vim.g.theme`) and arrives with the
# clone/pull; the dir symlinks above expose the palettes with no extra work.
# Changing the theme on ALL machines = `theme <id>` (scripts/theme rewrites
# those 2 lines) + commit + pull.

# Caps Lock → Option: System Settings → Keyboard → Keyboard Shortcuts →
# Modifier Keys → Caps Lock = Option ⌥. It is per-device and per-machine, not
# versionable; that is why it lives in the UI and not in the repo.
# Not Karabiner-Elements: its virtual HID only supports the generic ansi/iso
# layouts, which swaps <> with |° on the MacBook built-in keyboard + Latin
# American layout.

# ~/.gitconfig is NOT symlinked — each machine keeps its own 100%
# (credentials, 1Password vaults, signing keys are per-machine).

# Claude Code: all per-machine, not versioned. settings.json is NOT symlinked
# (it is 100% each host's own, like ~/.gitconfig): permissions/UI diverge per
# machine and symlinking it would drag personal state into a public repo.
#
# skills/ is not symlinked either. ~/.claude/skills is the REAL path where
# Claude Code reads the user's skills, and its content (the `learned` skill that
# Claude writes, `codebase-memory` that the binary rewrites on every install) is
# 100% per-machine. A symlink into the repo buys nothing, and a `git add -f` or
# a loosened .gitignore would leak personal state into a public repo. It is a
# real dir; the codebase-memory-mcp binary creates it if missing.
#
# memory/ is NOT symlinked, for a DIFFERENT reason: Claude Code derives the
# project-id from the REAL path of the directory (e.g. working in ~/dotfiles it
# uses ...projects/-Users-foo-dotfiles/memory), so a symlink there points at
# the wrong path and is ignored. Memory is per-project and Claude Code handles
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
    jq                    # required by claude/install/settings.sh
    gh                    # GitHub CLI — host for the gh-stack extension (bootstrap_gh_stack below)
    ghq                   # clone manager — $GHQ_ROOT tree, and the source the Ctrl+F widget lists
    git-delta
    pyenv
    neovim
    tree-sitter-cli       # parser generator used by nvim-treesitter's `main` branch
    # SQL formatter conform points at for `sql` (<leader>cf). Brew and not
    # mason-tool-installer like every other formatter: mason installs it into
    # a pip venv and refuses the system python3 (3.9.6 < the 3.10 it needs),
    # so the mason route leaves the formatter permanently uninstalled. The
    # brew bottle carries its own interpreter.
    sqlfluff
    imagemagick           # snacks.image converts anything but PNG with `magick`
    lazygit
    tmux                  # host for tmux-claude-hatch — see the block after install_claude
    rtk                   # token-reducing proxy CLI for Claude Code — see the rtk section below
    # Trigram-indexed grep (microsoft/tgrep). It is NOT an `rg` drop-in — the
    # README says so itself — so nothing here aliases or replaces ripgrep, and
    # `rg` stays what Claude Code's Grep tool and telescope shell out to.
    # What it buys is a persistent index + server (`tgrep index .`, then
    # `tgrep serve .`, index in `.tgrep/`), which only pays off on trees far
    # larger than anything in ~/Developer: measured here on the biggest one
    # (console, 594 indexed files) it is 6.9ms vs ripgrep's 12.6ms per search
    # — a 5.7ms difference, for an 8 MB index and a daemon per repo. Installed
    # for the checkouts where that ratio inverts (kernel/gecko-scale), not as
    # a replacement for the everyday search.
    tgrep
  )
  REQUIRED_CASKS=(
    ghostty
    1password-cli         # `op` — a cask on Homebrew, not a formula (lives in Caskroom)
    # Fonts referenced by ghostty/config.local.default, the seed of each
    # machine's config.local — that file is the source of truth for which one
    # is primary, not this comment.
    # The primary (font-family) is Recursive, the variable font
    # (`font-recursive`), pinned by `font-variation` in the config. NOT a
    # Nerd Font: its icons fall back into the NF casks below, which are
    # load-bearing while it is the primary. The other families are
    # alternatives, each one line away in the config (0xProto resolves as its
    # "Mono" family; see the typography block there). Paper Mono is NOT a
    # Nerd Font either: whenever it is the primary, the NF families here stop
    # being optional coverage and become load-bearing, since Ghostty pulls
    # every powerline/devicon glyph from them. iA Writer Mono rounds out the
    # fallback chain (Ghostty falls back to them + bundled JBM NF
    # automatically). Every font named in the config must be installed by
    # this list: a font-family pointing at a missing family falls back
    # silently.
    # Monaspace is the `-nf` (Nerd Font) build, not the plain cask, so it
    # ships its own icons instead of leaning on the JBM NF fallback.
    font-google-sans-code
    font-0xproto-nerd-font
    font-maple-mono-nf
    font-plemol-jp-nf
    font-monaspace-nf
    font-ia-writer-mono
    font-caskaydia-cove-nerd-font   # Cascadia Code NF
    font-intel-one-mono
    font-datatype
    font-lilex-nerd-font
    font-recursive
    # Ships the 8 static otf AND the variable ttf, so "Paper Mono" registers
    # twice and Ghostty's CoreText scoring does not prefer the variable face —
    # the `font-variation` weight in config.ghostty only holds when it wins.
    font-paper-mono
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
    brew install "${MISSING_FORMULAE[@]}" \
      || echo "⚠️  brew install failed for some formulae — re-run ./install.sh or install them by hand"
  fi

  if [[ ${#MISSING_CASKS[@]} -gt 0 ]]; then
    echo ""
    echo "→ Installing missing casks: ${MISSING_CASKS[*]}"
    brew install --cask "${MISSING_CASKS[@]}" \
      || echo "⚠️  brew install --cask failed for some casks — re-run ./install.sh or install them by hand"
  fi

  if [[ ${#MISSING_FORMULAE[@]} -eq 0 && ${#MISSING_CASKS[@]} -eq 0 ]]; then
    echo "✓ All Homebrew dependencies are already installed"
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

bootstrap_gh_stack

# ─── tmux-claude-hatch (our fork of craftzdog's) ──────────────
# Cloned and pinned here instead of through tpm, so every Mac runs the same
# bytes: tpm would clone whatever HEAD was on the day of the first `prefix + I`.
# A full clone, not --depth 1, so an arbitrary SHA is checkoutable. Convergent:
# a re-run fetches and checks out the pin, realigning a stale clone. Bumping it
# is editing hatch_pin. Needs tmux ≥ 3.2, fzf and jq (all in the brew list) and
# Claude Code ≥ 2.1.139.
#
# The fork is upstream (e0bcfd1, 28 sep) plus five things: the picker groups
# agents by repository (a worktree under its main checkout), ctrl-r there labels
# an agent, launch.sh takes a worktree name as its third argument (tmux.conf's
# Alt+Y), worktrees.sh lists a repository's worktrees to open Claude on one
# (Alt+U), and HATCH_VARIANT runs a second command in sessions of its own (the
# API key on Alt+a / Alt+A). A clone made from craftzdog's URL is re-pointed,
# not re-cloned.
hatch_dir="$HOME/.config/tmux/plugins/tmux-claude-hatch"
hatch_url="https://github.com/mgaliciat/tmux-claude-hatch"
hatch_pin="64062ef2ac843dd05ca4a04a60306d4942718167"
if [[ ! -d "$hatch_dir/.git" ]]; then
  echo "→ Cloning tmux-claude-hatch into $hatch_dir"
  git clone --quiet "$hatch_url" "$hatch_dir" || echo "⚠️  tmux-claude-hatch clone failed"
fi
if [[ -d "$hatch_dir/.git" && "$(git -C "$hatch_dir" remote get-url origin 2>/dev/null)" != "$hatch_url" ]]; then
  git -C "$hatch_dir" remote set-url origin "$hatch_url"
fi
if [[ -d "$hatch_dir/.git" && "$(git -C "$hatch_dir" rev-parse HEAD 2>/dev/null)" != "$hatch_pin" ]]; then
  if git -C "$hatch_dir" fetch --quiet origin && git -C "$hatch_dir" checkout --quiet "$hatch_pin"; then
    echo "✓ tmux-claude-hatch pinned to ${hatch_pin:0:7}"
  else
    echo "⚠️  could not check out tmux-claude-hatch ${hatch_pin:0:7}"
  fi
fi

# A running tmux server keeps the old config in memory; reload it. No server →
# nothing to do, the next one reads the file. Errors stay visible on purpose.
if command -v tmux >/dev/null 2>&1 && tmux info >/dev/null 2>&1; then
  tmux source-file "$HOME/.config/tmux/tmux.conf" && echo "✓ tmux config reloaded"
fi

# ─── Mouser ───────────────────────────────────────────────────
# Mouser (TomBadash/Mouser) — button remapping for Logitech mice without
# Logi Options+. It is NOT in REQUIRED_CASKS because there is no cask: neither
# homebrew/cask nor a tap ships it, only release zips. So it comes from the
# latest GitHub release, one zip per arch.
#
# Guarded on the .app existing, like gh-stack: deliberately NOT convergent —
# Mouser checks for its own updates, and bumping the version is the user's
# call. curl does not set com.apple.quarantine, so there is no Gatekeeper
# prompt; the Accessibility grant it needs is still a click in System Settings.
if [[ ! -d "/Applications/Mouser.app" ]]; then
  if [[ "$(uname -m)" == "arm64" ]]; then
    MOUSER_ZIP="Mouser-macOS.zip"
  else
    MOUSER_ZIP="Mouser-macOS-intel.zip"
  fi
  MOUSER_TMP="$(mktemp -d)"
  echo ""
  echo "→ Installing Mouser from github.com/TomBadash/Mouser ($MOUSER_ZIP)"
  if curl -fsSL -o "$MOUSER_TMP/$MOUSER_ZIP" \
       "https://github.com/TomBadash/Mouser/releases/latest/download/$MOUSER_ZIP" \
     && ditto -x -k "$MOUSER_TMP/$MOUSER_ZIP" "$MOUSER_TMP/x"; then
    # The .app may sit at the zip's root or one folder down.
    MOUSER_APP="$(find "$MOUSER_TMP/x" -maxdepth 2 -name 'Mouser.app' -type d -print -quit)"
    if [[ -n "$MOUSER_APP" ]]; then
      mv "$MOUSER_APP" /Applications/
      echo "✓ Mouser installed — grant it Accessibility in System Settings → Privacy & Security"
    else
      echo "⚠️  Mouser.app not found inside $MOUSER_ZIP — install it by hand"
    fi
  else
    echo "⚠️  Mouser download failed — re-run ./install.sh or install it by hand"
  fi
  rm -rf "$MOUSER_TMP"
fi
# Its config is a plain JSON file, and Mouser saves it atomically while keeping
# a symlinked config.json a symlink, so it is linked like any other config.
link "$DOTFILES/mouser/config.json" "$HOME/Library/Application Support/Mouser/config.json"

# macOS file associations — open config.ghostty in VS Code (not TextEdit).
# .ghostty has no registered UTI, so macOS falls back to TextEdit by default.
# Idempotent: checks whether the entry already exists before adding it.
# `grep >/dev/null`, not `grep -q`: -q exits on the first match, `defaults`
# then dies of SIGPIPE, and under pipefail the pipeline reports failure — a
# false "missing" that would append a duplicate LSHandlers entry.
if [[ -d "/Applications/Visual Studio Code.app" ]]; then
  if ! defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null \
       | grep 'LSHandlerContentTag = ghostty' >/dev/null; then
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
