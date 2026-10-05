# ═══════════════════════════════════════════════════════════════
#  ~/.zshenv — loaded on EVERY zsh invocation (interactive or not).
#  For PATH and env vars that also have to be available in scripts
#  and subprocesses (Docker, Claude Code, etc.).
#  UI/aliases/prompt go in .zshrc.
# ═══════════════════════════════════════════════════════════════

# ─── PATH ─────────────────────────────────────────────────────
# In its own file because .zprofile has to apply it again after /etc/zprofile.
# %x (prompt expansion) is the file being sourced; :A resolves the ~/.zshenv
# symlink into the repo, where path.zsh sits beside it — the same lookup
# .zshrc uses for functions.zsh. Not silenced: a shell without its PATH
# should say so.
#
# PYENV_ROOT is set here, not in path.zsh, so the .zprofile pass reads whatever
# ~/.zshenv.local left in it instead of resetting it.
export PYENV_ROOT="$HOME/.pyenv"
source "${${(%):-%x}:A:h}/path.zsh"

# ─── system rc files ──────────────────────────────────────────
# Ubuntu/Debian's /etc/zsh/zshrc runs its own full, uncached `compinit` in
# every interactive shell unless this is set — before ~/.zshrc, whose 24h-cached
# compinit then pays a second time. Only .zshenv is read early enough to set
# it. A no-op on macOS, whose /etc/zshrc never calls compinit.
skip_global_compinit=1

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
# no-blocks rule; the red pointer still points.
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

# Claude Code — fullscreen renderer (alternate screen). The name reads like a
# cosmetic tweak and isn't: "no flicker" is the fullscreen renderer's selling
# point, and =1 FORCES the alternate screen (code.claude.com/docs/en/fullscreen).
# Its opposite is CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1, which forces classic
# ahead of everything else — this one included — so the two never go together.
export CLAUDE_CODE_NO_FLICKER=1

# Claude Code — CFC is Claude For Chrome: the browser-extension integration,
# not "context-free composition" (what this comment used to claim). Verified
# against the 2.1.278 binary, where CFC_TOOL_PREFIX sits beside
# CLAUDE_IN_CHROME_MCP_SERVER_NAME and openInChrome; UNDOCUMENTED — it appears
# on no docs page, so re-check it against the binary and not against the docs.
#
# The parser is triBool, NOT bool: `1|true|yes|on` forces on, `0|false|no|off`
# forces off, and anything else (including unset) is undefined and falls back to
# the server-side default `claudeInChromeDefaultEnabled`. So `false` is a real
# off switch — it wins over that default — and a plausible value like "disabled"
# would read as undefined and hand the decision back to the server.
export CLAUDE_CODE_ENABLE_CFC=false

# Claude Code — the task list (TaskCreate/TaskGet/TaskUpdate/TaskList). Since
# v2.1.233 it is gated by model: only Claude 3.x, Opus ≤4.7, Sonnet ≤4.6 and
# Haiku 4.5 get it by default, so on Opus 5.5 and Sonnet 5.5 plans never show a
# checklist, and nothing in /doctor or the tool list says why
# (code.claude.com/docs/en/tools-reference#task-tool-availability). This puts
# it back on every model. Verified on 2.1.284 with `claude -p --verbose`: the
# init message lists the four tools with it and none without.
#
# Read at launch, so a running session keeps what it had. Only what a zsh starts
# sees it: the desktop app opened from the Dock does not.
export CLAUDE_CODE_ENABLE_TODO_TOOLS=1

# ─── local overrides (not versioned) ──────────────────────────
# ~/.zshenv.local for per-machine secrets/tokens/env vars.
# Loaded at the end so it can prepend to PATH and override defaults.
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
