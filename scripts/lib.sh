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

  # tmux-claude-session-manager is pinned here (not left to `prefix + I`) so
  # every machine runs the exact same picker/launcher. tpm would otherwise
  # clone whatever HEAD was on the day of the first `prefix + I`, drifting per
  # host — the symptom being an old Alt+U window on a mac installed later. We
  # own the clone (full, not --depth 1, so an arbitrary SHA is checkoutable);
  # tpm then sees the dir exists and leaves it alone. Convergent: re-running the
  # installer fetches + checks out the pin, realigning a stale clone.
  local csm_dir="$HOME/.config/tmux/plugins/tmux-claude-session-manager"
  local csm_pin="45d593f7e17d34fd5bad5330f825d430e817938e"
  if [[ ! -d "$csm_dir/.git" ]]; then
    echo "→ Cloning tmux-claude-session-manager into $csm_dir"
    git clone https://github.com/craftzdog/tmux-claude-session-manager "$csm_dir"
  fi
  if [[ -d "$csm_dir/.git" ]] && \
     [[ "$(git -C "$csm_dir" rev-parse HEAD 2>/dev/null)" != "$csm_pin" ]]; then
    git -C "$csm_dir" fetch --quiet origin && \
      git -C "$csm_dir" checkout --quiet "$csm_pin" && \
      echo "✓ tmux-claude-session-manager pinned to ${csm_pin:0:7}"
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
