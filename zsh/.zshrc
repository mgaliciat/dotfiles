# ═══════════════════════════════════════════════════════════════
#  ~/.zshrc — solo cargado en shells interactivas.
#  Filosofía: startup <50ms. Sin Oh My Zsh. Sólo lo esencial.
#
#  Orden:
#    1. history + opciones + completions + keybinds  (input/output)
#    2. tool inits                                   (pyenv, zoxide, fzf)
#    3. aliases
#    4. plugins                                      (syntax-highlight LAST)
#    5. prompt                                       (starship)
#    6. overrides locales                            (~/.zshrc.local)
# ═══════════════════════════════════════════════════════════════

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

zstyle ':completion:*' menu select                         # navegación con flechas
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case-insensitive

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
eval "$(zoxide init zsh --cmd cd)"

# fzf → fuzzy finder. Habilita Ctrl+R (history), Ctrl+T (files), Alt+C (cd).
source <(fzf --zsh) 2>/dev/null

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

# ─── plugins (Homebrew, no Oh My Zsh) ─────────────────────────
# Orden estricto requerido por los plugins:
#   1. autosuggestions       (gris en historial, → acepta)
#   2. syntax-highlighting   (verde/rojo según comando válido)
#   3. history-substring-search   (↑/↓ por substring — habilita los bindkeys de arriba)
#
# Si invertís el orden 2↔3, los matches de history-substring quedan
# sin highlightear. Documentado en docs del plugin.
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh 2>/dev/null

# ─── prompt: Starship ─────────────────────────────────────────
eval "$(starship init zsh)"

# ─── overrides locales (no versionado) ────────────────────────
# ~/.zshrc.local para aliases / funciones / overrides per-máquina.
# Para env vars y secrets usar ~/.zshenv.local (cargado también en scripts).
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
