# ═══════════════════════════════════════════════════════════════
#  zsh/path.zsh — the PATH, and nothing else.
#  Sourced by .zshenv (every zsh) and, in a login shell, again by
#  .zprofile after /etc/zprofile has reordered it (the why is there).
#  Not symlinked: both find it next to their own symlink's target.
# ═══════════════════════════════════════════════════════════════

# Cross-platform: every entry but ~/.local/bin is added only if the dir exists.
# Final order (first = highest priority):
#   $HOME/.local/bin → pyenv (shims, bin) → Homebrew (mac or linux)
#   → $HOME/.cargo/bin → rest of the PATH
# ~/.zshenv.local runs after this and can prepend to win priority — except in
# a login shell, where /etc/zprofile pushes those entries behind the system
# dirs and only ~/.zprofile.local comes after it.
#
# -U keeps the FIRST occurrence of each entry, so prepending a dir that is
# already on PATH moves it to the front instead of listing it twice. That is
# what makes sourcing this a second time safe, and what stops a nested zsh —
# which inherits PATH and runs .zshenv again — from stacking another copy of
# every entry. (N-/) drops a dir that does not exist; the `-` follows symlinks,
# like `[[ -d ]]`.
typeset -gU path

# pyenv — the shims dir is what makes `python`/`pip` resolve to the pyenv
# version, and it is only a directory of executables: putting it on PATH costs
# no fork, unlike `pyenv init`. Here rather than behind the lazy `pyenv()` in
# .zshrc, which only fires when `pyenv` itself is typed and leaves `python` on
# the system interpreter until then; and here rather than in .zshrc so scripts
# and Claude Code's shell get the same interpreter as the prompt.
# Ahead of Homebrew, whose python3 arrives as a dependency of other formulae.
# PYENV_ROOT comes from .zshenv; the fallback keeps an unset one from turning
# into /shims and /bin.
path=(
  $HOME/.local/bin
  ${PYENV_ROOT:-$HOME/.pyenv}/{shims,bin}(N-/)
  /opt/homebrew/{bin,sbin}(N-/)
  # Linuxbrew: rare, but supported for completeness.
  /home/linuxbrew/.linuxbrew/{bin,sbin}(N-/)
  # Cargo: Rust tools on Linux/WSL (zoxide, delta, etc.).
  $HOME/.cargo/bin(N-/)
  $path
)
