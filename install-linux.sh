#!/usr/bin/env bash
# Symlinks portable dotfiles + auto-installs packages for Ubuntu/Debian.
# Primary target: WSL2 Ubuntu (no Linux GUI — Windows Terminal is outside).
# For macOS use ./install.sh.
#
# Idempotent: backs up existing files before symlinking.
# Strategy: apt for what is available, official curl installers and GitHub
# release binaries for what it lacks (no cargo — see the note further down).

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d_%H%M%S)"

# link(), link_portable(), install_claude() and the bootstraps, shared with
# install.sh.
source "$DOTFILES/scripts/lib.sh"

# ─── symlinks (portable subset of install.sh) ─────────────────
# The whole portable set — the same list install.sh links, kept once in
# lib.sh. What is skipped here is only what install.sh adds on top: ghostty
# and its themes (macOS-only GUI).
link_portable

# ─── stack theme ──────────────────────────────────────────────
# Nothing to do here. Same reason as in install.sh: palettes AND the active
# selection travel versioned and arrive through the dir symlinks above
# (here only nvim; no ghostty on Linux/WSL2).

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
    imagemagick                   # snacks.image converts anything but PNG with `magick`
    ripgrep
    fd-find                       # the binary is 'fdfind' — apt names it that way because of a clash with another 'fd'
    bat                           # on Ubuntu 20.04 it was 'batcat'; 22.04+ it is 'bat'
    fzf
    jq                            # required by claude/install/settings.sh
    gh                            # GitHub CLI — universe on Ubuntu 23.10+/Debian 13; older releases fail here and bootstrap_gh_stack skips itself
    eza                           # apt 23.10+; on older versions it fails → GH release fallback below
    zsh-syntax-highlighting
    zsh-autosuggestions
    python3
    python3-pip
  )
  # NOTE: 'neovim' is NOT in this list on purpose — apt has v0.6.x, and your
  # plugins (lazy.nvim, blink.cmp, rustaceanvim) need 0.10+.
  # We install it via GH release tarball below.

  # dpkg-query's Status, not `dpkg -s`: the latter also succeeds for a package
  # that was `apt remove`d but not purged (config files left behind), which
  # would then never be reinstalled.
  MISSING_APT=()
  for pkg in "${APT_PACKAGES[@]}"; do
    pkg_status=$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null || true)
    [[ "$pkg_status" == "install ok installed" ]] || MISSING_APT+=("$pkg")
  done

  if [[ ${#MISSING_APT[@]} -gt 0 ]]; then
    echo ""
    echo "→ apt packages to install: ${MISSING_APT[*]}"
    echo "  (requires sudo)"
    # Soft, like every other step: with stale lists most names still resolve.
    # With NO lists (fresh container) nothing does, and the candidate filter
    # below reports every package as skipped — the update failure is the cause.
    sudo apt-get update \
      || echo "⚠️  apt-get update failed — candidates below come from the existing (possibly empty) package lists."

    # `apt-get install a b c` is one transaction: a single name without an
    # install candidate (eza/gh on Ubuntu 22.04) aborts it and NOTHING lands.
    # So only names apt can actually resolve go in. LC_ALL=C because the
    # `Candidate:` label is translated; an unknown name prints nothing at all
    # and a known-but-uninstallable one prints `Candidate: (none)`. The output
    # is captured rather than piped into `grep -q`: grep exiting on the first
    # match can SIGPIPE apt-cache, and under pipefail that reads as "missing".
    INSTALLABLE_APT=()
    UNAVAILABLE_APT=()
    for pkg in "${MISSING_APT[@]}"; do
      pkg_policy=$(LC_ALL=C apt-cache policy "$pkg" 2>/dev/null || true)
      if grep -q '^ *Candidate: [^(]' <<<"$pkg_policy"; then
        INSTALLABLE_APT+=("$pkg")
      else
        UNAVAILABLE_APT+=("$pkg")
      fi
    done
    if [[ ${#UNAVAILABLE_APT[@]} -gt 0 ]]; then
      echo "⚠️  No apt candidate for: ${UNAVAILABLE_APT[*]} — skipped."
      echo "   eza has a GH release fallback below and gh is optional (bootstrap_gh_stack skips"
      echo "   itself); anything else stays missing — jq in particular, which settings.sh needs."
    fi
    if [[ ${#INSTALLABLE_APT[@]} -gt 0 ]]; then
      sudo apt-get install -y "${INSTALLABLE_APT[@]}" \
        || echo "⚠️  apt-get install failed — see the apt output above; nothing from this batch may have landed."
    fi
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

# bat: same clash, same shim. On Ubuntu 20.04 the apt package installs `batcat`
# (the name `bat` was taken by bacula-console-qt). This is NOT cosmetic parity
# with mac: `alias cat='bat …'` in .zshrc is UNGUARDED (unlike the MANPAGER
# export in .zshenv, which does check), so on a box that only has `batcat`
# every `cat` in the shell is a broken alias.
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  echo "✓ symlink bat → batcat in ~/.local/bin"
fi

# ─── Claude Code ──────────────────────────────────────────────
# Same three scripts as on mac, sourced in a load-bearing order by
# install_claude (scripts/lib.sh) — the Claude Code logic does not diverge
# between platforms. It goes AFTER the apt block: settings.sh needs jq.
install_claude

bootstrap_gh_stack

# ─── zsh-history-substring-search (not in apt) ────────────────
# The manual plugin goes to ~/.zsh/plugins/, which the .zshrc discovery probes
# as the last fallback after brew/linuxbrew/apt.
HSS_DIR="$HOME/.zsh/plugins/zsh-history-substring-search"
if [[ ! -d "$HSS_DIR" ]]; then
  echo "→ Cloning zsh-history-substring-search"
  git clone --depth 1 https://github.com/zsh-users/zsh-history-substring-search "$HSS_DIR" \
    || echo "⚠️  zsh-history-substring-search clone failed — the .zshrc will skip it"
fi

# ─── zoxide (official curl installer) ──────────────────────────
# Does NOT require cargo — it downloads the precompiled binary to ~/.local/bin.
# Critical because the .zshrc invokes it (eval zoxide init).

if ! command -v zoxide >/dev/null 2>&1; then
  echo ""
  echo "→ Installing zoxide (official curl installer)"
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash \
    || echo "⚠️  zoxide install failed — the .zshrc will skip smart cd"
fi

# ─── no cargo block (deliberately removed) ─────────────────────
# There used to be a `cargo install` step here for git-delta and tree-sitter-cli,
# the two mac formulae apt has no equivalent for. It is gone: both now come from
# a GitHub release below, which needs no Rust toolchain. That closed a real parity
# gap — tree-sitter was silently skipped on any box without rustup, so
# nvim-treesitter's `main` branch (which shells out to it to build parsers) was
# broken on Linux while it worked on mac. Don't reintroduce it: a ~400MB toolchain
# to compile two binaries that ship prebuilt is the definition of a worse install.
# The cargo PATH block in .zshenv stays — that is for tools you install by hand.

# ─── GitHub release binaries (what apt lacks or has outdated) ───────
# Small helpers: arch detection, fetching the latest tag from the GH API, and
# the download-unpack-install shape every release binary below shares.
_arch_x86_arm() {
  case "$(uname -m)" in
    x86_64)        echo "$1" ;;
    aarch64|arm64) echo "$2" ;;
    *)             echo "" ;;
  esac
}
# `|| true`: the unauthenticated API allows 60 requests/h per IP, and grep
# exits 1 on no match. Under `set -euo pipefail` either one, inside a
# `X=$(_gh_latest_tag …)`, would kill the installer on the spot — so an empty
# tag must come back as an empty string the caller can warn about.
_gh_latest_tag() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | grep -Po '"tag_name":\s*"v?\K[^"]+' | head -1 || true
}

# _gh_install_bin <bin> <repo> <x86_64 arch> <arm64 arch> <asset path>
# The asset path is relative to https://github.com/<repo>/releases/ and may
# carry @VER@ (latest tag, leading `v` stripped) and @ARCH@. Only @VER@ costs
# an API call, so assets with a versionless name use latest/download/ instead.
# The suffix picks the unpack step: .deb goes through dpkg, the rest must yield
# a file named <bin> that lands in ~/.local/bin.
# Everything is downloaded into $GH_TMP — a private mktemp dir, never a fixed
# /tmp name: `sudo dpkg -i /tmp/x.deb` on a shared host installs whatever
# another local user planted at that path first.
_gh_install_bin() {
  local bin="$1" repo="$2" asset="$5" arch ver="" dir file
  arch=$(_arch_x86_arm "$3" "$4")
  if [[ -n "$arch" && "$asset" == *@VER@* ]]; then
    ver=$(_gh_latest_tag "$repo")
  fi
  if [[ -z "$arch" || ( "$asset" == *@VER@* && -z "$ver" ) ]]; then
    echo "⚠️  Could not resolve $bin version/arch (ver=$ver arch=$arch)"
    return 0
  fi
  asset=${asset//@VER@/$ver}
  asset=${asset//@ARCH@/$arch}
  dir="$GH_TMP/$bin"
  file="$dir/${asset##*/}"
  mkdir -p "$dir"
  {
    curl -fsSL "https://github.com/$repo/releases/$asset" -o "$file" &&
      case "$file" in
        *.deb)    sudo dpkg -i "$file" ;;
        *.tar.gz) tar -xzf "$file" -C "$dir" && install "$dir/$bin" "$HOME/.local/bin/" ;;
        *.zip)    unzip -q -j -o "$file" "*/$bin" -d "$dir" && install "$dir/$bin" "$HOME/.local/bin/" ;;
        *.gz)     gunzip -c "$file" >"$dir/$bin" && install "$dir/$bin" "$HOME/.local/bin/" ;;
        *)        false ;;
      esac
  } || {
    if [[ "$file" == *.deb ]]; then
      echo "⚠️  $bin install failed (try: sudo apt --fix-broken install)"
    else
      echo "⚠️  $bin install failed"
    fi
  }
}

mkdir -p "$HOME/.local/bin"
GH_TMP=$(mktemp -d)
trap 'rm -rf "$GH_TMP"' EXIT

# lazygit — not in apt by default. GH release tarball.
if ! command -v lazygit >/dev/null 2>&1; then
  echo ""
  echo "→ Installing lazygit (GH release)"
  _gh_install_bin lazygit jesseduffield/lazygit x86_64 arm64 \
    'download/v@VER@/lazygit_@VER@_Linux_@ARCH@.tar.gz'
fi

# nvim — apt has 0.6.x, your plugins need 0.10+. Release tarball
# (not AppImage: the tarball does not require FUSE, more robust on WSL2).
# Not through _gh_install_bin: it is a whole tree under ~/.local/share with a
# symlink into ~/.local/bin, not a single binary.
NVIM_NEEDS_INSTALL=true
if command -v nvim >/dev/null 2>&1; then
  # `|| true`: an unparseable --version (grep matching nothing) must fall
  # through to a reinstall, not abort under pipefail. An empty NVIM_VER reads
  # as 0.0 in the arithmetic below.
  NVIM_VER=$(nvim --version | head -1 | grep -oP 'v\K[0-9]+\.[0-9]+' | head -1 || true)
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
    # Unpacked in $GH_TMP and only then swapped in: a truncated download or a
    # full disk must not delete a working older install before the new one is
    # known to be whole.
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/${NVIM_TARBALL}" -o "$GH_TMP/nvim.tar.gz" \
      && mkdir -p "$GH_TMP/nvim-linux" "$HOME/.local/share" \
      && tar -xzf "$GH_TMP/nvim.tar.gz" -C "$GH_TMP/nvim-linux" --strip-components=1 \
      && rm -rf "$HOME/.local/share/nvim-linux" \
      && mv "$GH_TMP/nvim-linux" "$HOME/.local/share/nvim-linux" \
      && ln -sf "$HOME/.local/share/nvim-linux/bin/nvim" "$HOME/.local/bin/nvim" \
      || echo "⚠️  nvim install failed"
  else
    echo "⚠️  Could not resolve nvim arch ($(uname -m))"
  fi
fi

# delta (git-delta) — GH release .deb. Easier than a tarball and it handles
# dependencies/uninstall via apt. dpkg with sudo. Its tags carry no `v`.
if ! command -v delta >/dev/null 2>&1; then
  echo ""
  echo "→ Installing delta (GH release .deb)"
  _gh_install_bin delta dandavison/delta amd64 arm64 \
    'download/@VER@/git-delta_@VER@_@ARCH@.deb'
fi

# eza — fallback if `command -v eza` fails after apt (apt did not ship it —
# typical on Ubuntu < 23.10 — or the install failed for some other reason).
if ! command -v eza >/dev/null 2>&1; then
  echo ""
  echo "→ Installing eza (GH release fallback, apt did not have it)"
  _gh_install_bin eza eza-community/eza x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu \
    'download/v@VER@/eza_@ARCH@.tar.gz'
fi

# gomi — `rm` with a trash + interactive restore, behind the `gm` alias. A brew
# formula on mac with no apt equivalent, so without this Linux silently loses the
# alias: .zshrc guards it with `command -v gomi`, which is exactly why the gap was
# invisible. goreleaser tarball with the binary at the root, same as lazygit.
if ! command -v gomi >/dev/null 2>&1; then
  echo ""
  echo "→ Installing gomi (GH release)"
  _gh_install_bin gomi babarot/gomi x86_64 arm64 \
    'download/v@VER@/gomi_Linux_@ARCH@.tar.gz'
fi

# ghq — clone manager for the $GHQ_ROOT tree (.zshenv). A brew formula on mac
# with no apt equivalent; upstream documents brew/scoop/nixpkgs/Void/Guix and
# `go install`, but nothing for Debian/Ubuntu, so the release binary it is
# (no Go toolchain required — same reasoning as the cargo tombstone above).
# WITHOUT IT THE Ctrl+F WIDGET LOSES ITS REPO LIST: functions.zsh guards the
# call with `command -v ghq`, which is precisely the kind of silent degradation
# that left the old hardcoded find contributing nothing for months.
# The asset is a ZIP (not a tarball like lazygit/gomi) and nests everything
# under ghq_linux_<arch>/, hence `unzip -j` (in _gh_install_bin) to flatten the
# one file out.
if ! command -v ghq >/dev/null 2>&1; then
  echo ""
  echo "→ Installing ghq (GH release)"
  _gh_install_bin ghq x-motemen/ghq amd64 arm64 \
    'download/v@VER@/ghq_linux_@ARCH@.zip'
fi

# tree-sitter-cli — nvim-treesitter's `main` branch shells out to it to generate
# parsers, so nvim is degraded without it. This replaces the old `cargo install`
# (see the tombstone above). The asset is a gzipped BARE BINARY, not a tarball:
# `gunzip`, not `tar`. Its name carries no version, so the stable
# latest/download/ URL works and no API call for the tag is needed here.
if ! command -v tree-sitter >/dev/null 2>&1; then
  echo ""
  echo "→ Installing tree-sitter-cli (GH release)"
  _gh_install_bin tree-sitter tree-sitter/tree-sitter x64 arm64 \
    'latest/download/tree-sitter-linux-@ARCH@.gz'
fi

# ─── pyenv (official curl installer) ───────────────────────────
# apt does not have pyenv. The official installer sets up ~/.pyenv and leaves it
# ready for the .zshrc lazy-loader. `-f` matters on a curl piped into a shell:
# without it an HTTP error page is handed to bash as a script.
if [[ ! -d "$HOME/.pyenv" ]]; then
  echo ""
  echo "→ Installing pyenv (official curl installer)"
  curl -fsSL https://pyenv.run | bash || echo "⚠️  pyenv install failed"
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
  echo "       curl -fsSLo /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip"
  echo "       mkdir -p ~/.local/bin"
  echo "       unzip -p /tmp/win32yank.zip win32yank.exe > ~/.local/bin/win32yank.exe"
  echo "       chmod +x ~/.local/bin/win32yank.exe"
fi

echo ""
echo "✅ Done. Next steps:"
echo "   1. Per-machine credentials/env vars: create ~/.zshenv.local"
echo "   2. Per-machine aliases/functions: create ~/.zshrc.local"
echo "   3. Open a new shell: exec zsh"
echo "   4. If some tool is still missing: check the output above — the ⚠️"
echo "      mark failed installs. They are usually network problems or an"
echo "      unsupported arch (only x86_64 + arm64 are implemented)."
