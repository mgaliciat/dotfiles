# Native Windows

**Narrow scope, on purpose.** zsh, tmux and nvim do not run natively, so this
is not a port of the stack. `./install-windows.ps1` covers: the Claude Code
pieces, `git/.gitignore_global`, Nerd Fonts, the stack theme as a Windows
Terminal colour scheme, and two Windows Terminal keybindings for Claude. For a
real shell on a Windows box use WSL2 and follow [`linux-wsl2.md`](linux-wsl2.md)
inside the distro — then come back here for the fonts and the theme, which the
distro cannot install.

Read [`README.md`](README.md) in this folder first for the two silent guards.

## Prerequisites

- **PowerShell 5.1 or 7+.** Both parse the script; 7 is what CI checks.
- **Git for Windows.**
- **Developer Mode** — Settings → System → For developers. Without it (or
  Administrator), symlinks fail and the script **copies** the files instead,
  warning on screen. Copies work today but a `git pull` no longer propagates
  until you enable Developer Mode and re-run.
- **Claude Code** on PATH, if you want the MCP servers registered on the first
  pass.
- **Windows Terminal**, for the theme, font and keybinding blocks. Absent, they
  skip.
- Optional: **scoop** (for the Nerd Fonts — install it in a *non-admin* shell,
  its installer refuses elevation), **`gh`** (`winget install --id GitHub.cli`,
  for the gh-stack extension), **Node.js** (`npx`, for the gh-stack skill).

Run the script **non-elevated with Developer Mode on**. Elevation is the
fallback for symlinks, and scoop refuses to run under it.

## First install

1. Secrets as **user environment variables**. There is no `~/.zshenv.local`
   here. `setx` writes the registry, not the current session, so open a **new**
   terminal afterwards.

   ```powershell
   setx CONTEXT7_API_KEY "…"
   setx OPENKNOWLEDGE_MCP_URL "https://<host>/mcp"
   setx OPENKNOWLEDGE_CF_ACCESS_CLIENT_ID "<id>.access"
   setx OPENKNOWLEDGE_CF_ACCESS_CLIENT_SECRET "…"
   ```

   All three `OPENKNOWLEDGE_*` or none.

2. Clone and run, in the new terminal:

   ```powershell
   git clone https://github.com/mgaliciat/dotfiles.git $HOME\dotfiles
   cd $HOME\dotfiles
   .\install-windows.ps1
   ```

   If it stops on the execution policy:

   ```powershell
   PowerShell -ExecutionPolicy Bypass -File .\install-windows.ps1
   ```

   What it does, in order:
   - symlinks `claude/CLAUDE.md`, `statusline.ps1`, `hooks/bitacora.ps1`, the
     `bitacora` and `wiki` skills (directory symlinks) and
     `git/.gitignore_global`;
   - writes the `settings.json` keys `settings.sh` writes on mac/Linux
     (statusline, permissions from `permissions.json`, attribution, output
     style, fallback model, the PowerShell-tool env var, the bitácora hook),
     each only if absent. `terminalTitleFromRename` is deliberately not
     mirrored — no tmux here;
   - `rtk` from its release zip plus its versioned `config.toml`, copied;
   - `codebase-memory-mcp` — the **`-ui-`** release asset, sha256-checked, not
     the official installer (which ships the headless build). A stamp file
     `~/.local/bin/.codebase-memory-mcp-ui` records the installed version;
   - registers the `context7` and `open-knowledge` MCP endpoints from the env
     vars;
   - the `gh-stack` extension and skill, if `gh` / `npx` are present;
   - Nerd Fonts: Maple Mono NF and Monaspace NF via scoop, PlemolJP Console NF
     by direct download (per-user registry entry, no logout needed);
   - a Windows Terminal colour scheme generated from `ghostty/themes/<$WtTheme>`,
     the font `$WtFont`, and the keybindings `ctrl+shift+l` → `claude`,
     `ctrl+shift+y` → `claude --dangerously-skip-permissions`.

3. Bring the per-machine `~\.gitconfig` (identity, signing). Not versioned.

4. **Restart the terminal** (PATH changed) and **restart Claude Code**.

## Verify

```powershell
(Get-Item $HOME\.claude\CLAUDE.md).LinkType          # SymbolicLink; empty means it was copied
Get-ChildItem $HOME\.claude\skills | Select Name, LinkType
claude mcp list
rtk --version; rtk config                           # Config: <path> line — the toml lives there
codebase-memory-mcp --version; Get-Content $HOME\.local\bin\.codebase-memory-mcp-ui
[System.Windows.Media.Fonts]::SystemFontFamilies | Where-Object Source -match 'Maple|Monaspace|PlemolJP'
```

In Windows Terminal: Settings → Appearance → Font face shows what actually
resolved. A family that does not exist falls back **silently**, so check it by
eye once. `ctrl+shift+l` should type `claude` at the prompt.

## Re-run after a pull

```powershell
cd $HOME\dotfiles; git pull; .\install-windows.ps1
```

This script hand-replicates `claude/install/settings.sh`; CI fails when a
`settings.json` key exists on one side only, but nothing checks the *values*.
If a mac/Linux change looks missing here, that is where to look.

## Troubleshooting

- **`!! could not symlink …`.** Developer Mode is off. Enable it, re-run: the
  script replaces its own earlier copies with links (it deletes a copy whose
  content matches ours, never a file you edited).
- **`i scoop not found -- skipping Nerd Fonts`.** Optional. Install scoop in a
  non-admin shell and re-run:

  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned; irm get.scoop.sh | iex
  ```

- **Windows Terminal theme block skipped, "settings.json has // comments".**
  WT's file is JSONC and `ConvertFrom-Json` refuses comments. Remove the `//`
  lines by hand (or let WT rewrite the file once from its own Settings UI) and
  re-run. The script never regex-strips them — `"https://…"` would match.
- **Theme applied but colours did not change.** The block only overwrites
  `colorScheme` when the current value is a member of the family
  (`ghostty/themes/`). A scheme you picked by hand in the WT UI is reported and
  left alone. Switch it to the family in the UI once, then the installer owns it.
- **Google Sans Code looks like the fallback font.** On Windows the family is
  `Google Sans Code Monospace`, not `Google Sans Code`. The oracle is
  `[System.Windows.Media.Fonts]::SystemFontFamilies`, not GDI.
- **Graph UI on `localhost:9749` is dead** after `codebase-memory-mcp update`.
  The self-update pulls the headless build. Compare `--version` with the stamp
  file; re-run the installer to get the `-ui-` asset back.
- **`i context7: skipped` / `i open-knowledge: skipped`.** The `setx` vars are
  not visible in this terminal — it predates them. Open a new one, re-run.
- **Rotated token.** `claude mcp remove open-knowledge -s user`, then re-run.
- **A skill dir shows up twice or as `.backup`.** An old copy from a
  no-Developer-Mode run. Delete the `.backup.<ts>` directory under
  `~\.claude\skills\`; re-runs do not create new ones.

## Undo

Symlinks: delete them (`(Get-Item <path>).Delete()` — never `Remove-Item
-Recurse` on a directory symlink, it follows into the repo). Copies are beside
their `.backup.<ts>`. `settings.json` keys the script added can be removed by
hand; it never touches a key that already existed. scoop packages:
`scoop uninstall`. rtk and codebase-memory-mcp live in `~\.local\bin`.
