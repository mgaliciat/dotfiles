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
  # `git branch --all` indenta con 2 espacios (y la rama actual con `* `).
  # Hay que strippear ESO en origen: `${branch## }` solo quita un espacio y
  # dejaba `git checkout " main"` → "pathspec did not match" al elegir
  # cualquier rama no-actual.
  branch=$(git branch --all 2>/dev/null \
           | grep -v HEAD \
           | sed 's|remotes/origin/||' \
           | sed 's/^[ *]*//' \
           | sort -u \
           | fzf) || return
  [[ -n "$branch" ]] || return   # fzf cancelado → no intentes checkout
  git checkout "$branch"
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

# ─── fuzzy cd (estilo craftzdog) ──────────────────────────────
#
# Ctrl+F → fzf con lista curada de directorios "interesantes":
# configs, dotfiles, repos en ubicaciones convencionales y subdirs
# del cwd. Más opinado que `zoxide` (que va por frecuencia) — útil
# cuando arrancás desde cero y querés saltar a "ese proyecto que sé
# que existe en alguna carpeta".
#
# Trade-off: Ctrl+F default en emacs-mode es `forward-char` (cursor
# adelante 1 char). Si lo necesitás, podés usar la flecha → o
# rebindear a otra tecla (ej. bindkey '^G' _fzf_cd_widget). Craftzdog
# acepta el trade-off, su mapping fish es idéntico.
#
# Cada bloque del `{ ... }` aporta una fuente; `awk '!a[$0]++'`
# deduplica preservando orden.
_fzf_cd_widget() {
  local dir
  dir=$({
    echo "$HOME/.config"
    echo "$HOME/dotfiles"
    [[ -d "$HOME/finance" ]] && echo "$HOME/finance"
    for parent in "$HOME/projects" "$HOME/code" "$HOME/work" "$HOME/Developments"; do
      [[ -d "$parent" ]] && find "$parent" -maxdepth 3 -type d -name ".git" \
        -exec dirname {} \; 2>/dev/null
    done
    # Subdirs del cwd (no recursivo).
    ls -1d "$PWD"/*/ 2>/dev/null | sed 's:/$::'
  } | awk '!a[$0]++' | fzf \
        --height=40% --reverse \
        --prompt='cd > ' \
        --preview='eza -1 --color=always --icons {} 2>/dev/null || ls {}' \
        --preview-window=right:50%:wrap)

  # reset-prompt solo si hubo cd real — al cancelar fzf ($dir vacío) un
  # redibujado del prompt es ruido innecesario.
  if [[ -n "$dir" ]]; then
    builtin cd -- "$dir"
    zle reset-prompt
  fi
}
# Solo registramos el widget en shells interactivos — `zle` no existe en
# no-interactive (scripts, tools sourcing functions.zsh) y spamearía error.
if [[ -o interactive ]]; then
  zle -N _fzf_cd_widget
  bindkey '^F' _fzf_cd_widget
fi

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

# ─── tema del stack ───────────────────────────────────────────
# Wrapper de scripts/theme: voltea Ghostty + nvim + tmux a un mismo
# tema de la familia (osaka, oled-neon, anthropic-dark, …). El detalle
# del mecanismo (punteros *.local per-máquina, reloads) vive en el script.
#   theme <id>   aplica · theme list   lista · theme   muestra el actual
theme() {
  "$HOME/dotfiles/scripts/theme" "$@"
}

# Completion: la familia + alias osaka + subcomandos. compinit ya corrió
# (lo carga .zshrc antes de sourcear functions.zsh), pero guardamos por si
# functions.zsh se sourcea en un contexto sin compdef.
if (( $+functions[compdef] )); then
  _theme() {
    compadd osaka oled-neon carbon anthropic-dark anthropic-warm prism-night paper \
            solarized-osaka osaka-moon osaka-storm osaka-day list
  }
  compdef _theme theme
fi
