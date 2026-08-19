# ═══════════════════════════════════════════════════════════════
#  ~/.zshrc — only loaded in interactive shells.
#  Philosophy: startup <50ms. No Oh My Zsh. Only the essentials.
#
#  Order:
#    0. auto-tmux                                    (exec → cuts the rest in the parent)
#    1. history + options + completions + keybinds   (input/output)
#    2. tool inits                                   (pyenv, zoxide, fzf)
#    3. aliases
#    4. plugins                                      (syntax-highlight LAST)
#    5. prompt
#    6. local overrides                              (~/.zshrc.local)
# ═══════════════════════════════════════════════════════════════

# ─── auto-tmux ────────────────────────────────────────────────
# Every Ghostty window/tab starts inside tmux. We use `exec` so that
# tmux REPLACES this zsh — when you leave with `exit` (or close the
# last window), the process dies and Ghostty closes the window.
# Without `exec` you'd be back in a bare zsh.
#
# Guards:
#   $TMUX empty        → prevents recursion. The child panes that tmux
#                        spawns have $TMUX set and follow the normal
#                        .zshrc flow.
#   $- contains 'i'    → interactive shells only. Not scripts.
#   $TERM_PROGRAM     → VS Code's integrated terminal keeps a bare
#                        shell (its jump-to-error / cwd tracking breaks
#                        with tmux in the middle).
#   $NO_AUTO_TMUX     → manual escape hatch: NO_AUTO_TMUX=1 ghostty
#                        opens a shell without tmux for one-off cases.
#
# `tmux new-session` (without -s) creates a new ephemeral session per
# window — Cmd+T does NOT clone content between tabs. Named sessions
# (claude-*, claude-yolo-*) live independently in the same server and
# persist across Ghostty windows/restarts.
if [[ -z "$TMUX" && $- == *i* && -z "$NO_AUTO_TMUX" \
      && "$TERM_PROGRAM" != "vscode" ]] \
   && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session
fi

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
# Load compinit with a 24h cache (avoids constant recompilation).
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C   # skip security check (faster)
fi

# Native zsh menu: first Tab completes the common prefix, second Tab
# opens the navigable menu. (fzf-tab used to live here — it was removed
# because the interactive fzf list wasn't liked; the classic menu feels
# more terminal-native.)
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case-insensitive

# ─── key bindings (emacs style, zsh default) ──────────────────
bindkey -e
bindkey '^[[A' history-substring-search-up    # ↑ by substring (requires zsh-history-substring-search)
bindkey '^[[B' history-substring-search-down  # ↓ by substring

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
# pyenv lazy-load — initializes on the first use of pyenv/python/pip.
# Saves ~40ms at startup vs an eager `eval "$(pyenv init -)"`.
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
# following the symlink ~/.zshrc → dotfiles/zsh/.zshrc.
source "${${(%):-%x}:A:h}/functions.zsh" 2>/dev/null

# ─── aliases ──────────────────────────────────────────────────
# Modern CLI tools (replacements for the macOS defaults)
alias ls='eza --group-directories-first'
alias ll='eza -lah --git --group-directories-first'
alias lt='eza --tree --level=2 --git-ignore'
alias cat='bat --paging=never --style=plain'     # real `cat` available as \cat
alias catp='bat'                                  # bat with paging + full header
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
#   3. history-substring-search   (↑/↓ by substring — enables the bindkeys above)
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
}
_load_zsh_plugin zsh-autosuggestions
_load_zsh_plugin zsh-syntax-highlighting
_load_zsh_plugin zsh-history-substring-search

# ─── highlight: valid commands in olive green ─────────────────
# The plugin's default is `fg=green`, which lands on the theme's ANSI
# green (#50fa7b laser). We tone it down to the olive of the Anthropic
# Warm palette — it still reads as "valid" without the neon. It MUST come
# after loading the plugin, otherwise the ZSH_HIGHLIGHT_STYLES array
# doesn't exist.
ZSH_HIGHLIGHT_STYLES[command]='fg=#87a96b'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#87a96b'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#87a96b'
ZSH_HIGHLIGHT_STYLES[function]='fg=#87a96b'

# ─── prompt ───────────────────────────────────────────────────
# The system default (macOS /etc/zshrc uses `%n@%m %1~ %#`), with `$` as the
# sigil instead of `%`. Starship was removed (aug-2026): the terminal's width
# belongs to the command, and git state is one `git status` away.
PROMPT='%n@%m %1~ $ '

# ─── window title + cwd reporting ─────────────────────────────
# Two things on every prompt, both via precmd:
#
# 1. Title (OSC 2): without this Ghostty's title stays stuck on the
#    login cwd (tmux uses set-titles-string "#T" = pane title, and
#    nobody updates it). %~ = path with ~ abbreviated.
#
# 2. cwd (OSC 7): tells Ghostty which dir you're in so that Cmd+T
#    inherits the directory. INSIDE tmux the plain OSC 7 is captured by
#    tmux and never reaches Ghostty → it has to be wrapped in tmux's DCS
#    passthrough (\ePtmux;…\e\\ with every ESC doubled; requires
#    `allow-passthrough on` in tmux.conf). Outside tmux it's emitted as-is.
autoload -Uz add-zsh-hook

_set_title() { print -Pn "\e]2;%~\a" }
add-zsh-hook precmd _set_title

_report_cwd() {
  if [[ -n "$TMUX" ]]; then
    printf '\ePtmux;\e\e]7;file://%s%s\e\e\\\e\\' "$HOST" "$PWD"
  else
    printf '\e]7;file://%s%s\e\\' "$HOST" "$PWD"
  fi
}
add-zsh-hook precmd _report_cwd

# ─── local overrides (not versioned) ──────────────────────────
# ~/.zshrc.local for per-machine aliases / functions / overrides.
# For env vars and secrets use ~/.zshenv.local (also loaded in scripts).
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
