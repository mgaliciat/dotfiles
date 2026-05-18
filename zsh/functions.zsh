# ═══════════════════════════════════════════════════════════════
#  ~/.zshrc → sourced helper functions
#
#  Filosofía: solo funciones útiles a diario que no tengan alias
#  más simple. No bloatear. Lo que sea per-máquina va en ~/.zshrc.local.
# ═══════════════════════════════════════════════════════════════

# ─── navegación / shell ───────────────────────────────────────

# mkdir + cd en un solo paso.
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Qué proceso está usando un puerto TCP (LISTEN).
# Uso: port 3000
port() {
  lsof -nP -iTCP:"$1" -sTCP:LISTEN
}

# IP pública (vía ipify).
myip() {
  curl -s https://api.ipify.org && echo
}

# IP local (LAN) — prueba Wi-Fi (en0) y luego Ethernet (en1).
localip() {
  ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1
}

# HTTP server en el dir actual. Default port 8000.
# Uso: server  /  server 4000
server() {
  local p="${1:-8000}"
  echo "→ http://localhost:$p"
  python3 -m http.server "$p"
}

# ─── git con fzf ──────────────────────────────────────────────

# Pick branch (local + remote) con fzf y checkout.
# Uso: gco
gco() {
  local branch
  branch=$(git branch --all 2>/dev/null \
           | grep -v HEAD \
           | sed 's|remotes/origin/||' \
           | sort -u \
           | fzf) || return
  git checkout "${branch## }"
}

# ─── docker ───────────────────────────────────────────────────

# Exec en un container running (fzf-pick). Intenta bash → fallback sh.
# Uso: dex
dex() {
  local cid
  cid=$(docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}' \
        | fzf | awk '{print $1}') || return
  docker exec -it "$cid" /bin/bash 2>/dev/null \
    || docker exec -it "$cid" /bin/sh
}

# Tail logs de un container (running o exited).
# Uso: dlogs
dlogs() {
  local cid
  cid=$(docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Status}}' \
        | fzf | awk '{print $1}') || return
  docker logs -f --tail=100 "$cid"
}

# Stop de todos los containers running.
# Uso: dstop-all
dstop-all() {
  docker ps -q | xargs -r docker stop
}

# Cleanup agresivo: containers parados, imágenes danglig, volúmenes y networks
# huérfanos. NO toca containers ni imágenes en uso. Liberá espacio rápido.
# Uso: dprune-all
dprune-all() {
  docker system prune -af --volumes
}

# ─── proyectos ────────────────────────────────────────────────

# Abre el "workspace finanzas": cd a ~/finance + sesión tmux dedicada
# con `claude --dangerously-skip-permissions` (equivalente shell del
# popup Alt+Shift+C). Sesión persistente — si ya existe attachea y
# mantenés contexto de Claude entre invocaciones.
#
# Si ya estás dentro de tmux usa switch-client; afuera, attach normal.
# Uso: finance
finance() {
  local dir="$HOME/finance"
  local session="finance"

  [[ -d "$dir" ]] || { echo "finance: $dir no existe" >&2; return 1; }
  cd "$dir" || return

  tmux has-session -t "$session" 2>/dev/null || \
    tmux new-session -d -s "$session" -c "$dir" "claude --dangerously-skip-permissions"

  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$session"
  else
    tmux attach-session -t "$session"
  fi
}
