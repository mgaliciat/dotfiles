# ═══════════════════════════════════════════════════════════════
#  ~/.zshrc — only loaded in interactive shells.
#  Philosophy: startup <50ms. No Oh My Zsh. Only the essentials.
#
#  Order:
#    1. history + options + completions + keybinds   (input/output)
#    2. tool inits                                   (pyenv, zoxide, fzf)
#    3. aliases
#    4. plugins                                      (syntax-highlight LAST)
#    5. prompt
#    6. local overrides                              (~/.zshrc.local)
# ═══════════════════════════════════════════════════════════════

# ─── history ──────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY           # history shared across sessions
setopt HIST_IGNORE_ALL_DUPS    # aggressive dedupe
setopt HIST_IGNORE_SPACE       # commands starting with a space aren't saved
setopt HIST_VERIFY             # confirm before running !! and friends
setopt EXTENDED_HISTORY        # saves timestamp

# ─── useful options ───────────────────────────────────────────
setopt AUTO_CD                 # `cd foo` optional, `foo/` is enough
setopt AUTO_PUSHD              # cd pushes onto the stack
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS    # allows # comments at the prompt

# ─── completions ──────────────────────────────────────────────
# Homebrew's completions (_brew, _bat, _eza, _fd, _delta, _gh, _rg…) live in
# its own site-functions, which neither macOS's /bin/zsh nor a distro zsh has in
# its default fpath. Without these dirs every brew-installed tool gets plain
# file completion. (/usr/local/share/zsh/site-functions is already there.)
#
# Appended, not prepended the way `brew shellenv` does it: the one name both
# sides ship is `_git`, and brew's is git's contrib wrapper around the bash
# completion, which would shadow zsh's own native `_git`. Appending adds the
# ~20 completions zsh lacks and changes none it already had.
#
# Being in fpath puts these dirs under compinit's compaudit. On a multi-user
# brew (group-writable, or owned by another account) compinit will ask about
# "insecure directories"; `compaudit | xargs chmod go-w` is the fix.
() {
  local d
  for d in /opt/homebrew/share/zsh/site-functions \
           /home/linuxbrew/.linuxbrew/share/zsh/site-functions; do
    [[ -d $d ]] && (( ! ${fpath[(Ie)$d]} )) && fpath+=($d)
  done
}

# Load compinit with a 24h cache: the full check (compaudit + rescanning fpath)
# at most once a day, `compinit -C` against the existing dump otherwise.
#
# The glob runs as an argument to an anonymous function, where the bare
# `(N.mh+24)` qualifier works with default options. Inside `[[ ]]` it would need
# `(#q…)` AND `setopt extendedglob`; without the option it is a literal string,
# `-n` is always true and every shell pays for the full compinit.
#
# `compinit -C` never looks at fpath, it trusts the dump — so a dir added to
# fpath above would stay invisible for up to a day. A dump older than this file
# (which is what adds those dirs) therefore takes the full branch too, which
# rescans and rewrites it. One stat, no glob.
#
# The `touch` is what keeps the cache a cache: a full compinit only rewrites the
# dump when the set of completion functions changed, so without it the dump
# stays older than 24h and every later shell takes the slow branch again.
autoload -Uz compinit
() {
  local dump=${ZDOTDIR:-$HOME}/.zcompdump
  if (( $# )) || [[ $dump -ot ${${(%):-%x}:A} ]]; then
    compinit
    touch $dump
  else
    compinit -C   # skip security check (faster)
  fi
} ${ZDOTDIR:-$HOME}/.zcompdump(N.mh+24)

# Native zsh menu: first Tab completes the common prefix, second Tab
# opens the navigable menu. (fzf-tab used to live here — it was removed
# because the interactive fzf list wasn't liked; the classic menu feels
# more terminal-native.)
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case-insensitive

# ─── key bindings (emacs style, zsh default) ──────────────────
bindkey -e

# ⌥←/⌥→ — move by "word". I take '/' out of the default WORDCHARS so that
# in a path (/dev/user/foo/bar) it stops at every slash instead of eating
# the whole path as a single word. ⌘←/⌘→ still go to start/end of the
# line (macOS convention, left untouched).
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
bindkey '^[[1;3D' backward-word    # ⌥← (escape that Ghostty emits with macos-option-as-alt)
bindkey '^[[1;3C' forward-word     # ⌥→

# Alt+e — opens the command you're typing in $EDITOR (nvim). For a long,
# tangled one-liner: you edit it with vim's full modal editing, save+quit
# and it runs. Requires macos-option-as-alt in Ghostty (already on) so
# that left ⌥ emits ^[.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^[e' edit-command-line

# Smart Ctrl+Z — with an empty prompt it does `fg` (back to the suspended
# job); with half-written text it pushes it onto the stack so you can get
# it back later. Turns Ctrl+Z into a one-finger toggle between shell and
# nvim/lazygit: you suspend with ^Z, and ^Z again brings you back.
fancy-ctrl-z() {
  if [[ $#BUFFER -eq 0 ]]; then
    BUFFER=' fg'
    zle accept-line
  else
    zle push-input
  fi
  zle clear-screen
}
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

# ─── tool inits ───────────────────────────────────────────────
# pyenv lazy-load — `pyenv init -` runs on the first `pyenv` command.
# Saves ~40ms at startup vs an eager `eval "$(pyenv init -)"`. `python` and
# `pip` do not wait for it: the shims are already on PATH from .zshenv. What
# the init adds is the shell integration (`pyenv shell`, auto-rehash).
pyenv() {
  unfunction pyenv
  eval "$(command pyenv init -)"
  pyenv "$@"
}

# zoxide → smart cd. Learns visited dirs, jumps with 'cd project'.
# command -v guard: if zoxide isn't installed (e.g. WSL2 without a full
# install) we avoid a "command not found" on every shell start.
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"

# fzf → fuzzy finder. Enables Ctrl+R (history), Ctrl+T (files), Alt+C (cd).
# command -v guard (same pattern as zoxide above): without fzf installed
# we avoid the error on every shell start, without masking it with 2>/dev/null.
command -v fzf >/dev/null && source <(fzf --zsh)

# ─── helper functions ─────────────────────────────────────────
# mkcd, port, server, gco, dex, dlogs, etc. (see zsh/functions.zsh).
# %x (prompt expansion) gives the real path of the file being sourced,
# following the symlink ~/.zshrc → dotfiles/zsh/.zshrc. Tested with -r rather
# than silenced with 2>/dev/null, which would also swallow the file's own errors.
# A plain variable, not an anonymous function: sourcing from inside a function
# would turn any typeset in functions.zsh that lacks -g into a local.
_zshrc_functions="${${(%):-%x}:A:h}/functions.zsh"
[[ -r $_zshrc_functions ]] && source "$_zshrc_functions"
unset _zshrc_functions

# ─── aliases ──────────────────────────────────────────────────
# Modern CLI tools (replacements for the macOS defaults). command -v guard on
# each: install-linux.sh lets eza fail, and on a box without it a bare `ls`
# alias to a missing binary breaks the most-typed command there is.
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lah --git --group-directories-first'
  alias lt='eza --tree --level=2 --git-ignore'
fi
if command -v bat >/dev/null; then
  alias cat='bat --paging=never --style=plain'   # real `cat` available as \cat
  alias catp='bat'                                # bat with paging + full header
fi
# command -v guard: on apt the binary is `fdfind` (install-linux.sh
# symlinks fdfind → fd in ~/.local/bin); if neither exists, the classic
# `find` is better than a broken alias.
command -v fd >/dev/null && alias find='fd'
# ripgrep is already invoked as 'rg' — no alias needed

# safe delete: gomi sends to a trash with interactive restore
# (`gomi` with no args lists what was deleted and lets you recover with
# fzf). The real `rm` is deliberately left intact — scripts and a
# deliberate `rm -rf` shouldn't go through the trash. command -v guard:
# gomi comes from brew (mac); on Linux nobody installs it — without the
# guard, `gm` would be an alias to a nonexistent command.
command -v gomi >/dev/null && alias gm='gomi'

# keep awake: bare `caffeinate` only blocks system sleep and still lets the
# display turn off — `-d` is the display. command -v guard: macOS only.
command -v caffeinate >/dev/null && alias caffeinate='caffeinate -di'

# git (the sub-aliases live in .gitconfig)
alias g='git'
alias gs='git st'
alias gd='git d'
alias gl='git lg'

# navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ─── plugins (cross-platform discovery, no Oh My Zsh) ─────────
# Strict order required by the plugins:
#   1. autosuggestions       (grey from history, → accepts)
#   2. syntax-highlighting   (green/red depending on whether the command is valid)
#   3. history-substring-search   (↑/↓ by substring — bound right below it)
# If you invert order 2↔3, the history-substring matches end up
# unhighlighted. Documented in the plugin's docs.
#
# Discovery: we probe paths in order — macOS brew → linuxbrew →
# apt (/usr/share, Ubuntu/Debian) → manual clone in ~/.zsh/plugins.
# This allows the same .zshrc on mac and Linux/WSL2 without touching anything.
#
# Naming: we probe `$name.zsh` (zsh-autosuggestions style) and then
# `$name.plugin.zsh` (fzf-tab style). Both conventions exist.
_load_zsh_plugin() {
  local name="$1" dir file
  for dir in \
    "/opt/homebrew/share" \
    "/home/linuxbrew/.linuxbrew/share" \
    "/usr/share" \
    "$HOME/.zsh/plugins"
  do
    for file in "$dir/$name/$name.zsh" "$dir/$name/$name.plugin.zsh"; do
      [[ -f "$file" ]] && { source "$file"; return 0; }
    done
  done
  return 1
}
_load_zsh_plugin zsh-autosuggestions
_load_zsh_plugin zsh-syntax-highlighting
# Bound only when the plugin loaded: without it the widgets don't exist and
# ↑/↓ would do nothing at all instead of zsh's plain history walk.
if _load_zsh_plugin zsh-history-substring-search; then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

# ─── highlight: valid commands in the theme's green ───────────
# `fg=green` is the plugin's own default, restated here on purpose. Until
# 2026-09-18 this was a literal `#87a96b`, the olive of the Anthropic Warm
# palette, picked to tone down a laser ANSI green that no theme in the family
# has any more — and over a light canvas (typesafe's sage) that olive sat at
# 1.3:1, so every command you typed was nearly invisible. ANSI 2 is whatever
# the active stack theme tuned it to be, which is the only value that stays
# readable across the family. MUST come after loading the plugin, otherwise
# the ZSH_HIGHLIGHT_STYLES array doesn't exist — which is also why it is
# guarded: on a box without the plugin, assigning `[command]` to an array
# nobody declared fails with "invalid subscript range" on every shell start.
if (( ${+ZSH_HIGHLIGHT_STYLES} )); then
  ZSH_HIGHLIGHT_STYLES[command]='fg=green'
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=green'
  ZSH_HIGHLIGHT_STYLES[alias]='fg=green'
  ZSH_HIGHLIGHT_STYLES[function]='fg=green'
fi

# ─── prompt ───────────────────────────────────────────────────
# Two lines: where you are on the first (path, branch, background jobs, a
# failed exit code), and nothing but `❯` on the second.
# The command always starts at column 3 with the whole width to itself —
# the reason Starship was removed (aug-2026) — without the prompt having
# to be plain to get there. Once a line is accepted the prompt collapses
# to `❯ cmd` (see the transient section), so the scrollback keeps one line
# per command, not two.
#
# `%n@%m` is dropped: on your own machine it's a constant that eats a
# third of the line. It comes back only over SSH, where "which box am I
# on" is the one thing a prompt has to answer — $SSH_CONNECTION is set
# by sshd, so the test costs nothing and can't false-positive locally.
#
# Colours are ANSI *indices*, never hex: each theme in the stack (see
# CLAUDE.md, "The stack theme") redefines those slots, so the prompt
# follows `theme = <id>` on its own instead of becoming a 4th place that
# has to be edited by hand.
#
# Only slots 1-7 are used, NOT 8-15. The bright half is unusable here:
# solarized-osaka mirrors its ANSI flat (brights == normals, deliberate,
# see CLAUDE.md) so 8 is not a dim grey, it is `#001014` against a
# `#001419` background — the "dim" text it painted was invisible. 7 is
# the theme's own foreground, which every theme has to keep readable by
# definition, so it is the safe choice for the secondary bits.
setopt PROMPT_SUBST      # PROMPT re-expands $_prompt_line1 every draw

# Needed here and again by the title/cwd hooks below; autoload is
# idempotent, but it has to happen before the FIRST add-zsh-hook call.
autoload -Uz add-zsh-hook

# The branch, without git(1). vcs_info is the answer everyone gives and
# it is the wrong one here: measured in this repo it costs 26ms per
# prompt (60ms with check-for-changes), and even `git symbolic-ref` is
# 9ms — a subprocess per keystroke-to-prompt against a <50ms budget for
# the whole shell. Reading .git/HEAD in pure zsh is 0.03ms, ~800x less,
# because HEAD is a one-line text file and always has been.
#
# The two `.git`-is-a-file cases are worktrees and submodules, which is
# not a corner case here (agents run in worktrees): there `.git` holds
# `gitdir: <path>`, absolute for a worktree, relative for a submodule.
# Detached HEAD holds the sha instead of a `ref:` line — show it short.
# No dirty marker on purpose: that needs the index, i.e. the 26ms.
#
# It assigns to a global rather than printing it: a $(…) around this
# would fork a subshell and cost 0.4ms — more than everything the
# function itself does.
_prompt_git() {
  local dir=$PWD gitdir head
  _prompt_git_str=
  while [[ $dir != / ]]; do
    if [[ -d $dir/.git ]]; then
      gitdir=$dir/.git
      break
    elif [[ -f $dir/.git ]]; then
      read -r gitdir < $dir/.git
      gitdir=${gitdir#gitdir: }
      [[ $gitdir == /* ]] || gitdir=$dir/$gitdir
      break
    fi
    dir=${dir:h}
  done
  [[ -n $gitdir && -r $gitdir/HEAD ]] || return
  read -r head < $gitdir/HEAD
  if [[ $head == ref:* ]]; then
    _prompt_git_str=${${head#ref: }#refs/heads/}
  else
    _prompt_git_str=${head[1,7]}
  fi
}
add-zsh-hook precmd _prompt_git

# ─── dirty marker, asynchronous ───────────────────────────────
# THE ONE PLACE the no-subprocess-per-prompt rule above is relaxed, and it is
# only survivable because it is off the critical path. A dirty flag needs the
# git index — that is the 26ms `_prompt_git` exists to avoid, and no amount of
# cleverness reads it in pure zsh. So the cost is paid where it cannot be felt:
# the prompt draws immediately without the marker, `git status` runs in the
# background, and the marker appears on its own when the answer arrives.
#
# The mechanism is zsh's own: `exec {fd}< <(…)` opens a process substitution on
# a numbered fd, `zle -F` asks ZLE to call a handler when that fd is readable,
# and the handler redraws with `zle reset-prompt`. No framework, no polling, no
# temp files. Registering the watcher from precmd (before ZLE is reading) is
# the supported order — ZLE installs it and fires once the line editor is live.
#
# `head -n 1` is what keeps this cheap on a large tree: git gets SIGPIPE after
# the first changed path, so it stops walking instead of enumerating everything.
# We only ever needed "is there at least one".
#
# The PWD guard is the correctness half: `cd` while a check is in flight would
# otherwise paint the old directory's answer next to the new directory's branch.
typeset -g _prompt_dirty_str=
typeset -g _prompt_dirty_pwd=

_prompt_dirty_done() {
  local fd=$1 line
  IFS= read -r line <&$fd
  zle -F $fd
  exec {fd}<&-
  [[ $_prompt_dirty_pwd == $PWD ]] || return
  _prompt_dirty_str=${line:+•}
  _prompt_render
  zle && zle reset-prompt
}

_prompt_dirty() {
  # The last answer stands while the next one is computed, as long as the
  # directory is the same. The branch changes colour with it, and clearing
  # it on every prompt would flash a dirty repo green for as long as each
  # `git status` takes.
  [[ $_prompt_dirty_pwd == $PWD ]] || _prompt_dirty_str=
  _prompt_dirty_pwd=$PWD
  # No repo, no question to ask — `_prompt_git` already told us, for free.
  [[ -n $_prompt_git_str ]] || return
  local fd
  exec {fd}< <(command git status --porcelain --ignore-submodules=dirty 2>/dev/null | head -n 1)
  zle -F $fd _prompt_dirty_done
}
add-zsh-hook precmd _prompt_dirty

# ─── first line ───────────────────────────────────────────────
# Plain coloured text, one space apart. Rounded powerline pills were tried
# here (oct-2026) and dropped for this.
#
# The branch glyph (U+E0A0) is spelled as UTF-8 bytes: Private Use
# codepoints get dropped by editors and tools, the same trap
# claude/statusline.sh documents.
_prompt_branch_glyph=$'\xee\x82\xa0'

_prompt_seg() { _prompt_line1+="${_prompt_line1:+ }%F{$1}$2%f" }

# Built in precmd, and again when the dirty check answers, into a variable
# PROMPT only references — never baked into PROMPT itself, for two reasons:
#   1. A branch name can contain `$(…)`, which PROMPT_SUBST would run if it
#      were part of the PROMPT text. A parameter's value is not expanded a
#      second time; only its `%` escapes are, hence the `%%` below.
#   2. Ghostty's shell integration wraps PROMPT in OSC 133 marks at its own
#      precmd, and they last only while PROMPT stays the string it marked.
#      An async redraw that reassigned PROMPT would drop the marks
#      jump-to-prompt relies on; one that changes a variable keeps them.
#
# `%(5~|…|…)` = ternary on "does the path have 5+ components": short
# paths print whole, long ones keep the first and the last three. Plain
# %1~ was losing the only part that identifies the project — in
# ~/dev/api/src/routes it printed `routes` and nothing else.
#
# Jobs and the exit code are prompt ternaries rather than tests here,
# because only draw time knows them: `%(1j.….)` is absent at zero jobs,
# `%(?..…)` absent on success. A failure also turns `❯` red.
#
# The branch is 2 when clean, 3 when dirty, and keeps its `•` on top of
# the colour change: solarized's green and yellow (#849900, #b28500) are
# too close to carry it alone.
typeset -g _prompt_line1=

_prompt_render() {
  _prompt_line1=
  [[ -n $SSH_CONNECTION ]] && _prompt_seg 7 '%n@%m'
  _prompt_seg 4 '%(5~|%-1~/…/%3~|%~)'
  if [[ -n $_prompt_git_str ]]; then
    local branch="$_prompt_branch_glyph ${_prompt_git_str//\%/%%}"
    if [[ -n $_prompt_dirty_str ]]; then
      _prompt_seg 3 "$branch $_prompt_dirty_str"
    else
      _prompt_seg 2 "$branch"
    fi
  fi
  _prompt_line1+="%(1j. %F{6}✳%j%f.)"
  _prompt_line1+="%(?.. %F{1}✘ %?%f)"
}
add-zsh-hook precmd _prompt_render

_prompt_ps1='${_prompt_line1}'$'\n''%(?.%F{5}.%F{1})❯%f '
PROMPT=$_prompt_ps1

# ─── transient prompt ─────────────────────────────────────────
# The moment a line is accepted, line-finish swaps PROMPT for the bare
# `❯` and redraws it in place over both lines; the next precmd puts the
# full one back, before Ghostty's precmd marks it. Hooked through
# add-zle-hook-widget rather than by defining zle-line-finish, so the
# other hooks on that widget (Ghostty's integration adds one) survive.
_prompt_collapse() {
  PROMPT='%(?.%F{5}.%F{1})❯%f '
  zle reset-prompt
}
autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-finish _prompt_collapse

_prompt_expand() { PROMPT=$_prompt_ps1 }
add-zsh-hook precmd _prompt_expand

# ─── window title + cwd reporting ─────────────────────────────
# Two things on every prompt, both via precmd:
#
# 1. Title (OSC 2): without this Ghostty's title stays stuck on the
#    login cwd. %~ = path with ~ abbreviated.
#
# 2. cwd (OSC 7): tells Ghostty which dir you're in so that Cmd+T
#    inherits the directory.
#
# add-zsh-hook is already autoloaded by the prompt section above.
#
# Ghostty's own shell integration already does both (cwd always, the title
# with the `title` feature, which config.ghostty enables) and runs its precmd
# last, so there these hooks would be duplicates whose output gets overwritten.
# They stay for every other terminal, and for a shell Ghostty did not inject
# into — a nested `zsh`, tmux, `exec zsh` (refresh) — which is why the test is
# "is the integration loaded in THIS shell", not $GHOSTTY_RESOURCES_DIR: that
# is inherited by all of those, the integration is not. At this point its
# precmd is still `_ghostty_deferred_init`; `_ghostty_precmd` covers a re-source.
# Both are Ghostty-internal names: if they ever change, this degrades to the
# harmless duplicates, never to no title/cwd at all.
_zshrc_in_ghostty() { (( $+functions[_ghostty_deferred_init] || $+functions[_ghostty_precmd] )) }

_set_title() { print -Pn "\e]2;%~\a" }
_zshrc_in_ghostty && [[ $GHOSTTY_SHELL_FEATURES == *title* ]] \
  || add-zsh-hook precmd _set_title

# OSC 7 carries a file:// URL, so the path is percent-encoded: a raw space, `#`
# or `%` in $PWD makes the URL mean a different path (or none). LC_ALL=C makes
# zsh see bytes, so a non-ASCII name is encoded byte by byte as UTF-8.
_report_cwd() {
  emulate -L zsh -o extended_glob
  local LC_ALL=C
  printf '\e]7;file://%s%s\e\\' "$HOST" \
    "${PWD//(#m)[^A-Za-z0-9\/._~-]/%${(l:2::0:)$(( [##16] #MATCH ))}}"
}
_zshrc_in_ghostty || add-zsh-hook precmd _report_cwd
unfunction _zshrc_in_ghostty

# ─── local overrides (not versioned) ──────────────────────────
# ~/.zshrc.local for per-machine aliases / functions / overrides.
# For env vars and secrets use ~/.zshenv.local (also loaded in scripts).
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
