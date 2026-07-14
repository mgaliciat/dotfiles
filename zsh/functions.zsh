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
