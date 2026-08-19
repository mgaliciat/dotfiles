# ═══════════════════════════════════════════════════════════════
#  ~/.zshenv — loaded on EVERY zsh invocation (interactive or not).
#  For PATH and env vars that also have to be available in scripts
#  and subprocesses (Docker, Claude Code, etc.).
#  UI/aliases/prompt go in .zshrc.
# ═══════════════════════════════════════════════════════════════

# ─── PATH ─────────────────────────────────────────────────────
# Cross-platform: each block is prepended only if the dir exists.
# Final order (first = highest priority):
#   $HOME/.local/bin → Homebrew (mac or linux) → $HOME/.cargo/bin → rest of the PATH
# ~/.zshenv.local can prepend afterwards and win priority.

# Cargo (Rust tools on Linux/WSL: zoxide, delta, etc.)
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"

# Linuxbrew (rare, but supported for completeness)
[[ -d "/home/linuxbrew/.linuxbrew/bin" ]] && \
  export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"

# Homebrew macOS Apple Silicon
[[ -d "/opt/homebrew/bin" ]] && \
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# ~/.local/bin always wins — preserves the original behavior.
export PATH="$HOME/.local/bin:$PATH"

# Pyenv root (PATH only; the lazy init lives in .zshrc so as not to penalize startup).
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# ─── CLI tool env vars ────────────────────────────────────────
# bat — uses the terminal's colors (Anthropic Warm) instead of its own theme.
export BAT_THEME="ansi"

# man pages through bat — syntax-highlighted, line numbers off. `col -bx`
# strips the backspace-overstrike bold/underline that groff emits (bat would
# render it as literal ^H garbage otherwise). command -v guard: on a box
# without bat (e.g. WSL2 without a full install) we leave man's default pager.
command -v bat >/dev/null && export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Default editor — nvim for everything that respects $EDITOR/$VISUAL:
# `edit-command-line` (Alt+e at the prompt), `crontab -e`, `less` (v key).
# git uses its own core.editor, so this does NOT override it.
export EDITOR="nvim"
export VISUAL="nvim"

# Claude Code — classic main-screen renderer instead of fullscreen (documented
# env var: code.claude.com/docs/en/env-vars). Avoids the banner "flash" when
# starting a session and keeps the conversation in the native scrollback.
export CLAUDE_CODE_NO_FLICKER=1

# Claude Code — disable CFC (context-free composition) mode.
export CLAUDE_CODE_ENABLE_CFC=false

# ─── local overrides (not versioned) ──────────────────────────
# ~/.zshenv.local for per-machine secrets/tokens/env vars.
# Loaded at the end so it can prepend to PATH and override defaults.
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
