# ═══════════════════════════════════════════════════════════════
#  ~/.zshenv — cargado en TODA invocación de zsh (incluyendo scripts).
#  Solo PATH y secrets aquí. UI/aliases/prompt van en .zshrc.
# ═══════════════════════════════════════════════════════════════

# Carga secrets locales (no versionados).
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local

# PATH base
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# Pyenv root (PATH solamente, sin init eager — eso es lento).
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
