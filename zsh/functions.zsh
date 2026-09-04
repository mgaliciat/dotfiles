# ═══════════════════════════════════════════════════════════════
#  ~/.zshrc → sourced helper functions
#
#  Philosophy: only functions useful day to day that don't have a
#  simpler alias. Don't bloat. Anything per-machine goes in ~/.zshrc.local.
# ═══════════════════════════════════════════════════════════════

# Where this repo is checked out, resolved from this file's own path at source
# time (.zshrc already sources us through the resolved symlink). Used instead
# of a hardcoded ~/dotfiles so a clone anywhere else still works.
typeset -g _DOTFILES_ROOT="${${(%):-%x}:A:h:h}"

# ─── navigation / shell ───────────────────────────────────────

# mkdir + cd in a single step.
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Which process is using a TCP port (LISTEN).
# Usage: port 3000
port() {
  lsof -nP -iTCP:"$1" -sTCP:LISTEN
}

# Public IP (via ipify).
myip() {
  curl -s https://api.ipify.org && echo
}

# Local (LAN) IP. On macOS it tries Wi-Fi (en0) and then Ethernet (en1);
# on Linux/WSL2 there's no `ipconfig` → fallback to `hostname -I`.
localip() {
  if command -v ipconfig >/dev/null; then
    ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1
  else
    hostname -I 2>/dev/null | awk '{print $1}'
  fi
}

# HTTP server in the current dir. Default port 8000.
# Usage: server  /  server 4000
server() {
  local p="${1:-8000}"
  echo "→ http://localhost:$p"
  python3 -m http.server "$p"
}

# ─── git with fzf ─────────────────────────────────────────────

# Pick a branch (local + remote) with fzf and check it out.
# Usage: gco
gco() {
  local branch
  # `git branch --all` indents with 2 spaces (and the current branch with `* `).
  # THAT has to be stripped at the source: `${branch## }` only removes one space
  # and left `git checkout " main"` → "pathspec did not match" when picking
  # any non-current branch.
  branch=$(git branch --all 2>/dev/null \
           | grep -v HEAD \
           | sed 's|remotes/origin/||' \
           | sed 's/^[ *]*//' \
           | sort -u \
           | fzf) || return
  [[ -n "$branch" ]] || return   # fzf cancelled → don't try to checkout
  git checkout "$branch"
}

# ─── docker ───────────────────────────────────────────────────

# Exec into a running container (fzf-pick). Tries bash → falls back to sh.
# Usage: dex
dex() {
  local cid
  cid=$(docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}' \
        | fzf | awk '{print $1}') || return
  docker exec -it "$cid" /bin/bash 2>/dev/null \
    || docker exec -it "$cid" /bin/sh
}

# Tail the logs of a container (running or exited).
# Usage: dlogs
dlogs() {
  local cid
  cid=$(docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Status}}' \
        | fzf | awk '{print $1}') || return
  docker logs -f --tail=100 "$cid"
}

# Stop all running containers.
# Usage: dstop-all
dstop-all() {
  docker ps -q | xargs -r docker stop
}

# Aggressive cleanup: stopped containers, dangling images, orphaned volumes
# and networks. Does NOT touch containers or images in use. Frees space fast.
# Usage: dprune-all
dprune-all() {
  docker system prune -af --volumes
}

# ─── fuzzy cd (craftzdog style) ───────────────────────────────
#
# Ctrl+F → fzf with a curated list of "interesting" directories:
# configs, dotfiles, repos in conventional locations and subdirs of
# the cwd. More opinionated than `zoxide` (which goes by frequency) —
# useful when you start from scratch and want to jump to "that project
# I know exists in some folder".
#
# Trade-off: Ctrl+F by default in emacs-mode is `forward-char` (cursor
# forward 1 char). If you need it, you can use the → arrow or rebind to
# another key (e.g. bindkey '^G' _fzf_cd_widget). Craftzdog accepts the
# trade-off, his fish mapping is identical.
#
# Each block in the `{ ... }` contributes a source; `awk '!a[$0]++'`
# dedupes while preserving order.
_fzf_cd_widget() {
  local dir
  dir=$({
    echo "$HOME/.config"
    echo "$_DOTFILES_ROOT"
    for parent in "$HOME/projects" "$HOME/code" "$HOME/work" "$HOME/Developments"; do
      [[ -d "$parent" ]] && find "$parent" -maxdepth 3 -type d -name ".git" \
        -exec dirname {} \; 2>/dev/null
    done
    # Subdirs of the cwd (not recursive).
    ls -1d "$PWD"/*/ 2>/dev/null | sed 's:/$::'
  } | awk '!a[$0]++' | fzf \
        --height=40% --reverse \
        --prompt='cd > ' \
        --preview='eza -1 --color=always --icons {} 2>/dev/null || ls {}' \
        --preview-window=right:50%:wrap)

  # reset-prompt only if there was a real cd — when fzf is cancelled
  # ($dir empty) a prompt redraw is needless noise.
  if [[ -n "$dir" ]]; then
    builtin cd -- "$dir"
    zle reset-prompt
  fi
}
# We only register the widget in interactive shells — `zle` doesn't exist in
# non-interactive ones (scripts, tools sourcing functions.zsh) and it would
# spam an error.
if [[ -o interactive ]]; then
  zle -N _fzf_cd_widget
  bindkey '^F' _fzf_cd_widget
fi

# ─── claude-config ─────────────────────────────────────────────
# Stash/restore a top-level block of ~/.claude/settings.json by name.
#   claude-config remove <block>  → stash `.<block>` to a sidecar, then strip it.
#   claude-config restore <block> → restore `.<block>` from the sidecar, verbatim.
# `remove` only stashes when the block is actually present, so running it twice
# never clobbers the stash with an empty one — the block survives a double-remove.
# settings.json is a real file (never symlinked), so mv is safe here (unlike
# ~/.zshrc). Requires jq (installed by the dotfiles installers).
claude-config() {
  local settings="$HOME/.claude/settings.json" action="$1" block="$2"
  if [[ -z "$block" ]]; then
    echo "usage: claude-config remove|restore <block>" >&2
    return 1
  fi
  local stash="$HOME/.claude/.${block}-stash.json"
  case "$action" in
    remove)
      if [[ "$(jq --arg b "$block" 'has($b)' "$settings")" == "true" ]]; then
        jq --arg b "$block" '.[$b]' "$settings" > "$stash"
        jq --arg b "$block" 'del(.[$b])' "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
        echo "claude-config: $block block removed (stashed → $stash)"
      else
        echo "claude-config: already removed (no $block block)"
      fi
      ;;
    restore)
      if [[ -f "$stash" ]]; then
        jq --arg b "$block" --slurpfile e "$stash" '.[$b] = $e[0]' "$settings" > "$settings.tmp" \
          && mv "$settings.tmp" "$settings"
        echo "claude-config: $block block restored"
      else
        echo "claude-config: nothing to restore ($stash missing)" >&2
        return 1
      fi
      ;;
    *)
      echo "usage: claude-config remove|restore <block>" >&2
      return 1
      ;;
  esac
}

# ─── claude / code --api: launch with the API env, per process ───
# Claude Code reads the gateway from ANTHROPIC_* env vars (documented at
# code.claude.com/docs/en/env-vars): ANTHROPIC_BASE_URL for the host,
# ANTHROPIC_API_KEY (X-Api-Key) or ANTHROPIC_AUTH_TOKEN (Bearer) for the
# credential, ANTHROPIC_MODEL for the model plus ANTHROPIC_DEFAULT_<TIER>_MODEL
# for what the opus/sonnet/haiku/fable aliases resolve to. Exporting those
# globally (or via the `env` block of settings.json) makes EVERY claude — and
# the VS Code extension — go through the gateway, hence the old
# `claude-config remove env` / `restore env` dance before each launch.
# Instead the values sit in ~/.claude/claude-api.env (per-machine, never
# versioned) and a `--api` flag hands them to ONE child process via `env`:
#   claude --api [args]  → claude through the gateway.
#   code --api [args]    → VS Code with the same vars, so its Claude Code
#                          extension (which spawns the CLI from VS Code's own
#                          environment) goes through the gateway too.
# Without the flag both are the plain binary, untouched: the wrappers run
# `command claude` / `command code`, nothing is read and the helper below is
# never even looked up, so a box with no gateway file never pays for a state
# that is not an error. (These replaced `claude-api` / `code-api`, sep-2026 —
# same machinery, but a suffixed name is a second command to remember and does
# not read as "the same tool, one switch".)
#
# THE PARSING ITSELF LIVES IN `scripts/claude-api-env`, on PATH via
# ~/.local/bin — these functions only strip the flag and delegate. Read that
# file for the env-file rules; the short version is that it is parsed, never
# sourced. The split exists because a zsh function is reachable only from an
# INTERACTIVE shell, and tmux launches its Claude popups through `$SHELL -c`
# (see tmux/utility.conf) where .zshrc never runs — so the gateway had a
# ceiling that no amount of work here could lift. One implementation on PATH
# serves the shell, tmux, scripts and hooks alike.
#
# `--api` IS ONLY RECOGNISED AS THE FIRST ARGUMENT, and is removed before the
# real binary sees it. Scanning the whole list would be friendlier to type but
# would also strip the string out of `claude -p 'compare --api vs the SDK'` —
# a silent corruption of the prompt, and neither binary has a real `--api` flag
# to collide with anyway. First-arg-only can never misread a value as a flag.
#
# THE FILE HOLDS THE REAL NAMES AND IS PASSED THROUGH VERBATIM. There used to be
# a CLAUDE_API_* prefix here and a 22-entry table translating it; the prefix
# bought nothing (checked against the 2.1.259 binary, Claude Code never reads
# `CLAUDE_API_*` from the environment — the one `CLAUDE_API_KEY` string in there
# is placeholder text in the GitHub-Actions setup flow) while the table had to
# grow a row for every variable the gateway might want, and a name missing from
# it was dropped in silence. Passthrough has no such hole: what you write is
# what the child gets. The docs are the reference for which names exist
# (code.claude.com/docs/en/env-vars); `_SUPPORTED_CAPABILITIES` is the one worth
# remembering, because Claude Code turns effort/thinking on by pattern-matching
# the model id, so a gateway's own id gets neither until that var declares them.
#
# WHY A FILE AND NOT ~/.zshenv.local, where the other secrets live: .zshenv is
# sourced by EVERY zsh, interactive or not, so an export there puts the gateway
# credential in the environment of every process the shell ever spawns — every
# script, every npm hook, anything that can read /proc or run `ps eww`. Reading
# it here instead keeps the token in exactly one child. That is also why the
# file, not an export, is the source of truth now: with the real names, an
# exported value would already have sent every plain `claude` through the
# gateway, which is the state this whole thing exists to avoid.
#
# The file holds a credential — keep it chmod 600. ~/.claude/ is Claude Code's
# own directory and its bundle carries a dotenv filename list (.env.local and
# friends), hence the unambiguous `claude-api.env` rather than `env.local`.
#
# NO LEADING UNDERSCORE ON THIS NAME. Claude Code's Bash tool does not source
# .zshrc; it replays a snapshot of the interactive shell's functions
# (~/.claude/shell-snapshots/) and that snapshot DROPS every function whose
# name starts with a single `_` (`_fzf_cd_widget`, `_prompt_git`… are all
# absent from it; `__zoxide_*` and plain names survive). `claude()` below is
# kept, so with a `_`-prefixed helper every `claude mcp list` / `claude agents
# --json` Claude runs from inside a session died with `command not found:
# _claude_api_launch`. A plain name rides along with the wrapper.
claude_api_launch() {
  local bin=$1
  shift
  if [[ $1 == --api ]]; then
    shift
    # Explicit check so a machine that hasn't re-run install.sh since the
    # helper was added says what to do, instead of `command not found`.
    if ! command -v claude-api-env >/dev/null 2>&1; then
      echo "$bin --api: claude-api-env is not on PATH (run ./install.sh)" >&2
      return 1
    fi
    # The helper execs the real binary from PATH, so this cannot re-enter the
    # wrapper the way a bare `$bin` would.
    command claude-api-env $bin "$@"
    return
  fi
  command $bin "$@"
}

claude() { claude_api_launch claude "$@" }

# VS Code footgun: `code` only spawns a NEW process when none is running; with
# a window already open it hands the args to that instance and its
# (gateway-less) environment wins. Quit VS Code first, then `code --api .`.
code() { claude_api_launch code "$@" }

# ─── refresh: reload tmux config + the shell env ──────────────
# One command for "I edited a dotfile and want it live now" without
# remembering which layer to poke. Two independent reloads:
#   1. tmux config (only if inside tmux) — `source-file` re-reads
#      tmux.conf so new binds / options apply. Reopening Ghostty does
#      NOT do this: the tmux server survives the emulator, keeping the
#      old config loaded. This is the reload people forget.
#   2. the shell — `exec zsh` replaces the process with a fresh one
#      that re-sources .zshenv (PATH, env vars like MANPAGER) AND
#      .zshrc (aliases, functions, plugins) from scratch. Cleaner than
#      `source ~/.zshrc`, which skips .zshenv and duplicates PATH.
# tmux reload runs FIRST because `exec` never returns (it replaces the
# shell, so anything after it would never run).
# Caveat: this reloads CONFIG, not already-running processes. A stale
# `caffeinate`/daemon launched before the change still needs its own
# restart — a shell refresh won't touch it.
refresh() {
  if [ -n "$TMUX" ]; then
    tmux source-file "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf" \
      && echo "tmux config reloaded"
  fi
  echo "reloading shell…"
  exec zsh
}
