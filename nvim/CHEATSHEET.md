# nvim cheatsheet

Shortcuts for **this specific config**. For an exhaustive vim reference, use `:help` inside nvim.

`<leader>` = **space**. Leave insert: **`jk`**. `<CR>` = Enter. `<C-x>` = Ctrl+x. `<A-x>` = Alt+x. `<S-x>` = Shift+x.

Forgot a key? **`<leader>fk`** searches every active keymap (telescope); **`<leader>`** alone (wait ~400ms) opens which-key with the group menu; **`<leader>?`** shows only the keymaps active in the current buffer.

Every keymap below is taken from `lua/config/keymaps.lua` (native) or the `keys = {}` block of its plugin in `lua/plugins/*.lua`.

---

## 0. Base concepts

### Modes

| Mode | How to enter | What for |
|---|---|---|
| **Normal** | `<Esc>` or `jk` | Default. Navigate, commands. You don't type text. |
| **Insert** | `i`, `a`, `o`, `I`, `A`, `O` | Type text. |
| **Visual** | `v` (char), `V` (line), `<C-v>` (block) | Select. |
| **Command** | `:` | Commands `:w`, `:Telescope`, etc. |
| **Replace** | `R` | Overwrites instead of inserting. |
| **Terminal** | `:terminal` | Embedded terminal. `<C-\><C-n>` to go back to normal. |

### Quit / save

| Action | Shortcut |
|---|---|
| Save | `<leader>w` or `:w` |
| Close window | `<leader>q` or `:q` |
| Force close everything | `<leader>Q` (`:qa!`) |
| Save and close | `:wq` or `ZZ` |
| Close without saving | `:q!` or `ZQ` |
| Close a utility buffer (help, man, quickfix, `:checkhealth`, `:LspInfo`) | `q` |

---

## 1. Movement (native vim, essential)

### Character / line
- `h j k l` — left, down, up, right
- `w` / `b` — next / previous word
- `W` / `B` — next / previous WORD (space-separated, ignores punctuation)
- `e` — end of word
- `0` / `^` — start of line / first non-blank
- `$` — end of line
- `f<char>` / `F<char>` — jump to `<char>` in the line (forward / backward)
- `t<char>` — up to just before `<char>`
- `;` / `,` — repeat last `f`/`t` (forward / backward)

### File
- `gg` / `G` — first / last line
- `<num>G` or `:<num>` — go to line N (e.g. `42G`)
- `<C-u>` / `<C-d>` — scroll half a page up / down
- `<C-b>` / `<C-f>` — scroll a full page up / down
- `zz` — center the current line on screen
- `zt` / `zb` — current line to top / bottom

### Jumps
- `%` — jump to the matching `()` / `{}` / `[]`
- `*` / `#` — search the word under the cursor forward / backward
- `n` / `N` — next / previous search match
- `<C-o>` / `<C-i>` — back / forward in the jump history
- `<C-^>` — toggle previous buffer

### Quick jumps (flash.nvim)

| Shortcut | Action |
|---|---|
| `s` + chars (normal / visual / operator) | Jump anywhere on screen — type the target, labels appear, press the label |
| `S` (normal / operator) | Jump / select by **treesitter node** (expands with `;`, shrinks with `,`). In visual `S` belongs to nvim-surround |
| `r` (operator only) | Remote flash: `yr` + jump → yank there without moving the cursor |
| `R` (operator / visual) | Treesitter search: pick a node anywhere on screen |

### Bracket navigation `]x` / `[x` (next / previous)

| Keys | Target | Plugin |
|---|---|---|
| `]d` / `[d` | Diagnostic | native (`keymaps.lua`) |
| `]h` / `[h` | Git hunk | gitsigns (LSP-independent, any git buffer) |
| `]f` / `[f` | Function start | treesitter textobjects |
| `]c` / `[c` | Class start | treesitter textobjects |
| `]t` / `[t` | TODO / FIX / HACK comment | todo-comments |
| `]b` / `[b` | Buffer | mini.bracketed |
| `]x` / `[x` | Merge-conflict marker | mini.bracketed |
| `]i` / `[i` | Indent-level change | mini.bracketed |
| `]j` / `[j` | Jumplist entry | mini.bracketed |
| `]l` / `[l` | Location-list entry | mini.bracketed |
| `]o` / `[o` | Recent file (oldfile) | mini.bracketed |
| `]u` / `[u` | Undo state (linearized undo tree) | mini.bracketed |
| `]y` / `[y` | **Yank history** — after a `p`, cycles through earlier yanks in place | mini.bracketed |

mini.bracketed's `file`, `comment`, `quickfix`, `window` and `treesitter` targets are **disabled** on purpose so they don't shadow the rows above.

---

## 2. Editing (native vim, essential)

### Text
- `i` / `a` — insert before / after the cursor
- `I` / `A` — insert at start / end of line
- `o` / `O` — new line below / above (enters insert)
- `r<char>` — replace 1 character
- `cw` — change word. `cc` — change line. `C` — change to end of line
- `dw` — delete word. `dd` — delete line. `D` — delete to end of line
- `x` — delete character (**black-hole** in this config, see §3). `X` — delete previous character
- `yy` — yank (copy) line. `Y` — yank to end of line
- `p` / `P` — paste after / before
- `u` — undo. `<C-r>` — redo
- `.` — repeat last change
- `J` — join the next line with the current one

### Text objects (combine with `d`, `c`, `y`, `v`)
- `iw` / `aw` — inner word / a word (includes the space)
- `i"` / `a"` — inner / around quotes (same with `'` and `` ` ``)
- `i(` / `a(` — inner / around parentheses (same with `[`, `{`, `<`)
- `it` / `at` — inner / around HTML tag
- `ip` / `ap` — inner / around paragraph
- `if` / `af` — inner / around **function** (treesitter)
- `ic` / `ac` — inner / around **class** (treesitter)
- `ia` / `aa` — inner / around **argument** (treesitter)

Examples: `daw` deletes a word + space. `ci"` changes the content between quotes. `vaf` selects a whole function.

### Surround (nvim-surround) — a new operator, no leader keys

| Keys | Action | Example |
|---|---|---|
| `ys<motion><char>` | Wrap a motion / text object | `ysiw"` → wrap word in `"` |
| `yss<char>` | Wrap the whole line | `yss)` |
| `cs<old><new>` | Change delimiters | `cs"'` → `"` becomes `'` |
| `ds<char>` | Delete delimiters | `ds(` |
| `S<char>` (visual) | Wrap the selection | select, `S}` |

Closing char (`)`, `}`, `]`) wraps tight; opening char (`(`, `{`, `[`) adds a space inside. `t` asks for an HTML tag.

### Visual mode
- `v` / `V` / `<C-v>` — visual char / line / block
- `o` — jump to the other end of the selection
- In visual, every operator works: `d`, `y`, `c`, `>`, `<`
- `<` / `>` — indent **and keep the selection** (custom)
- `p` — paste **without losing the yank** (custom)
- `<A-j>` / `<A-k>` — move the selection down / up (custom)

### Registers (multiple clipboards)
- `"ayy` — yank the line into register `a`
- `"ap` — paste from register `a`
- `"+y` / `"+p` — system clipboard (already the default via `clipboard=unnamedplus`)
- `"_d` — delete without overwriting the current yank
- `"0p` — paste the last **yank** even after deletes (what `<leader>p` does)
- `:reg` — see all registers

### Increment / decrement (dial.nvim)

| Shortcut | Action |
|---|---|
| `+` or `<C-a>` (normal) | Smart increment: numbers, `true↔false`, dates (`%Y-%m-%d`, `%Y/%m/%d`), semver, `let↔const` |
| `<C-x>` (normal) | Smart decrement |
| `<C-a>` / `<C-x>` (visual) | Same over a selection |

`-` is **not** decrement: oil.nvim owns `-` (open parent directory).

---

## 3. Custom keymaps of this config

All in `lua/config/keymaps.lua` with a `desc`, so they show in which-key and `<leader>fk`.

### General

| Shortcut | Action |
|---|---|
| `jk` (in insert) | Exit to normal (faster than `<Esc>`) |
| `<Esc>` (in normal) | Clear search highlight |
| `<leader>w` | Save |
| `<leader>q` | Close window |
| `<leader>Q` | Force close everything |

### Navigation between splits

| Shortcut | Action |
|---|---|
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | Move to the split left / down / up / right |
| `<C-Up>` / `<C-Down>` | Resize height ±2 |
| `<C-Left>` / `<C-Right>` | Resize width ∓2 |

### Buffers

| Shortcut | Action |
|---|---|
| `<S-l>` / `<S-h>` | Next / previous buffer |
| `<leader>bd` | Close current buffer |

### Moving lines

| Shortcut | Action |
|---|---|
| `<A-j>` / `<A-k>` (normal) | Move the current line down / up (re-indents) |
| `<A-j>` / `<A-k>` (visual) | Move the selection down / up |

### Diagnostics

| Shortcut | Action |
|---|---|
| `[d` / `]d` | Previous / next diagnostic |
| `<leader>cd` | Show the line's diagnostic in a float |
| `<leader>fd` | All workspace diagnostics (telescope) |

### Accelerators (craftzdog style)

**Accelerators within the vim model**, not Mac crutches — designed so the yank register never gets polluted.

| Shortcut | Action |
|---|---|
| `<leader>p` (normal / visual) | Paste from **register 0** — always the last yank, ignores deletes |
| `<leader>P` | Same, **before** the cursor |
| `<leader>d` (normal / visual) | Delete to the black-hole `"_` — your yank survives |
| `<leader>D` | Delete to end of line, black-hole |
| `x` | Delete 1 char, black-hole |
| `+` | Increment (chains to dial's `<C-a>`) |

---

## 4. Files and folders

### oil.nvim — edit the directory as text (pure vim)

| Key | Action |
|---|---|
| `-` | Open the current file's directory (also the parent, from inside oil) |
| `<leader>e` | Open oil |
| `o` / `i` + name + `:w` | **Create file** (`foo.lua`) |
| name with trailing `/` + `:w` | **Create folder** (`utils/`) |
| `foo/bar/baz.lua` + `:w` | Nested folders + file in one go |
| edit the line + `:w` | Rename |
| `dd` + `:w` | Delete |
| `<CR>` | Open file / enter directory |
| `q` | Close |

`:w` applies the edits to the filesystem (with a preview before confirming). Hidden files are shown.

### neo-tree — IDE-style sidebar

| Key | Action |
|---|---|
| `<leader>n` | Toggle the tree |
| `<leader>N` | Reveal the current file in the tree |
| `a` | **Add** — `foo.lua` file · `foo/` folder · `a/b/c.lua` full path |
| `d` / `r` | Delete / rename |
| `c` / `m` | Copy / move |
| `l` / `h` | Open / collapse node |
| `q` | Close panel |

Hidden and gitignored files are visible; the tree follows the current file and watches the filesystem (git pull, etc.).

---

## 5. Telescope (fuzzy finder) — `<leader>f*`

| Shortcut | Action |
|---|---|
| `<leader>ff` | Find files (in cwd) |
| `<leader>fg` | Live grep (search text in the project) |
| `<leader>/` | Search inside the current buffer |
| `<leader>fb` | Open buffers |
| `<leader>fr` | Recent files |
| `<leader>fs` / `<leader>fS` | Symbols in the document / workspace |
| `<leader>fd` | Workspace diagnostics |
| `<leader>ft` | TODO / FIX / HACK / NOTE comments (todo-comments) |
| `<leader>fc` | Available commands |
| `<leader>fk` | Active keymaps |
| `<leader>fh` | Help tags (nvim docs) |

**Inside Telescope:**
- `<C-j>` / `<C-k>` — navigate results (same as `<C-n>` / `<C-p>`)
- `<CR>` — open
- `<C-x>` / `<C-v>` / `<C-t>` — open in a horizontal split / vertical split / tab
- `<Esc>` — close (no double escape)

---

## 6. LSP

### Installed stack

| Language | LSP server | Notes |
|---|---|---|
| Go | `gopls` | full inlay hints, gofumpt + staticcheck on, code lenses |
| TypeScript / JavaScript / React (.tsx) | `ts_ls` | one server for the whole TS/JS ecosystem |
| Angular | `angularls` | takes the lead in Angular projects; ts_ls covers TS outside the project |
| Astro | `astro` | parses `.astro` with mixed frontmatter |
| Rust | `rust-analyzer` via `rustaceanvim` | does NOT go through lspconfig — its own plugin (§7) |
| PHP | `intelephense` | premium-tier without a license (~80% of features); projects up to 5MB |
| Python | `basedpyright` + `ruff` | basedpyright = type checking; ruff = linter + formatter + import sorter |
| YAML | `yamlls` | automatic schemas via SchemaStore (k8s, GitHub Actions, etc.) |
| JSON | `jsonls` | automatic schemas via SchemaStore (package.json, tsconfig, etc.) |
| HTML | `html` + `emmet_ls` | emmet expands `div.foo>span` → markup |
| CSS / SCSS / Less | `cssls` + `emmet_ls` | |
| Bash / sh / zsh | `bashls` | uses shellcheck if it's in PATH |
| Lua | `lua_ls` | knows nvim's APIs for your config |
| Markdown | `marksman` | links, refs, headings |

**SYSTEM prerequisites** (mason does NOT install them):

| Toolchain | For which LSP | How to install |
|---|---|---|
| `go` | gopls, delve | `brew install go` |
| `node` | ts_ls, angularls, astro, html, cssls, jsonls, yamlls, intelephense, emmet, bashls, marksman | you already have it (Claude Code requires it) |
| `python3` | basedpyright | macOS ships one; `pyenv` for specific versions |
| `rustup` | rust-analyzer | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| `php` (optional) | intelephense validates paths | `brew install php` |

Mason downloads the rest on demand. `:Mason` to view/install/update. `:LspInfo` shows the LSP status in the current buffer.

### LSP keymaps (buffer-local, set on `LspAttach`)

| Shortcut | Action |
|---|---|
| `gd` | Goto definition — **Glance peek** if there are several results; direct jump if only one |
| `gD` | Goto declaration (direct jump, native LSP) |
| `gr` | References — Glance peek |
| `gi` | Goto implementation — Glance peek |
| `gt` | Goto type definition — Glance peek. **Careful:** in any buffer with LSP, `gt` is NOT "next tab" (`gT` still works) |
| `K` | Over a closed fold: ufo peek. Otherwise: hover docs |
| `<leader>rn` | Rename symbol with **IncRename** — live preview at every call site; the cmdline stays open for editing |
| `<leader>ca` (normal / visual) | Code action (quick fix, imports, refactor) |
| `<leader>cs` | Signature help |
| `<leader>cl` | Run the code lens on the current line (go test, go generate…) — only when the server offers lenses |
| `<leader>ch` | Toggle inlay hints (**enabled by default** where supported: Go, Rust, TS, Python) |

**Inside a Glance window:** `<CR>` jump · `o` jump and close · `<Tab>` / `<S-Tab>` next / previous location · `<C-v>` / `<C-x>` / `<C-t>` open in vsplit / split / tab · `<leader>l` toggle the list · `q` / `<Esc>` close.

### Completion (blink.cmp, `default` preset)

| Key | Action |
|---|---|
| `<C-space>` | Open the menu / toggle docs |
| `<C-n>` / `<C-p>` | Next / previous item |
| `<CR>` | Accept |
| `<Tab>` / `<S-Tab>` | Snippet jump forward / back |
| `<C-e>` | Cancel |

Sources: LSP, path, snippets, buffer. Signature help pops up automatically while typing arguments.

---

## 7. Rust (rustaceanvim)

Registers itself on `.rs` buffers; **not** in the lspconfig loop. Same `gd` / `gr` / `K` / `<leader>ca` keymaps as any LSP buffer, plus its own commands (no default keymaps):

| Command | Action |
|---|---|
| `:RustLsp runnables` | Pick a target / test to run |
| `:RustLsp debuggables` | Same, under the debugger |
| `:RustLsp expandMacro` | Expand the macro under the cursor |
| `:RustLsp explainError` | Long-form explanation of the error under the cursor |
| `:RustLsp openCargo` | Jump to `Cargo.toml` |

Clippy runs on save; lifetime-elision inlay hints are always on.

---

## 8. Git — `<leader>g*` (gitsigns)

| Shortcut | Action |
|---|---|
| `]h` / `[h` | Next / previous hunk |
| `<leader>gs` | Stage hunk |
| `<leader>gr` | Reset hunk (discard the change) |
| `<leader>gp` | Preview hunk |
| `<leader>gb` | Toggle inline blame for the current line |
| `<leader>gd` | Diff the current buffer against the index |

Gutter signs: `│` added / modified · `_` / `‾` deleted · `~` changed-and-deleted · `┆` untracked.

Full git UI: **`Alt+g`** in tmux opens lazygit in a popup (no prefix). `prefix + g` is something else — the IDE layout.

---

## 9. Formatting — `<leader>cf` (conform.nvim)

| Shortcut | Action |
|---|---|
| `<leader>cf` (normal / visual) | Format the buffer or the selection (falls back to the LSP formatter) |

**Automatic format on save** (`plugins/conform.lua`) for:
- Go (`goimports` + `gofumpt`)
- Rust (`rustfmt`)
- Lua (`stylua`)
- Python (`ruff_organize_imports` + `ruff_format`)

**Available but NOT on save** (run manually with `<leader>cf`):
- TS/JS/JSON/YAML/MD/HTML/CSS/Astro → `prettierd` / `prettier`
- PHP → `php_cs_fixer`
- SQL → `sqlfluff`
- shell → `shfmt`

Mason installs the formatters on first use. If one is missing: `:Mason` → find it → `i` to install. `:ConformInfo` shows which formatter applies to the current buffer.

---

## 10. Debugging (nvim-dap + dap-ui, Go via delve)

| Shortcut | Action |
|---|---|
| `<F5>` | Continue / start |
| `<F10>` | Step over |
| `<F11>` | Step into |
| `<F12>` | Step out |
| `<leader>cb` | Toggle breakpoint |
| `<leader>cB` | Conditional breakpoint (prompts for the condition) |
| `<leader>cu` | Toggle the debug UI (scopes, watches, stacks, repl) |
| `<leader>cR` | Re-run the last debug session |
| `<leader>ct` | Terminate the session |
| `<leader>cgt` (Go only) | Debug the nearest test |
| `<leader>cgT` (Go only) | Debug the last test again |

The UI opens on attach/launch and closes when the session ends. `delve` is installed by mason-nvim-dap; other adapters go in its `ensure_installed`.

---

## 11. Folding (nvim-ufo)

Folds come from **nvim-ufo** (treesitter → indent chain), not native folding. `zR` / `zM` / `zr` / `zm` are ufo functions.

| Shortcut | Action |
|---|---|
| `za` | Toggle the current fold |
| `zM` / `zR` | Close / open all folds |
| `zm` / `zr` | Close / open one fold level |
| `zc` / `zo` | Close / open fold |
| `zj` / `zk` | Next / previous fold |
| `K` | Peek the closed fold under the cursor (no fold → LSP hover) |

Everything starts **expanded** (`foldlevel = 99`). `foldenable` stays `true` — ufo needs it to render its virtual text.

---

## 12. UI and focus

| Shortcut / command | Plugin | What |
|---|---|---|
| `<leader>z` | snacks.zen | Zen mode: centers the buffer, hides statusline / signs / diagnostics |
| `<leader>Z` | snacks.zen | Zoom the current window only |
| `<leader>h` | dropbar | Interactive breadcrumb picker (winbar): navigate path → symbol and jump |
| `<leader>cm` | render-markdown | Toggle in-buffer markdown rendering |
| `:Noice` / `:Noice last` | noice | Message history / the last message (cmdline and popups are noice too) |
| `:Snacks.dashboard()` | snacks.dashboard | Splash screen when opening nvim with no args — `f` files, `g` grep, `r` recent, `n` new, `c` config, `L` Lazy, `q` quit |

Also on: snacks indent guides with scope highlight, subtle smooth scroll, incline (per-window filename floats), lualine, highlight-colors (inline `#hex` swatches).

---

## 13. Search and replace

### Search
- `/<pattern>` — search forward
- `?<pattern>` — search backward
- `n` / `N` — next / previous
- `*` / `#` — search the word under the cursor
- `<Esc>` — clear the highlight (custom)

### Replace `:substitute`
- `:s/old/new/` — first occurrence in the line
- `:s/old/new/g` — all in the line
- `:%s/old/new/g` — all in the file
- `:%s/old/new/gc` — all in the file with confirmation
- `:'<,'>s/old/new/g` — in the visual selection

Useful flags: `c` confirm, `i` case-insensitive, `I` case-sensitive.

---

## 14. Splits and tabs

### Splits
- `:split` / `:sp` or `<C-w>s` — horizontal split
- `:vsplit` / `:vsp` or `<C-w>v` — vertical split
- `<C-w>q` or `:close` — close split
- `<C-w>o` — only this split (closes the rest)
- `<C-w>=` — equalize sizes
- `<C-w>x` — swap with the next split
- Navigation: `<C-h/j/k/l>` (custom)
- Resize: `<C-Arrow>` (custom)

### Tabs
- `:tabnew` — new tab
- `:tabclose` — close tab
- `gT` — previous tab. `gt` and `<num>gt` do **not** work in a buffer with LSP: `gt` is Glance type-definition there, and the count doesn't avoid the mapping. Use `:tabnext` / `:tabn N`.

---

## 15. Maintenance

### Plugins (lazy.nvim)
- `:Lazy` — open the plugin manager UI
- `:Lazy sync` — update and install pending plugins
- `:Lazy update` — update plugins
- `:Lazy clean` — remove plugins that aren't listed
- `:Lazy profile` — see each plugin's load time
- `:Lazy log` — log of recent changes
- `:Lazy restore` — go back to the lockfile (`lazy-lock.json`)

### LSP servers (mason)
- `:Mason` — UI to install/uninstall LSPs, formatters, linters, debug adapters
- `:MasonInstall <name>` — install a specific one
- `:LspInfo` — LSP status in the current buffer
- `:LspRestart` — restart the buffer's LSP

### Treesitter
- `:TSUpdate` — update parsers
- `:TSInstall <lang>` — install a language's parser
- `:Inspect` — show the highlight groups under the cursor
- `:InspectTree` — open the buffer's AST

### Diagnosis
- `:checkhealth` — general check (nvim, plugins, mason)
- `:checkhealth lazy` / `:checkhealth mason` — one component
- `:messages` — message history (`:Noice` is the richer version)

---

## 16. which-key groups

Press `<leader>` and wait ~400ms (`timeoutlen`):

- `<leader>b` → buffer
- `<leader>c` → code (LSP / format / debug)
- `<leader>cg` → go debug
- `<leader>f` → find (telescope)
- `<leader>g` → git
- `<leader>r` → rename

---

## 17. Useful tips

- **Macros**: `q<letter>` start recording, `q` stop, `@<letter>` run. `@@` repeats the last one.
- **Marks**: `m<letter>` marks a position, `'<letter>` jumps to the line, `` `<letter> `` jumps to the exact character. Uppercase marks (`mA`) are global across files.
- **`gx`** — opens the URL under the cursor in the browser.
- **`gu` / `gU`** — lowercase / uppercase (with a motion, e.g. `guw`).
- **`>ip` / `<ip`** — indent / unindent paragraph.
- **`==`** — re-indent the line according to LSP/treesitter.
- **`<C-r>=` in insert** — inline calculator (`5*7` Enter inserts `35`).
- **Reviewing a generated diff**: `]h` through the hunks, `<leader>gp` to see the old text, `<leader>gr` to throw a hunk away, `gd` / `gr` (Glance) to check a symbol without leaving the file, `<leader>fd` for everything the LSP disagrees with.

---

## 18. When something doesn't work

| Symptom | Diagnosis |
|---|---|
| A shortcut doesn't respond | `<leader>fk` to see if it's registered; `:WhichKey <leader>a` for a group |
| LSP doesn't complete | `:LspInfo` shows whether it's running. `:Mason` to check the server is installed |
| Odd color | `:Inspect` under the cursor shows which highlight group applies it |
| Language without highlight | `:TSInstall <lang>` to install the parser |
| A plugin doesn't load | `:Lazy` and look for the plugin — check for an installation error |
| Format on save did nothing | `:ConformInfo` — the formatter may not be installed (`:Mason`) |
| Everything broke | `:Lazy restore` goes back to the lockfile (`lazy-lock.json`) |
