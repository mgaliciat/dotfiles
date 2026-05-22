# ═══════════════════════════════════════════════════════════════
#  ~/.zshenv — cargado en TODA invocación de zsh (interactiva o no).
#  Para PATH y env vars que tienen que estar disponibles también
#  en scripts y subprocesos (Docker, Claude Code, etc.).
#  UI/aliases/prompt van en .zshrc.
# ═══════════════════════════════════════════════════════════════

# ─── PATH ─────────────────────────────────────────────────────
# Cross-platform: cada bloque se prepende sólo si el dir existe.
# Orden final (primero = mayor prioridad):
#   $HOME/.local/bin → Homebrew (mac o linux) → $HOME/.cargo/bin → resto del PATH
# ~/.zshenv.local puede prepender después y ganar prioridad.

# Cargo (Rust tools en Linux/WSL: starship, zoxide, delta, etc.)
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"

# Linuxbrew (raro, pero soportado por completitud)
[[ -d "/home/linuxbrew/.linuxbrew/bin" ]] && \
  export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"

# Homebrew macOS Apple Silicon
[[ -d "/opt/homebrew/bin" ]] && \
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# ~/.local/bin siempre wins — preserva el comportamiento original.
export PATH="$HOME/.local/bin:$PATH"

# Pyenv root (solo PATH; init lazy vive en .zshrc para no penalizar startup).
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# ─── env vars de CLI tools ────────────────────────────────────
# bat — usa colores del terminal (Anthropic Warm) en vez de su propio theme.
export BAT_THEME="ansi"

# Editor por default — nvim para todo lo que respete $EDITOR/$VISUAL:
# `edit-command-line` (Alt+e en el prompt), `crontab -e`, `less` (tecla v).
# git usa su propio core.editor, así que esto NO lo pisa.
export EDITOR="nvim"
export VISUAL="nvim"

# ─── overrides locales (no versionado) ────────────────────────
# ~/.zshenv.local para secrets/tokens/env vars per-máquina.
# Se carga al final para poder prepender al PATH y sobrescribir defaults.
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
