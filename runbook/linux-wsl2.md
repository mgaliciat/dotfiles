# Ubuntu / Debian / WSL2

Portable subset: zsh, nvim, tmux, lazygit, git, Claude Code. No Ghostty. Entry
point `./install-linux.sh`. Read [`README.md`](README.md) in this folder first
for the per-machine files and the two silent guards.

On **WSL2** this is half the job: fonts and the terminal theme live on the
Windows side, so also run [`windows.md`](windows.md) there.

## Prerequisites

- **Ubuntu 22.04+ or Debian 12+**, `x86_64` or `arm64`. Other arches are not
  implemented: every GitHub-release step prints `⚠️ Could not resolve … arch`
  and skips.
- **`sudo`**. Used for `apt-get` and for the `delta` `.deb`; the script prompts
  when it gets there.
- `git` and `curl` to clone and to fetch the release binaries. `apt-get install
  git curl` if the image is bare.
- **Claude Code** on PATH before the run, if you want the MCP servers
  registered on the first pass.
- **Node.js** (`npx`) only for the `gh-stack` skill; optional.
- **`gh` (GitHub CLI)** comes from apt only on Ubuntu 23.10+ / Debian 13. Older
  releases: install it from GitHub's apt repo first, or accept that
  `gh-stack` skips.

## First install

1. Secrets in place so the installer sees them:

   ```bash
   cat > ~/.zshenv.local <<'EOF'
   export CONTEXT7_API_KEY="…"
   export OPENKNOWLEDGE_MCP_URL="https://<host>/mcp"
   export OPENKNOWLEDGE_CF_ACCESS_CLIENT_ID="<id>.access"
   export OPENKNOWLEDGE_CF_ACCESS_CLIENT_SECRET="…"
   EOF
   source ~/.zshenv.local
   ```

   This is bash at this point — `source` works the same. All three
   `OPENKNOWLEDGE_*` or none.

2. Clone and run:

   ```bash
   git clone https://github.com/mgaliciat/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ./install-linux.sh
   ```

   What it does, in order:
   - symlinks the portable set (same list as macOS, from `scripts/lib.sh`);
   - `apt-get install` for what apt has (zsh, tmux, ripgrep, fd-find, bat, fzf,
     jq, gh, eza, the zsh plugins, python3, build-essential…);
   - shims `fd → fdfind` and `bat → batcat` into `~/.local/bin` where apt uses
     the renamed binaries — the `cat` alias in `.zshrc` is unguarded, so
     without the shim every `cat` breaks;
   - configures Claude Code (same three scripts as macOS);
   - clones tpm, pins `tmux-claude-session-manager`;
   - GitHub release binaries for what apt lacks or ships too old: lazygit,
     **nvim 0.10+** (tarball, no FUSE), delta (`.deb`), eza fallback, gomi,
     tree-sitter-cli; zoxide and pyenv via their official curl installers;
   - `chsh -s $(which zsh)` if zsh is not the login shell. It may ask for your
     password; it takes effect on the **next login**, not the current shell.

3. Per-machine git config: `~/.gitconfig` with `[include] path = ~/.gitconfig.local`
   as its last line; identity and signing in the `.local`.

4. Optional gateway file, same as macOS:

   ```bash
   install -m 600 /dev/null ~/.claude/claude-api.env
   printf 'ANTHROPIC_BASE_URL=https://<gateway>\nANTHROPIC_AUTH_TOKEN=…\n' >> ~/.claude/claude-api.env
   ```

5. `exec zsh`. An interactive shell auto-starts tmux; `NO_AUTO_TMUX=1` to
   skip. Inside tmux the first time: `C-t I` to install plugins.

### WSL2 extras

The installer detects WSL2 and prints these; they are manual on purpose:

- **Fonts**: install them on Windows (`install-windows.ps1` does Maple,
  Monaspace, PlemolJP). A font installed inside the distro is invisible to
  Windows Terminal.
- **Clipboard for nvim**: `win32yank` on PATH inside the distro.

  ```bash
  curl -sLo /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip
  mkdir -p ~/.local/bin
  unzip -p /tmp/win32yank.zip win32yank.exe > ~/.local/bin/win32yank.exe
  chmod +x ~/.local/bin/win32yank.exe
  ```

- Ghostty config is not linked and nothing reads it here.

## Verify

```bash
readlink ~/.zshrc ~/.config/nvim ~/.config/tmux ~/.local/bin/ide ~/.local/bin/claude-api-env
echo $SHELL                                   # /usr/bin/zsh after re-login
nvim --version | head -1                      # v0.10 or newer
command -v fd bat eza zoxide lazygit delta gomi tree-sitter rtk
claude mcp list
git -C ~/.config/tmux/plugins/tmux-claude-session-manager rev-parse --short HEAD
```

`fd` and `bat` should resolve to `~/.local/bin/` shims on Ubuntu, not to the
apt binaries directly.

## Re-run after a pull

```bash
cd ~/dotfiles && git pull && ./install-linux.sh && exec zsh
```

The release-binary steps are guarded on `command -v`, so a tool already
installed is never re-downloaded — this is not an upgrade path. To upgrade one,
remove it from `~/.local/bin` and re-run.

## Troubleshooting

- **`E: Unable to locate package eza` / `gh`.** Old Ubuntu. `eza` falls back to
  a GitHub release automatically. `gh` does not — install it from GitHub's apt
  repo and re-run so `bootstrap_gh_stack` finds it.
- **`dpkg` left a broken state after `delta`.** `sudo apt --fix-broken install`,
  then re-run.
- **`nvim` still reports 0.6/0.9.** The apt one is shadowing the tarball. The
  installer symlinks `~/.local/bin/nvim`; make sure `~/.local/bin` is first on
  PATH (`.zshenv` does this — you are still in bash if it is not).
- **`command not found: fd` / `cat: broken alias`.** The apt package installed
  `fdfind` / `batcat` and the shim step did not run. Re-run the installer; it
  is guarded on the shim being absent.
- **`chsh: PAM: Authentication failure`.** Run it by hand:
  `chsh -s "$(command -v zsh)"`. On WSL2 you can also set it in
  `/etc/wsl.conf` under `[user]`.
- **`pyenv install <version>` fails to compile.** The installer only installs
  pyenv itself. Building a Python needs the build dependencies pyenv
  documents (libssl-dev, zlib1g-dev, libbz2-dev, libreadline-dev, libsqlite3-dev,
  libffi-dev, liblzma-dev…) — apt-get them, then retry.
- **`→ context7: skipped` / `→ open-knowledge: skipped`.** Env var not in the
  shell that ran the installer. Fix `~/.zshenv.local`, `exec zsh`, re-run.
- **Rotated token.** `claude mcp remove <name> -s user`, then re-run.
- **tmux config not reloaded.** No server was running, which is normal on a
  fresh login. The next `tmux` reads it.
- **`rtk` missing after the run.** brew is not involved here; `binaries.sh`
  falls back to rtk's curl installer. If that failed (network), re-run.

## Undo

Replaced files are beside their symlink as `<file>.backup.<ts>`. Release
binaries live in `~/.local/bin` and `~/.local/share/nvim-linux` and can be
deleted directly. apt packages stay.
