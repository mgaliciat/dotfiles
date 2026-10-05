# ═══════════════════════════════════════════════════════════════
#  ~/.zprofile — login shells only, read after /etc/zprofile and
#  before .zshrc. Exists to put the PATH back in order.
# ═══════════════════════════════════════════════════════════════

# ─── PATH, again ──────────────────────────────────────────────
# macOS's /etc/zprofile runs `path_helper`, which rebuilds PATH as /etc/paths +
# /etc/paths.d FIRST and appends what .zshenv had built after them. So /usr/bin
# lands ahead of the pyenv shims and `python3` is /usr/bin/python3 again — the
# exact thing path.zsh orders PATH to prevent. Not an edge case: Ghostty and
# Terminal.app start every tab as a login shell. Applying path.zsh a second time
# moves its entries back to the front; `typeset -U` keeps it from duplicating
# them. Harmless where /etc/zprofile leaves PATH alone (Debian/Ubuntu).
source "${${(%):-%x}:A:h}/path.zsh"

# ─── local overrides (not versioned) ──────────────────────────
# ~/.zprofile.local for per-machine login-shell setup (e.g. OrbStack's init
# line). Last, so a PATH entry prepended here beats /usr/bin in a login shell;
# one prepended from ~/.zshenv.local sits behind the system dirs, where
# path_helper put it.
[[ -f ~/.zprofile.local ]] && source ~/.zprofile.local
