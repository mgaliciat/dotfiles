# shellcheck shell=bash
# Shared by install.sh (macOS) and install-linux.sh. Sourced, not executed:
# it expects $DOTFILES and $TS from the parent installer.

# Symlink $1 → $2, backing up whatever was there first. Idempotent: an existing
# symlink is replaced silently, a real file is moved aside with a timestamp so a
# fresh machine never loses a config it already had.
#
# A missing source is a soft failure checked BEFORE touching $dst: `ln -s`
# happily creates a dangling link, so a renamed repo path would otherwise
# replace a working config with a broken one and still print ✓.
link() {
  local src="$1" dst="$2"
  if [[ ! -e "$src" ]]; then
    echo "⚠️  missing $src — not linking $dst"
    return 0
  fi
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
# per installer. install.sh adds the mac-only Ghostty pieces on top;
# install-linux.sh adds nothing.
#
# ~/.local/bin entries are tools that must resolve by NAME, not by repo path,
# from non-interactive shells too (scripts, hooks): ~/.local/bin is first on
# PATH via zsh/.zshenv, which every zsh sources.
link_portable() {
  link "$DOTFILES/zsh/.zshrc"             "$HOME/.zshrc"
  link "$DOTFILES/zsh/.zshenv"            "$HOME/.zshenv"
  link "$DOTFILES/git/.gitignore_global"  "$HOME/.gitignore_global"
  link "$DOTFILES/nvim"                   "$HOME/.config/nvim"
  link "$DOTFILES/lazygit/config.yml"     "$HOME/.config/lazygit/config.yml"
  link "$DOTFILES/scripts/claude-api-env" "$HOME/.local/bin/claude-api-env"
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
# out on a re-run. `grep >/dev/null`, not `grep -q`: -q exits on the first
# match, `gh` can die of SIGPIPE, and under the installers' pipefail that reads
# as "not installed" and triggers the erroring re-install.
#
# Deliberately NOT convergent (no `gh extension upgrade`): bumping the version
# is the user's call.
#
# `gh` missing is a skip, not a failure: on Linux the apt package only exists on
# Ubuntu 23.10+/Debian 13, and the installer must not die on an older box.
bootstrap_gh_stack() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "→ gh-stack: skipped (no gh on PATH — install the GitHub CLI first)"
    return
  fi
  if gh extension list 2>/dev/null | grep 'github/gh-stack' >/dev/null; then
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
