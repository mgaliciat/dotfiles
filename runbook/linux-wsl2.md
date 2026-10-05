# Ubuntu / Debian / WSL2

Portable subset: zsh, nvim, lazygit, git, Claude Code. No Ghostty. Entry
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
- **Claude Code** on PATH before the run, if you want the `context7` MCP
  server registered on the first pass.
- **Node.js** (`npx`) only for the `gh-stack` skill; optional.
- **`gh` (GitHub CLI)** comes from apt only on Ubuntu 23.10+ / Debian 13. Older
  releases: install it from GitHub's apt repo first, or accept that
  `gh-stack` skips.
- **Rust toolchain via rustup**, only for Rust work — the installer never
  touches it (the cargo block was removed on purpose, see the script). nvim's
  rust-analyzer, rustfmt and std sources are rustup components:

  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  rustup component add rust-analyzer rustfmt rust-src clippy
  ```

## First install

1. Secrets in place so the installer sees them:

   ```bash
   cat > ~/.zshenv.local <<'EOF'
   export CONTEXT7_API_KEY="…"
   EOF
   source ~/.zshenv.local
   ```

   The vault's MCP (`logbook-mcp`, which the logbook skills write through) is not
   the installer's job: after the install, run the one-line command in the notes of
   the vault's 1Password item. It needs `op` installed and signed in.

   This is bash at this point — `source` works the same.

2. Clone and run:

   ```bash
   git clone https://github.com/mgaliciat/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ./install-linux.sh
   ```

   What it does, in order:
   - symlinks the portable set (same list as macOS, from `scripts/lib.sh`). An
     existing `~/.zprofile` is moved aside like any other real file; move what
     it held into `~/.zprofile.local`, which `.zprofile` sources last;
   - `apt-get install` for what apt has (zsh, ripgrep, fd-find, bat, fzf,
     jq, gh, eza, the zsh plugins, python3, build-essential…);
   - shims `fd → fdfind` and `bat → batcat` into `~/.local/bin` where apt uses
     the renamed binaries — `.zshrc` guards the `cat` and `find` aliases on
     `command -v bat` / `fd`, so without the shim they silently stay the
     plain tools and the shell drifts from macOS;
   - configures Claude Code (same three scripts as macOS);
   - GitHub release binaries for what apt lacks or ships too old: lazygit,
     **nvim 0.10+** (tarball, no FUSE), delta (`.deb`), eza fallback, gomi,
     ghq, tree-sitter-cli; zoxide and pyenv via their official curl installers;
   - `chsh -s $(which zsh)` if zsh is not the login shell. It may ask for your
     password; it takes effect on the **next login**, not the current shell.

3. Per-machine git config: `~/.gitconfig` with `[include] path = ~/.gitconfig.local`
   as its last line; identity and signing in the `.local`. Plus the two keys the
   repo leans on and cannot ship (same as macOS):

   ```bash
   git config --global core.editor nvim
   git config --global pull.rebase true
   ```

4. Optional gateway file, same as macOS:

   ```bash
   install -m 600 /dev/null ~/.claude/claude-api.env
   printf 'ANTHROPIC_BASE_URL=https://<gateway>\nANTHROPIC_AUTH_TOKEN=…\n' >> ~/.claude/claude-api.env
   ```

5. `exec zsh`.

### WSL2 extras

The installer detects WSL2 and prints these; they are manual on purpose:

- **Fonts**: install them on Windows (`install-windows.ps1` does Maple,
  Monaspace, PlemolJP). A font installed inside the distro is invisible to
  Windows Terminal.
- **Clipboard for nvim**: `win32yank` on PATH inside the distro.

  ```bash
  curl -fsSLo /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip
  mkdir -p ~/.local/bin
  unzip -p /tmp/win32yank.zip win32yank.exe > ~/.local/bin/win32yank.exe
  chmod +x ~/.local/bin/win32yank.exe
  ```

- Ghostty config is not linked and nothing reads it here.

## Verify

```bash
readlink ~/.zshrc ~/.zprofile ~/.config/nvim ~/.local/bin/claude-api-env
echo $SHELL                                   # /usr/bin/zsh after re-login
nvim --version | head -1                      # v0.10 or newer
command -v fd bat eza zoxide lazygit delta gomi ghq tree-sitter rtk
claude mcp list
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

- **`⚠️  No apt candidate for: eza gh`.** Old Ubuntu; those two are skipped and
  the rest of the batch still installs. `eza` falls back to a GitHub release
  automatically. `gh` does not — install it from GitHub's apt
  repo and re-run so `bootstrap_gh_stack` finds it.
- **`dpkg` left a broken state after `delta`.** `sudo apt --fix-broken install`,
  then re-run.
- **`nvim` still reports 0.6/0.9.** The apt one is shadowing the tarball. The
  installer symlinks `~/.local/bin/nvim`; make sure `~/.local/bin` is first on
  PATH (`zsh/path.zsh` does this, through `.zshenv` — you are still in bash if
  it is not).
- **`command not found: fd`, or `cat` is plain `cat`.** The apt package
  installed `fdfind` / `batcat` and the shim step did not run. Re-run the
  installer; it is guarded on the shim being absent.
- **`chsh: PAM: Authentication failure`.** Run it by hand:
  `chsh -s "$(command -v zsh)"`. On WSL2 you can also set it in
  `/etc/wsl.conf` under `[user]`.
- **`pyenv install <version>` fails to compile.** The installer only installs
  pyenv itself. Building a Python needs the build dependencies pyenv
  documents (libssl-dev, zlib1g-dev, libbz2-dev, libreadline-dev, libsqlite3-dev,
  libffi-dev, liblzma-dev…) — apt-get them, then retry.
- **`→ context7: skipped`.** Env var not in the
  shell that ran the installer. Fix `~/.zshenv.local`, `exec zsh`, re-run.
- **Rotated token.** `claude mcp remove <name> -s user`, then re-run.
- **`rtk` missing after the run.** brew is not involved here; `binaries.sh`
  falls back to rtk's curl installer. If that failed (network), re-run.

## Undo

Replaced files are beside their symlink as `<file>.backup.<ts>`. Release
binaries live in `~/.local/bin` and `~/.local/share/nvim-linux` and can be
deleted directly. apt packages stay.
