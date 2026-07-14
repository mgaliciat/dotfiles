#!/usr/bin/env bash
# Symlinks portable dotfiles + auto-installs packages for Ubuntu/Debian.
# Primary target: WSL2 Ubuntu (no Linux GUI — Windows Terminal is outside).
# For macOS use ./install.sh.
#
# Idempotent: backs up existing files before symlinking.
# Strategy: apt for what is available + cargo install for what is missing.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d_%H%M%S)"

# link() and bootstrap_tmux(), shared with install.sh.
source "$DOTFILES/scripts/lib.sh"

# ─── symlinks (portable subset of install.sh) ─────────────────
# Skipped: ghostty and its themes (macOS-only GUI). The rest of the repo is
# the portable subset and is linked exactly like on mac.
link "$DOTFILES/zsh/.zshrc"             "$HOME/.zshrc"
link "$DOTFILES/zsh/.zshenv"            "$HOME/.zshenv"
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/git/.gitignore_global"  "$HOME/.gitignore_global"
link "$DOTFILES/nvim"                   "$HOME/.config/nvim"
link "$DOTFILES/tmux"                   "$HOME/.config/tmux"
link "$DOTFILES/lazygit/config.yml"     "$HOME/.config/lazygit/config.yml"

# ─── stack theme ──────────────────────────────────────────────
# Nothing to do here. Same reason as in install.sh: palettes AND the active
# selection travel versioned and arrive through the dir symlinks above
# (here only nvim + tmux; no ghostty on Linux/WSL2).

# ~/.gitconfig is NOT symlinked — per-machine, same as on mac.

# Claude Code per-machine (same pattern as install.sh).
# settings.json is NOT symlinked (100% per-machine, like ~/.gitconfig).
# skills/ is not either (since jul-2026): its content is per-machine and was
# never versioned, so the symlink to the repo was pure indirection — and it
# leaked personal state into the public repo if the .gitignore was loosened.
# ~/.claude/skills is a real dir; the codebase-memory-mcp binary creates it if
# missing.
# memory/ is not either: Claude Code handles it per-project, deriving the real
# path of the directory, so a guessed symlink was ignored.

# ─── apt packages ──────────────────────────────────────────────
# What apt has out-of-the-box on Ubuntu 24.04 / Debian 12.
# Modern lazygit and nvim are NOT there — those go via GitHub releases / AppImage.
# It goes BEFORE the settings.json blocks below: those use jq (installed here) —
# if they ran first, on a fresh machine they would silently skip and only apply
# on the second run.
if command -v apt-get >/dev/null 2>&1; then
  APT_PACKAGES=(
    zsh
    git
    curl
    unzip
    build-essential
    tmux
    ripgrep
    fd-find                       # the binary is 'fdfind' — apt names it that way because of a clash with another 'fd'
    bat                           # on Ubuntu 20.04 it was 'batcat'; 22.04+ it is 'bat'
    fzf
    jq                            # required by tmux-claude-session-manager (parses `claude agents --json`)
    eza                           # apt 23.10+; on older versions it fails → GH release fallback below
    zsh-syntax-highlighting
    zsh-autosuggestions
    python3
    python3-pip
  )
  # NOTE: 'neovim' is NOT in this list on purpose — apt has v0.6.x, and your
  # plugins (lazy.nvim, blink.cmp, rustaceanvim) need 0.10+.
  # We install it via GH release tarball below.

  MISSING_APT=()
  for pkg in "${APT_PACKAGES[@]}"; do
    dpkg -s "$pkg" >/dev/null 2>&1 || MISSING_APT+=("$pkg")
  done

  if [[ ${#MISSING_APT[@]} -gt 0 ]]; then
    echo ""
    echo "→ apt packages to install: ${MISSING_APT[*]}"
    echo "  (requires sudo)"
    sudo apt-get update
    # `|| true`: some packages may not exist on older Ubuntu (e.g. eza
    # pre-23.10). We continue so cargo can cover them afterwards.
    sudo apt-get install -y "${MISSING_APT[@]}" || \
      echo "⚠️  Some packages failed — cargo install will cover what is missing."
  fi
else
  echo "⚠️  apt-get not detected — skipping package installation."
fi

# fd: the apt package is fd-find and its binary is called `fdfind`. The .zshrc
# (shared with mac) expects `fd` — symlink it in ~/.local/bin (already in PATH
# via .zshenv) so fd/the find alias work the same on both.
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  echo "✓ symlink fd → fdfind in ~/.local/bin"
fi

# ─── Claude Code ──────────────────────────────────────────────
# Same scripts as install.sh (mac) — the Claude Code logic does not diverge
# between platforms, so it lives once in claude/install/. Three mechanisms split
# by WHO writes to settings.json: us with jq (settings.sh), the external binary
# (binaries.sh), the plugin CLI (plugins.sh). Detail in claude/install/README.md.
#
# `rtk` here does not come from Homebrew: binaries.sh falls back on its own to
# the official curl installer when the binary is missing (the `command -v` guard
# covers both cases).
#
# The order is load-bearing: settings.sh symlinks ~/.claude/CLAUDE.md, and
# `rtk init` (binaries.sh) adds an @RTK.md line to it — we want that to land on
# the versioned file through the symlink, not on a loose one.
# They go AFTER the apt block: settings.sh needs jq.
source "$DOTFILES/claude/install/settings.sh"
source "$DOTFILES/claude/install/binaries.sh"
source "$DOTFILES/claude/install/plugins.sh"

bootstrap_tmux

# ─── zsh-history-substring-search (not in apt) ────────────────
# The manual plugin goes to ~/.zsh/plugins/, which the .zshrc discovery probes
# as the last fallback after brew/linuxbrew/apt.
HSS_DIR="$HOME/.zsh/plugins/zsh-history-substring-search"
if [[ ! -d "$HSS_DIR" ]]; then
  echo "→ Cloning zsh-history-substring-search"
  git clone --depth 1 https://github.com/zsh-users/zsh-history-substring-search "$HSS_DIR"
fi

# ─── starship + zoxide (official curl installers) ──────────────
# These do NOT require cargo — they download the precompiled binary to ~/.local/bin.
# Critical because the .zshrc invokes them (eval starship/zoxide init).

if ! command -v starship >/dev/null 2>&1; then
  echo ""
  echo "→ Installing starship (official curl installer)"
  # -y: install without prompt; -b ~/.local/bin: does not require sudo
  curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin" \
    || echo "⚠️  starship install failed — the .zshrc will skip the prompt"
fi

if ! command -v zoxide >/dev/null 2>&1; then
  echo ""
  echo "→ Installing zoxide (official curl installer)"
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash \
    || echo "⚠️  zoxide install failed — the .zshrc will skip smart cd"
fi

# ─── cargo packages (only what really needs the Rust toolchain) ───
# delta and tree-sitter have no convenient official curl installer.
# If cargo is missing we skip them with a clear message (they are not critical).
if command -v cargo >/dev/null 2>&1; then
  declare -A CARGO_PACKAGES=(
    [git-delta]=delta             # the "git-delta" crate installs the "delta" binary
    [tree-sitter-cli]=tree-sitter
  )

  for crate in "${!CARGO_PACKAGES[@]}"; do
    binary="${CARGO_PACKAGES[$crate]}"
    if ! command -v "$binary" >/dev/null 2>&1; then
      echo "→ cargo install $crate"
      cargo install --locked "$crate" || echo "⚠️  $crate failed"
    fi
  done
else
  echo ""
  echo "ℹ️  cargo (Rust toolchain) not detected — tree-sitter-cli skipped."
  echo "   (delta is installed via GH release below, it does not require cargo)."
  echo "   For tree-sitter: install rustup and re-run this script."
  echo "     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
fi

# ─── GitHub release binaries (what apt lacks or has outdated) ───────
# Small helpers: arch detection + fetching the latest tag from the GH API.
_arch_x86_arm() {
  case "$(uname -m)" in
    x86_64)        echo "$1" ;;
    aarch64|arm64) echo "$2" ;;
    *)             echo "" ;;
  esac
}
_gh_latest_tag() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | grep -Po '"tag_name":\s*"v?\K[^"]+' | head -1
}

mkdir -p "$HOME/.local/bin"

# lazygit — not in apt by default. GH release tarball.
if ! command -v lazygit >/dev/null 2>&1; then
  echo ""
  echo "→ Installing lazygit (GH release)"
  LG_VER=$(_gh_latest_tag jesseduffield/lazygit)
  LG_ARCH=$(_arch_x86_arm x86_64 arm64)
  if [[ -n "$LG_VER" && -n "$LG_ARCH" ]]; then
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_${LG_ARCH}.tar.gz" \
      | tar -xz -C /tmp lazygit && install /tmp/lazygit "$HOME/.local/bin/" && rm /tmp/lazygit \
      || echo "⚠️  lazygit install failed"
  else
    echo "⚠️  Could not resolve lazygit version/arch (LG_VER=$LG_VER LG_ARCH=$LG_ARCH)"
  fi
fi

# nvim — apt has 0.6.x, your plugins need 0.10+. Release tarball
# (not AppImage: the tarball does not require FUSE, more robust on WSL2).
NVIM_NEEDS_INSTALL=true
if command -v nvim >/dev/null 2>&1; then
  NVIM_VER=$(nvim --version | head -1 | grep -oP 'v\K[0-9]+\.[0-9]+' | head -1)
  NVIM_MAJOR=${NVIM_VER%.*}
  NVIM_MINOR=${NVIM_VER#*.}
  if (( NVIM_MAJOR > 0 )) || (( NVIM_MINOR >= 10 )); then
    NVIM_NEEDS_INSTALL=false
  fi
fi
if $NVIM_NEEDS_INSTALL; then
  echo ""
  echo "→ Installing nvim 0.10+ (GH release tarball)"
  NVIM_ARCH=$(_arch_x86_arm x86_64 arm64)
  if [[ -n "$NVIM_ARCH" ]]; then
    NVIM_TARBALL="nvim-linux-${NVIM_ARCH}.tar.gz"
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/${NVIM_TARBALL}" -o /tmp/nvim.tar.gz \
      && rm -rf "$HOME/.local/share/nvim-linux" \
      && mkdir -p "$HOME/.local/share/nvim-linux" \
      && tar -xzf /tmp/nvim.tar.gz -C "$HOME/.local/share/nvim-linux" --strip-components=1 \
      && ln -sf "$HOME/.local/share/nvim-linux/bin/nvim" "$HOME/.local/bin/nvim" \
      && rm /tmp/nvim.tar.gz \
      || echo "⚠️  nvim install failed"
  fi
fi

# delta (git-delta) — GH release .deb. Easier than a tarball and it handles
# dependencies/uninstall via apt. dpkg with sudo.
if ! command -v delta >/dev/null 2>&1; then
  echo ""
  echo "→ Installing delta (GH release .deb)"
  DELTA_VER=$(_gh_latest_tag dandavison/delta)
  DELTA_ARCH=$(_arch_x86_arm amd64 arm64)
  if [[ -n "$DELTA_VER" && -n "$DELTA_ARCH" ]]; then
    curl -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VER}/git-delta_${DELTA_VER}_${DELTA_ARCH}.deb" -o /tmp/delta.deb \
      && sudo dpkg -i /tmp/delta.deb \
      && rm /tmp/delta.deb \
      || echo "⚠️  delta install failed (try: sudo apt --fix-broken install)"
  fi
fi

# eza — fallback if `command -v eza` fails after apt (apt did not ship it —
# typical on Ubuntu < 23.10 — or the install failed for some other reason).
if ! command -v eza >/dev/null 2>&1; then
  echo ""
  echo "→ Installing eza (GH release fallback, apt did not have it)"
  EZA_VER=$(_gh_latest_tag eza-community/eza)
  EZA_ARCH=$(_arch_x86_arm x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu)
  if [[ -n "$EZA_VER" && -n "$EZA_ARCH" ]]; then
    curl -fsSL "https://github.com/eza-community/eza/releases/download/v${EZA_VER}/eza_${EZA_ARCH}.tar.gz" \
      | tar -xz -C /tmp ./eza && install /tmp/eza "$HOME/.local/bin/" && rm /tmp/eza \
      || echo "⚠️  eza install failed"
  fi
fi

# ─── pyenv (official curl installer) ───────────────────────────
# apt does not have pyenv. The official installer sets up ~/.pyenv and leaves it
# ready for the .zshrc lazy-loader.
if [[ ! -d "$HOME/.pyenv" ]]; then
  echo ""
  echo "→ Installing pyenv (official curl installer)"
  curl https://pyenv.run | bash || echo "⚠️  pyenv install failed"
fi

# ─── default shell to zsh ──────────────────────────────────────
if [[ "$(basename "${SHELL:-}")" != "zsh" ]] && command -v zsh >/dev/null 2>&1; then
  echo ""
  echo "→ Changing default shell to zsh"
  chsh -s "$(command -v zsh)" || \
    echo "⚠️  chsh failed — run 'chsh -s \$(which zsh)' by hand (it may ask for a password)."
fi

# ─── WSL2-specific helpers (heuristic detection) ──────────────
if [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSLENV:-}" ]] || \
   grep -qi microsoft /proc/version 2>/dev/null; then
  echo ""
  echo "ℹ️  WSL2 detected:"
  echo "   - Fonts: use the Windows Terminal ones (do not install fonts inside WSL)."
  echo "   - Ghostty: not applicable — its config is ignored."
  echo "   - nvim clipboard: install win32yank for Windows clipboard integration:"
  echo "       curl -sLo /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip"
  echo "       mkdir -p ~/.local/bin"
  echo "       unzip -p /tmp/win32yank.zip win32yank.exe > ~/.local/bin/win32yank.exe"
  echo "       chmod +x ~/.local/bin/win32yank.exe"
fi

echo ""
echo "✅ Done. Next steps:"
echo "   1. Per-machine credentials/env vars: create ~/.zshenv.local"
echo "   2. Per-machine aliases/functions: create ~/.zshrc.local"
echo "   3. Open a new shell: exec zsh"
echo "   4. Inside tmux the first time: prefix + I to install plugins"
echo "   5. If some tool is still missing: check the output above — the ⚠️"
echo "      mark failed installs. They are usually network problems or an"
echo "      unsupported arch (only x86_64 + arm64 are implemented)."
