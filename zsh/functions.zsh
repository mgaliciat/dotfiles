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
  # THAT has to be stripped at the source: `${branch## }` only removes one space,
  # leaving `git checkout " main"` → "pathspec did not match" for any
  # non-current branch.
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

# Exec into a running container (fzf-pick). bash if the image has it, else sh.
# The choice is made INSIDE the container, in one exec: two execs chained with
# `||` would also run the sh fallback whenever the bash session itself ends
# non-zero (the last command failed, `exit 1`), dropping you into a second shell.
# Usage: dex
dex() {
  local cid
  cid=$(docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}' \
        | fzf | awk '{print $1}')
  # The pipeline's status is awk's, so a cancelled fzf only shows up as an
  # empty id — catch it here rather than hand docker an empty argument.
  [[ -n "$cid" ]] || return
  docker exec -it "$cid" sh -c 'command -v bash >/dev/null && exec bash || exec sh'
}

# Tail the logs of a container (running or exited).
# Usage: dlogs
dlogs() {
  local cid
  cid=$(docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Status}}' \
        | fzf | awk '{print $1}')
  [[ -n "$cid" ]] || return   # cancelled fzf, same as dex
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
# configs, dotfiles, every ghq-managed clone and subdirs of the cwd.
# More opinionated than `zoxide` (which goes by frequency) — useful
# when you start from scratch and want to jump to "that project I know
# exists in some folder".
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
    # Every clone ghq knows about, which is every clone: $GHQ_ROOT (.zshenv) is
    # the one place they live. Asking ghq cannot drift the way a hardcoded list
    # of parent dirs does — it reports what is on disk rather than where we
    # guessed it would be, and it is not depth-limited.
    command -v ghq >/dev/null && ghq list --full-path
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
# the VS Code extension — go through the gateway.
# Instead the values sit in ~/.claude/claude-api.env (per-machine, never
# versioned) and a `--api` flag hands them to ONE child process via `env`:
#   claude --api [args]  → claude through the gateway.
#   code --api [args]    → VS Code with the same vars, so its Claude Code
#                          extension (which spawns the CLI from VS Code's own
#                          environment) goes through the gateway too.
# Without the flag both are the plain binary, untouched: the wrappers run
# `command claude` / `command code`, nothing is read and the helper below is
# never even looked up, so a box with no gateway file never pays for a state
# that is not an error. A flag rather than a suffixed `claude-api` command: it
# reads as "the same tool, one switch", not a second command to remember.
#
# THE PARSING ITSELF LIVES IN `scripts/claude-api-env`, on PATH via
# ~/.local/bin — these functions only strip the flag and delegate. Read that
# file for the env-file rules; the short version is that it is parsed, never
# sourced. The split exists because a zsh function is reachable only from an
# INTERACTIVE shell; one implementation on PATH serves the shell, scripts and
# hooks alike.
#
# `--api` IS ONLY RECOGNISED AS THE FIRST ARGUMENT, and is removed before the
# real binary sees it. Scanning the whole list would be friendlier to type but
# would also strip the string out of `claude -p 'compare --api vs the SDK'` —
# a silent corruption of the prompt, and neither binary has a real `--api` flag
# to collide with anyway. First-arg-only can never misread a value as a flag.
#
# THE FILE HOLDS THE REAL NAMES AND IS PASSED THROUGH VERBATIM — no prefix, no
# translation table that would need a row per variable and drop a missing name
# in silence: what you write is what the child gets. The docs are the reference for which names exist
# (code.claude.com/docs/en/env-vars); `_SUPPORTED_CAPABILITIES` is the one worth
# remembering, because Claude Code turns effort/thinking on by pattern-matching
# the model id, so a gateway's own id gets neither until that var declares them.
#
# WHY A FILE AND NOT ~/.zshenv.local, where the other secrets live: .zshenv is
# sourced by EVERY zsh, interactive or not, so an export there puts the gateway
# credential in the environment of every process the shell ever spawns — every
# script, every npm hook, anything that can read /proc or run `ps eww`. Reading
# it here instead keeps the token in exactly one child. It is also why the
# file, not an export, is the source of truth: with the real names, an
# exported value would send every plain `claude` through the gateway, which
# is the state this whole thing exists to avoid.
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
# --json` Claude runs from inside a session would die with `command not found`.
# A plain name rides along with the wrapper.
claude_api_launch() {
  local bin=$1
  shift
  if [[ $1 == --api ]]; then
    shift
    # Explicit check so a machine whose install.sh run predates the helper
    # says what to do, instead of `command not found`.
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

# ─── refresh: reload the shell env ────────────────────────────
# "I edited a dotfile and want it live now". `exec zsh` replaces the
# process with a fresh one that re-sources .zshenv (PATH, env vars like
# MANPAGER) AND .zshrc (aliases, functions, plugins) from scratch. Cleaner
# than `source ~/.zshrc`, which skips .zshenv and duplicates PATH.
# Caveat: this reloads CONFIG, not already-running processes. A stale
# daemon launched before the change still needs its own restart.
refresh() {
  echo "reloading shell…"
  exec zsh
}
