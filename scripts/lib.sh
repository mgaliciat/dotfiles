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
