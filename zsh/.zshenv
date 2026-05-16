# ═══════════════════════════════════════════════════════════════
#  ~/.zshenv — cargado en TODA invocación de zsh (interactiva o no).
#  Para PATH y env vars que tienen que estar disponibles también
#  en scripts y subprocesos (Docker, Claude Code, etc.).
#  UI/aliases/prompt van en .zshrc.
# ═══════════════════════════════════════════════════════════════

# ─── PATH ─────────────────────────────────────────────────────
# Base primero. ~/.zshenv.local puede prepender después y ganar prioridad.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# Pyenv root (solo PATH; init lazy vive en .zshrc para no penalizar startup).
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# ─── env vars de CLI tools ────────────────────────────────────
# bat — usa colores del terminal (Anthropic Warm) en vez de su propio theme.
export BAT_THEME="ansi"

# ─── overrides locales (no versionado) ────────────────────────
# ~/.zshenv.local para secrets/tokens/env vars per-máquina.
# Se carga al final para poder prepender al PATH y sobrescribir defaults.
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
