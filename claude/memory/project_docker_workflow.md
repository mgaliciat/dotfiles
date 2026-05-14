---
name: project-docker-workflow
description: User runs all dev workflows in Docker — host-side version managers have low ROI
metadata:
  type: project
---

The user runs all his development workflows (TypeScript, Go, Python projects) inside Docker containers, not on the macOS host.

**Why this matters:** Host-side version managers (mise, pyenv, nvm, asdf) have very low ROI for him. Language runtimes/versions live in `Dockerfile` / `docker-compose.yaml`, not in his shell. Suggesting a version manager as a productivity win is misframed for his setup.

**How to apply:**
- Don't recommend mise/pyenv/nvm as a productivity upgrade by default.
- His host-side Python (pyenv 3.14.4), Node (brew v26), Go (brew 1.26) are only used for: occasional scripts run outside docker, LSP binaries for the editor, and one-off CLI tools.
- If he asks about local language tooling, the question to ask is "is this for LSP/editor or for actually running code?" — if the latter, the answer probably belongs in the Dockerfile, not on the host.
- `mise` is installed via brew but **not activated** in his shell as of 2026-05-14. If host workflow needs ever emerge (LSP versioning, multi-project tool versions), `eval "$(mise activate zsh)"` in `.zshrc` is the only thing needed to wake it up.
