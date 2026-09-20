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
# bat — uses the terminal's 16 ANSI colors instead of its own theme, so it
# follows whatever stack theme is active.
export BAT_THEME="ansi"

# fzf — same idea. Its default scheme on a 256-color terminal is `dark`:
# fixed 256-color values (current line = #e4e4e4 on #303030, matches in a
# dark-tuned green) that ignore the theme and read as a dark slab over a
# light canvas. `16` maps every role onto the ANSI slots the theme tunes.
# `bg+:-1` drops the current-line block entirely (base16 would paint it in
# ANSI 8, the comment gray) and `fg+` bold marks the line instead — the same
# no-blocks rule the tmux statusline follows; the red pointer still points.
export FZF_DEFAULT_OPTS="--color=16,bg+:-1,fg+:-1:bold"

# man pages through bat — syntax-highlighted, line numbers off. `col -bx`
# strips the backspace-overstrike bold/underline that groff emits (bat would
# render it as literal ^H garbage otherwise). command -v guard: on a box
# without bat (e.g. WSL2 without a full install) we leave man's default pager.
command -v bat >/dev/null && export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# ghq — clones live in a tree derived from the remote URL
# ($GHQ_ROOT/github.com/<owner>/<repo>), so the path says where a checkout came
# from instead of relying on whatever the folder was named by hand.
#
# THIS ENV VAR, NOT `git config ghq.root`, IS THE VERSIONED ROUTE. ghq reads
# both, and GHQ_ROOT wins: when it is non-empty it becomes the ONLY root and the
# git config is not consulted at all (local_repository.go, `Roots()`). That
# matters here because ~/.gitconfig is deliberately not symlinked — it is 100%
# per-machine — so a `ghq.root` there would have to be re-set by hand on every
# box. One line in .zshenv travels with the clone and covers mac and Linux
# alike.
#
# ~/Developer and not the ~/ghq default: that is where the checkouts already
# were, and a second top-level repo dir is exactly the sprawl ghq is here to
# end. Repos that predate this (flat `~/Developer/<name>`) were moved in with
# `ghq migrate`, which reads each remote and derives the path — so a local
# folder whose name had drifted from its repo (`diagramb` → `diagramas`) now
# matches the remote.
export GHQ_ROOT="$HOME/Developer"

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
