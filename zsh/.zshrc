# ═══════════════════════════════════════════════════════════════
#  ~/.zshrc — solo cargado en shells interactivas.
#  Filosofía: startup <50ms. Sin Oh My Zsh. Sólo lo esencial.
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

# ─── completions ──────────────────────────────────────────────
# Cargar compinit con cache de 24h (evita recompilación constante)
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
bindkey '^[[A' history-substring-search-up    # ↑ busca por prefijo
bindkey '^[[B' history-substring-search-down  # ↓ busca por prefijo

# ─── opciones útiles ──────────────────────────────────────────
setopt AUTO_CD                 # `cd foo` opcional, basta `foo/`
setopt AUTO_PUSHD              # cd guarda en stack
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS    # permite # comentarios en prompt

# ─── pyenv lazy-load ──────────────────────────────────────────
# Solo se inicializa al primer uso de pyenv/python/pip — ahorra ~40ms al startup
pyenv() {
  unfunction pyenv
  eval "$(command pyenv init -)"
  pyenv "$@"
}

# ─── plugins (vía homebrew, no Oh My Zsh) ─────────────────────
# Autosuggestions: sugerencias en gris según historial (acepta con →)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null

# Syntax highlighting: comandos válidos en verde, inválidos en rojo
# Debe cargarse al final, después de todo lo demás.
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# ─── aliases personales ───────────────────────────────────────
alias ll='ls -lah'
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias ..='cd ..'
alias ...='cd ../..'

# ─── prompt: Starship ─────────────────────────────────────────
# Debe ser lo último — initializa el prompt.
eval "$(starship init zsh)"
