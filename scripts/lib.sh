# shellcheck shell=bash
# Shared by install.sh (macOS) and install-linux.sh. Sourced, not executed:
# it expects $DOTFILES and $TS from the parent installer.

# Symlink $1 → $2, backing up whatever was there first. Idempotent: an existing
# symlink is replaced silently, a real file is moved aside with a timestamp so a
# fresh machine never loses a config it already had.
link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    echo "→ backing up existing $dst to $dst.backup.$TS"
    mv "$dst" "$dst.backup.$TS"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "✓ $dst → $src"
}

# The portable symlink set — everything that lands in the same place on mac
# and Linux. Lives here so that adding a file to the repo is ONE edit, not one
# per installer (the ide link was missing from both for two months because
# each list was maintained by hand). install.sh adds the mac-only Ghostty
# pieces on top; install-linux.sh adds nothing.
#
# ~/.local/bin entries are tools that must resolve by NAME, not by repo path:
# tmux runs its binds through `$SHELL -c` (non-interactive, no .zshrc, so no
# zsh functions), and `prefix + g` / the Alt+a popups call `ide` and
# `claude-api-env` from there. ~/.local/bin is first on PATH via zsh/.zshenv,
# which every zsh sources, non-interactive included.
link_portable() {
  link "$DOTFILES/zsh/.zshrc"             "$HOME/.zshrc"
  link "$DOTFILES/zsh/.zshenv"            "$HOME/.zshenv"
  link "$DOTFILES/git/.gitignore_global"  "$HOME/.gitignore_global"
  link "$DOTFILES/nvim"                   "$HOME/.config/nvim"
  link "$DOTFILES/tmux"                   "$HOME/.config/tmux"
  link "$DOTFILES/lazygit/config.yml"     "$HOME/.config/lazygit/config.yml"
  link "$DOTFILES/scripts/claude-api-env" "$HOME/.local/bin/claude-api-env"
  link "$DOTFILES/scripts/ide"            "$HOME/.local/bin/ide"
  link "$DOTFILES/scripts/theme"          "$HOME/.local/bin/theme"
}

# Claude Code: three mechanisms, one file each, split by WHO writes to
# settings.json — us with jq (settings.sh), the external binary in its own
# setup command (binaries.sh), the plugin CLI (plugins.sh). Same on every
# platform that can run bash, hence one call here instead of three `source`
# lines per installer. Detail in claude/install/README.md.
#
# The order is fixed by contract, not by a mechanism any more: `rtk init` used to
# append an @RTK.md line to the ~/.claude/CLAUDE.md that settings.sh symlinks, so
# settings.sh had to run first. `--hook-only` (binaries.sh) stopped that write.
#
# Call it AFTER the platform's package block: settings.sh needs jq, and on a
# fresh machine running first would silently skip every settings.json write
# until the second run. `rtk` also need not come from the package manager —
# binaries.sh falls back to the official curl installer when it is missing.
install_claude() {
  source "$DOTFILES/claude/install/settings.sh"
  source "$DOTFILES/claude/install/binaries.sh"
  source "$DOTFILES/claude/install/plugins.sh"
}

# gh-stack (github/gh-stack) — stacked branches/PRs as a `gh` extension.
# It is NOT a formula or an apt package: `gh extension install` is the only
# supported install, so it cannot ride along in the deps block like everything
# else. Hence a bootstrap here, shared by both installers.
#
# Guarded on the extension already being listed — `gh extension install` errors
# out on a re-run. Deliberately NOT convergent (no `gh extension upgrade`):
# bumping the version is the user's call, unlike the tmux plugin above, which is
# pinned precisely so every machine runs the same bytes.
#
# `gh` missing is a skip, not a failure: on Linux the apt package only exists on
# Ubuntu 23.10+/Debian 13, and the installer must not die on an older box.
bootstrap_gh_stack() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "→ gh-stack: skipped (no gh on PATH — install the GitHub CLI first)"
    return
  fi
  if gh extension list 2>/dev/null | grep -q 'github/gh-stack'; then
    echo "✓ gh-stack extension already installed"
    return
  fi
  echo "→ Installing gh extension github/gh-stack"
  if gh extension install github/gh-stack </dev/null; then
    echo "✓ gh-stack installed (gh stack --help)"
  else
    echo "⚠️  gh extension install github/gh-stack failed"
  fi
}

# tpm (Tmux Plugin Manager) + reload. tpm lives in the installer, not in
# tmux.conf: cloning it is a one-time bootstrap, not per-launch work. Plugins
# listed in tmux.conf are installed from inside tmux with `prefix + I` the first
# time (`prefix + U` updates them).
bootstrap_tmux() {
  local tpm_dir="$HOME/.config/tmux/plugins/tpm"
  if [[ ! -d "$tpm_dir" ]]; then
    echo "→ Cloning tpm into $tpm_dir"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
    echo "✓ tpm installed. Inside tmux: prefix + I to install plugins"
  fi

  # tmux-claude-hatch is pinned here (not left to `prefix + I`) so every
  # machine runs the exact same picker/launcher. tpm would otherwise clone
  # whatever HEAD was on the day of the first `prefix + I`, drifting per host —
  # the symptom being an old Alt+U window on a mac installed later. We own the
  # clone (full, not --depth 1, so an arbitrary SHA is checkoutable); tpm then
  # sees the dir exists and leaves it alone. Convergent: re-running the
  # installer fetches + checks out the pin, realigning a stale clone.
  #
  # Upstream renamed itself from tmux-claude-session-manager on 2026-09-15
  # (`0ba963e`). The dir name must match the `@plugin` line in tmux.conf, or
  # tpm clones a second copy under the new name beside ours — so a clone left
  # by the old installer is MOVED, not re-cloned, and its remote re-pointed.
  # GitHub redirects the old URL, so a clone that keeps it still works; the
  # re-point just stops depending on that. TEMPORARY: drop the move once every
  # machine has run this version.
  local csm_dir="$HOME/.config/tmux/plugins/tmux-claude-hatch"
  local csm_old_dir="$HOME/.config/tmux/plugins/tmux-claude-session-manager"
  local csm_url="https://github.com/craftzdog/tmux-claude-hatch"
  local csm_pin="8d02d64d0bf2ae6fd979a99ad9fefd3c1fe0cea2"
  if [[ ! -d "$csm_dir/.git" && -d "$csm_old_dir/.git" ]]; then
    mv "$csm_old_dir" "$csm_dir"
    echo "✓ moved the tmux-claude-session-manager clone to its new name"
  fi
  if [[ ! -d "$csm_dir/.git" ]]; then
    echo "→ Cloning tmux-claude-hatch into $csm_dir"
    git clone "$csm_url" "$csm_dir"
  fi
  if [[ -d "$csm_dir/.git" ]]; then
    if [[ "$(git -C "$csm_dir" remote get-url origin 2>/dev/null)" != "$csm_url" ]]; then
      git -C "$csm_dir" remote set-url origin "$csm_url"
    fi
    if [[ "$(git -C "$csm_dir" rev-parse HEAD 2>/dev/null)" != "$csm_pin" ]]; then
      git -C "$csm_dir" fetch --quiet origin && \
        git -C "$csm_dir" checkout --quiet "$csm_pin" && \
        echo "✓ tmux-claude-hatch pinned to ${csm_pin:0:7}"
    fi
  fi

  # If a tmux server is running, reload the config so active sessions pick up
  # the changes without having to attach and do it by hand. No server (typical
  # on a fresh WSL2 login) → skip; the next session reads the config anyway.
  # The `tmux info` guard also covers tmux not being installed yet (first run on
  # a new machine).
  if command -v tmux >/dev/null 2>&1 && tmux info >/dev/null 2>&1; then
    # No 2>/dev/null here on purpose: a syntax error in the config should be
    # visible, not swallowed (`tmux info` already guarantees a server exists).
    if tmux source-file "$HOME/.config/tmux/tmux.conf"; then
      echo "✓ tmux config reloaded in active sessions"
    fi
  fi
}
