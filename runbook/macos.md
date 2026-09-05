# macOS

Full stack: Ghostty, zsh, nvim, tmux, lazygit, Claude Code, fonts. Entry point
`./install.sh`. Read [`README.md`](README.md) in this folder first for the
per-machine files and the two silent guards.

## Prerequisites

- **Xcode Command Line Tools** (gives you `git`): `xcode-select --install`.
- **Homebrew.** Without it the installer only symlinks, prints the install
  command and stops short of every dependency.

  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

- **Claude Code** installed and on PATH, if you want the MCP servers registered
  on the first pass. Neither installer installs it.
- **Node.js** (for `npx`), only for the `gh-stack` skill. Without it that one
  step prints `→ skipped` and everything else proceeds.
- **1Password** running, only if this machine signs commits through
  `op-ssh-sign`. Unrelated to the installer; it bites on the first `git commit`.
- **Rust toolchain via rustup**, only for Rust work — the installer never
  touches it. nvim's rust-analyzer, rustfmt and std sources are rustup
  components, and a rustup install without them leaves proxies on PATH that
  fail on exec (so `command -v rust-analyzer` lies; `rust-analyzer --version`
  does not):

  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  rustup component add rust-analyzer rustfmt rust-src clippy
  ```

## First install

1. Secrets in place, so the installer sees them (see the folder README):

   ```bash
   cat > ~/.zshenv.local <<'EOF'
   export CONTEXT7_API_KEY="…"
   export OPENKNOWLEDGE_MCP_URL="https://<host>/mcp"
   export OPENKNOWLEDGE_CF_ACCESS_CLIENT_ID="<id>.access"
   export OPENKNOWLEDGE_CF_ACCESS_CLIENT_SECRET="…"
   EOF
   source ~/.zshenv.local
   ```

   All three `OPENKNOWLEDGE_*` vars or none — a half-registered server looks
   configured and fails at call time.

2. Clone and run. Any path works (the scripts locate themselves); `~/dotfiles`
   is the convention the docs assume.

   ```bash
   git clone https://github.com/mgaliciat/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ./install.sh
   ```

   What it does, in order:
   - symlinks the portable set (`.zshrc`, `.zshenv`, `.gitignore_global`,
     `nvim`, `tmux`, lazygit, `~/.local/bin/{ide,claude-api-env}`) plus Ghostty
     (`config.ghostty` into Application Support, `themes/` into
     `~/.config/ghostty/` — two different dirs, both required);
   - installs the missing Homebrew formulae and casks (fonts included) and Paper
     Mono by direct download, since it has no cask;
   - configures Claude Code: `settings.json` keys (additive, guarded), the
     `CLAUDE.md` / statusline / hook / skill symlinks, `rtk`,
     `codebase-memory-mcp`, the two MCP endpoints, the `gh-stack` skill;
   - clones tpm, pins `tmux-claude-session-manager`, reloads a running tmux;
   - installs the `gh-stack` extension;
   - registers VS Code as the default app for `.ghostty` files, if installed.

3. Bring the per-machine git config: `~/.gitconfig` with an `[include]` of
   `~/.gitconfig.local` as its **last** line, identity and signing in the
   `.local`. Neither file is in the repo.

4. If this machine talks to an API gateway:

   ```bash
   install -m 600 /dev/null ~/.claude/claude-api.env
   cat >> ~/.claude/claude-api.env <<'EOF'
   ANTHROPIC_BASE_URL=https://<gateway>
   ANTHROPIC_AUTH_TOKEN=…
   EOF
   ```

   Real `ANTHROPIC_*` names, passed through verbatim. `ANTHROPIC_BASE_URL` is
   the one required key; without it `claude --api` refuses to launch.

5. `exec zsh`. An interactive shell **auto-starts tmux** (`exec tmux
   new-session` in `.zshrc`). Escape hatch: `NO_AUTO_TMUX=1`. Inside tmux the
   first time: `C-t I` (prefix is `C-t`) to install the plugins tpm lists.

6. Open Ghostty. The theme and font are already selected in the config; if the
   glyphs look wrong, check the family name resolved:

   ```bash
   ghostty +list-fonts | grep -i 'paper mono'
   ```

7. **Caps Lock → Option**: System Settings → Keyboard → Keyboard Shortcuts →
   Modifier Keys. Per device, not in the repo. Do not use Karabiner for this on
   a Latin American layout — it swaps `<>` with `|°`.

## Verify

```bash
readlink ~/.zshrc ~/.config/nvim ~/.config/tmux ~/.local/bin/ide     # all into the repo
readlink ~/.claude/CLAUDE.md ~/.claude/skills/bitacora ~/.claude/skills/wiki
claude mcp list                                                     # context7, open-knowledge, codebase-memory
rtk --version && rtk config                                         # config path under ~/Library/Application Support/rtk
tmux -V && git -C ~/.config/tmux/plugins/tmux-claude-session-manager rev-parse --short HEAD
nvim --headless '+Lazy! sync' +qa                                   # first plugin install, non-interactive
```

In tmux: `Alt+c` opens Claude in a popup, `Alt+d` detaches it, `Alt+u` lists
sessions, `Alt+a` is the gateway twin (needs the env file).

## Re-run after a pull

```bash
cd ~/dotfiles && git pull && ./install.sh && exec zsh
```

Then the reload table in the folder README. Ghostty in particular: saving the
file does nothing on screen until `Cmd+Shift+R`.

## Troubleshooting

- **`→ context7: skipped` / `→ open-knowledge: skipped`.** The env var was not
  in the shell that ran the installer. Add it to `~/.zshenv.local`, `exec zsh`,
  re-run.
- **Rotated token.** `claude mcp add` errors if the name exists, so the
  installer will report "already registered" with the old header. Remove first:
  `claude mcp remove open-knowledge -s user` (or `context7`), then re-run.
- **Ghostty "theme not found".** Themes must be under `~/.config/ghostty/themes`,
  not beside the config. `readlink ~/.config/ghostty/themes` should point into
  the repo; re-run the installer if not.
- **Ghostty ignores the config entirely.** A stale plain `config` (no
  extension) in Application Support wins over `config.ghostty`. The installer
  moves it to `config.backup.<ts>`; check that dir if it came back.
- **`claude --api` says the env file is missing.** Step 4 above. The path can be
  overridden with `CLAUDE_API_ENV_FILE` for a second gateway.
- **`Alt+a` popup flashes and closes.** The helper is not on PATH yet — a
  `git pull` delivered the tmux bind but `./install.sh` has not delivered the
  `~/.local/bin/claude-api-env` symlink. Re-run the installer.
- **`git commit` fails with "1Password: Could not connect to socket".** The
  1Password app is not running (the browser helper alone is not enough):
  `open -a 1Password`.
- **`gh-stack: skipped`.** No `gh` or no `npx` on PATH. Both are optional; the
  installer says which one and how to get it.
- **`codebase-memory` skill vanished after deleting `~/.claude`.** Re-run the
  installer; `codebase-memory-mcp install -y` runs unguarded on purpose and
  rebuilds hooks, server and skill.

## Undo

Every file the installer replaced is beside its symlink as
`<file>.backup.<ts>`. Remove the symlink, move the backup back. Homebrew
packages stay; nothing here uninstalls.
