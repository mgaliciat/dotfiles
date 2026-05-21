# ═══════════════════════════════════════════════════════════════
#  ~/.zshrc — solo cargado en shells interactivas.
#  Filosofía: startup <50ms. Sin Oh My Zsh. Sólo lo esencial.
#
#  Orden:
#    0. auto-tmux                                    (exec → corta el resto en padre)
#    1. history + opciones + completions + keybinds  (input/output)
#    2. tool inits                                   (pyenv, zoxide, fzf)
#    3. aliases
#    4. plugins                                      (syntax-highlight LAST)
#    5. prompt                                       (starship)
#    6. overrides locales                            (~/.zshrc.local)
# ═══════════════════════════════════════════════════════════════

# ─── auto-tmux ────────────────────────────────────────────────
# Cada ventana/pestaña de Ghostty arranca dentro de tmux. Usamos
# `exec` para que tmux REEMPLACE este zsh — cuando salgas con
# `exit` (o cierres la última window), el proceso muere y Ghostty
# cierra la ventana. Sin `exec` quedarías de vuelta en un zsh pelón.
#
# Guardas:
#   $TMUX vacío        → previene recursión. Las panes hijas que
#                        spawnea tmux tienen $TMUX seteado y siguen
#                        el flujo normal del .zshrc.
#   $- contiene 'i'    → solo shells interactivas. Scripts no.
#   $TERM_PROGRAM     → terminal integrada de VS Code mantiene shell
#                        pelón (su jump-to-error / cwd tracking se
#                        rompe con tmux en el medio).
#   $NO_AUTO_TMUX     → escape hatch manual: NO_AUTO_TMUX=1 ghostty
#                        abre una shell sin tmux para casos one-off.
#
# `tmux new-session` (sin -s) crea una sesión efímera nueva por
# ventana — Cmd+T NO clona contenido entre tabs. Las sesiones
# nombradas (claude-*, claude-yolo-*) viven independientes en el
# mismo server y persisten entre ventanas/reinicios de Ghostty.
if [[ -z "$TMUX" && $- == *i* && -z "$NO_AUTO_TMUX" \
      && "$TERM_PROGRAM" != "vscode" ]] \
   && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session
fi

# ─── history ──────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY           # historial compartido entre sesiones
setopt HIST_IGNORE_ALL_DUPS    # dedupe agresivo
setopt HIST_IGNORE_SPACE       # comandos que empiezan con espacio no se guardan
setopt HIST_VERIFY             # confirma antes de ejecutar !! y similares
setopt EXTENDED_HISTORY        # guarda timestamp

# ─── opciones útiles ──────────────────────────────────────────
setopt AUTO_CD                 # `cd foo` opcional, basta `foo/`
setopt AUTO_PUSHD              # cd guarda en stack
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS    # permite # comentarios en prompt

# ─── completions ──────────────────────────────────────────────
# Cargar compinit con cache de 24h (evita recompilación constante).
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C   # skip security check (más rápido)
fi

# fzf-tab requiere `menu no` — el menú nativo de zsh interfiere con fzf
# reemplazando el widget de completion. Si sacás fzf-tab volvé a `menu select`.
zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case-insensitive

# fzf-tab: preview contextual al tabular.
#  - cd/__zoxide_z: muestra contenido del dir (con eza si está)
#  - git checkout/switch: muestra el log del branch
#  - kill/proceso: muestra info del PID
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null || ls $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null || ls $realpath'
zstyle ':fzf-tab:complete:git-(checkout|switch):*' fzf-preview 'git log --oneline --color=always -20 $word 2>/dev/null'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps -p $word -o pid,user,start,command 2>/dev/null'
zstyle ':fzf-tab:*' switch-group ',' '.'   # , y . para navegar entre grupos de completions

# ─── key bindings (estilo emacs, default de zsh) ──────────────
bindkey -e
bindkey '^[[A' history-substring-search-up    # ↑ por substring (requiere zsh-history-substring-search)
bindkey '^[[B' history-substring-search-down  # ↓ por substring

# ─── tool inits ───────────────────────────────────────────────
# pyenv lazy-load — se inicializa al primer uso de pyenv/python/pip.
# Ahorra ~40ms al startup vs `eval "$(pyenv init -)"` eager.
pyenv() {
  unfunction pyenv
  eval "$(command pyenv init -)"
  pyenv "$@"
}

# zoxide → cd inteligente. Aprende dirs visitados, salta con 'cd proyecto'.
# command -v guard: si zoxide no está instalado (ej. WSL2 sin install completo)
# evitamos "command not found" en cada shell start.
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"

# fzf → fuzzy finder. Habilita Ctrl+R (history), Ctrl+T (files), Alt+C (cd).
source <(fzf --zsh) 2>/dev/null

# ─── funciones helper ─────────────────────────────────────────
# mkcd, port, server, gco, dex, dlogs, etc. (ver zsh/functions.zsh).
# %x (prompt expansion) da el path real del archivo siendo sourced,
# siguiendo el symlink ~/.zshrc → dotfiles/zsh/.zshrc.
source "${${(%):-%x}:A:h}/functions.zsh" 2>/dev/null

# ─── aliases ──────────────────────────────────────────────────
# CLI tools modernos (reemplazos del default de macOS)
alias ls='eza --group-directories-first'
alias ll='eza -lah --git --group-directories-first'
alias lt='eza --tree --level=2 --git-ignore'
alias cat='bat --paging=never --style=plain'     # `cat` real disponible como \cat
alias catp='bat'                                  # bat con paging + header completo
alias find='fd'
# ripgrep ya se invoca como 'rg' — sin alias necesario

# git (los sub-aliases viven en .gitconfig)
alias g='git'
alias gs='git st'
alias gd='git d'
alias gl='git lg'

# navegación
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ─── plugins (cross-platform discovery, no Oh My Zsh) ─────────
# Orden estricto requerido por los plugins:
#   1. fzf-tab               (DEBE cargarse después de compinit y ANTES
#                             de autosuggestions/highlighting porque
#                             envuelve el widget de completion)
#   2. autosuggestions       (gris en historial, → acepta)
#   3. syntax-highlighting   (verde/rojo según comando válido)
#   4. history-substring-search   (↑/↓ por substring — habilita los bindkeys de arriba)
# Si invertís el orden 3↔4, los matches de history-substring quedan
# sin highlightear. Documentado en docs del plugin.
#
# Discovery: probamos paths en orden — macOS brew → linuxbrew →
# apt (/usr/share, Ubuntu/Debian) → manual clone en ~/.zsh/plugins.
# Esto permite el mismo .zshrc en mac y Linux/WSL2 sin tocar nada.
#
# Naming: probamos `$name.zsh` (zsh-autosuggestions style) y luego
# `$name.plugin.zsh` (fzf-tab style). Ambas convenciones existen.
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
_load_zsh_plugin fzf-tab
_load_zsh_plugin zsh-autosuggestions
_load_zsh_plugin zsh-syntax-highlighting
_load_zsh_plugin zsh-history-substring-search

# ─── prompt: Starship ─────────────────────────────────────────
# command -v guard: si starship no está instalado evitamos error en startup.
# Sin starship el prompt cae al default de zsh (`%~ $`) — funcional pero feo.
command -v starship >/dev/null && eval "$(starship init zsh)"

# ─── overrides locales (no versionado) ────────────────────────
# ~/.zshrc.local para aliases / funciones / overrides per-máquina.
# Para env vars y secrets usar ~/.zshenv.local (cargado también en scripts).
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
