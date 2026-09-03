# ═══════════════════════════════════════════════════════════════
#  ~/.zshrc → sourced helper functions
#
#  Philosophy: only functions useful day to day that don't have a
#  simpler alias. Don't bloat. Anything per-machine goes in ~/.zshrc.local.
# ═══════════════════════════════════════════════════════════════

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
    echo "$HOME/dotfiles"
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

# ─── claude-api / code: launch with the API env, per process ───
# Claude Code reads the gateway from ANTHROPIC_* env vars (documented at
# code.claude.com/docs/en/env-vars): ANTHROPIC_BASE_URL for the host,
# ANTHROPIC_API_KEY (X-Api-Key) or ANTHROPIC_AUTH_TOKEN (Bearer) for the
# credential, ANTHROPIC_MODEL for the model plus ANTHROPIC_DEFAULT_<TIER>_MODEL
# for what the opus/sonnet/haiku/fable aliases resolve to. Exporting those
# globally (or via the `env` block of settings.json) makes EVERY claude — and
# the VS Code extension — go through the gateway, hence the old
# `claude-config remove env` / `restore env` dance before each launch.
# Instead the values sit in ~/.claude/claude-api.env (per-machine, never
# versioned) under a CLAUDE_API_* prefix, and these two map them onto the
# real ANTHROPIC_* names for ONE child process via `env`:
#   claude-api [args]  → claude through the gateway; plain `claude` stays as-is.
#   code-api [args]    → VS Code with the same vars, so its Claude Code
#                        extension (which spawns the CLI from VS Code's own
#                        environment) goes through the gateway too; plain
#                        `code` stays as-is.
# Neither shadows the bare command — the `-api` suffix IS the opt-in. An
# earlier version named the second one `code`, which meant every `code .` on
# a box with no gateway paid a warning for a state that is not an error.
# Only the CLAUDE_API_* vars that are set get mapped, so a gateway that
# needs just URL + token works without inventing model ids. BASE_URL is the
# one that must exist: without it there is no API to speak of, so both
# refuse instead of falling back — launching the plain binary under a name
# that promises the gateway would hide the misconfiguration, and the plain
# name is one word away.
# Each tier (OPUS/SONNET/HAIKU/FABLE) carries three companions, mapped with
# the same suffix: _NAME and _DESCRIPTION label it in the /model picker, and
# _SUPPORTED_CAPABILITIES (e.g. `effort,thinking,adaptive_thinking`) is what
# turns effort/thinking ON for an id the built-in pattern match does not
# recognise — a gateway alias like `my-gw/claude-opus-5` gets neither until
# it is declared, and once set ONLY the listed capabilities are enabled.
# CUSTOM_MODEL(+suffixes) → ANTHROPIC_CUSTOM_MODEL_OPTION* adds one extra
# picker entry; SUBAGENT_MODEL → CLAUDE_CODE_SUBAGENT_MODEL is what
# subagents/teammates run on when their definition names no model.
# VS Code footgun: `code` only spawns a NEW process when none is running;
# with a window already open it hands the args to that instance and its
# (gateway-less) environment wins. Quit VS Code first, then `code .`.
#
# WHY A FILE AND NOT ~/.zshenv.local, where the other secrets live: .zshenv is
# sourced by EVERY zsh, interactive or not, so an export there puts the gateway
# credential in the environment of every process the shell ever spawns — every
# script, every npm hook, anything that can read /proc or run `ps eww`. Reading
# it here instead keeps the token in exactly one child. It is NOT about Claude
# Code picking the prefix up: checked against the 2.1.259 binary, `CLAUDE_API_*`
# is never read from the environment (the one `CLAUDE_API_KEY` string in there
# is placeholder text in the GitHub-Actions setup flow, suggesting a name for a
# repo secret). An exported value still wins over the file, for one-off tests.
#
# The file is parsed, never sourced: `NAME=value` lines (an optional leading
# `export`, `#` comments, optional quotes), so a stray command in it cannot run.
# It holds a credential — keep it chmod 600. ~/.claude/ is Claude Code's own
# directory and its bundle carries a dotenv filename list (.env.local and
# friends), hence the unambiguous `claude-api.env` rather than `env.local`.
_claude_api_vars() {
  reply=()
  # Resolved per call, not at source time, so CLAUDE_API_ENV_FILE can point at
  # another file (a second gateway, a test) without reloading the shell.
  local envfile=${CLAUDE_API_ENV_FILE:-$HOME/.claude/claude-api.env}
  local -A vals
  local line k v
  if [[ -r $envfile ]]; then
    while IFS= read -r line || [[ -n $line ]]; do
      line=${line#"${line%%[![:space:]]*}"}
      [[ -z $line || $line == '#'* ]] && continue
      if [[ $line == export[[:space:]]* ]]; then
        line=${line#export}
        line=${line#"${line%%[![:space:]]*}"}
      fi
      k=${line%%=*}
      [[ $k == $line ]] && continue
      v=${line#*=}
      # One layer of matching quotes, the way the file would be written by hand.
      [[ $v == \"*\" || $v == \'*\' ]] && v=${v[2,-2]}
      vals[$k]=$v
    done < $envfile
  fi

  local base=${CLAUDE_API_BASE_URL:-$vals[CLAUDE_API_BASE_URL]}
  if [[ -z $base ]]; then
    # funcstack[2] is the caller, so the message names the command actually
    # typed (claude-api / code-api) instead of hardcoding one of the two.
    echo "${funcstack[2]}: CLAUDE_API_BASE_URL is unset (put it in $envfile)" >&2
    return 1
  fi
  reply+=("ANTHROPIC_BASE_URL=$base")
  local -a pairs=(
    KEY            ANTHROPIC_API_KEY
    AUTH_TOKEN     ANTHROPIC_AUTH_TOKEN
    MODEL          ANTHROPIC_MODEL
    DEFAULT_MODEL  ANTHROPIC_DEFAULT_MODEL
    SUBAGENT_MODEL CLAUDE_CODE_SUBAGENT_MODEL
  )
  local tier suffix
  for tier in OPUS SONNET HAIKU FABLE; do
    for suffix in "" _NAME _DESCRIPTION _SUPPORTED_CAPABILITIES; do
      pairs+=("${tier}_MODEL${suffix}" "ANTHROPIC_DEFAULT_${tier}_MODEL${suffix}")
    done
  done
  for suffix in "" _NAME _DESCRIPTION _SUPPORTED_CAPABILITIES; do
    pairs+=("CUSTOM_MODEL${suffix}" "ANTHROPIC_CUSTOM_MODEL_OPTION${suffix}")
  done
  local src target name val
  for src target in "${pairs[@]}"; do
    name="CLAUDE_API_${src}"
    val=${(P)name:-$vals[$name]}
    [[ -n $val ]] && reply+=("${target}=${val}")
  done
  return 0
}

claude-api() {
  local -a reply
  _claude_api_vars || return 1
  env "${reply[@]}" claude "$@"
}

code-api() {
  local -a reply
  _claude_api_vars || return 1
  env "${reply[@]}" code "$@"
}

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
