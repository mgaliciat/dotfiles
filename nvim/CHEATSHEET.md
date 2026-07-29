# nvim cheatsheet

Commands relevant to **this specific config**. For an exhaustive vim reference, use `:help` inside nvim.

> ⚠️ **This file is NOT complete.** It covers the most-used native stuff + the core of the config (LSP, telescope, gitsigns, conform, treesitter), but it's missing several plugins that arrived later: oil, neo-tree, flash, snacks, dap, ufo, glance, blink.cmp, dropbar, mini.bracketed, todo-comments, surround, render-markdown.
>
> In the meantime, **`../NVIM-CHEATSHEET.md` (repo root) is the more up-to-date of the two** — it started as a condensed version for reviewing AI diffs, but today it covers more plugins than this one. Start there.

`<leader>` = **spacebar**. `<CR>` = Enter. `<C-x>` = Ctrl+x. `<A-x>` = Alt+x. `<S-x>` = Shift+x.

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
| Close | `<leader>q` or `:q` |
| Force close everything | `<leader>Q` |
| Save and close | `:wq` or `ZZ` |
| Close without saving | `:q!` or `ZQ` |

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

---

## 2. Editing (native vim, essential)

### Text
- `i` / `a` — insert before / after the cursor
- `I` / `A` — insert at start / end of line
- `o` / `O` — new line below / above (enters insert)
- `r<char>` — replace 1 character
- `cw` — change word. `cc` — change line. `C` — change to end of line
- `dw` — delete word. `dd` — delete line. `D` — delete to end of line
- `x` — delete character. `X` — delete previous character
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

### Visual mode
- `v` / `V` / `<C-v>` — visual char / line / block
- `o` — jump to the other end of the selection
- In visual, every operator works: `d`, `y`, `c`, `>`, `<`
- `<` / `>` — indent (keeps the selection, see custom keymap)
- `p` — paste without yanking what was replaced (see custom keymap)
- `<A-j>` / `<A-k>` — move the selection up/down (see custom keymap)

### Registers (multiple clipboards)
- `"ayy` — yank the line into register `a`
- `"ap` — paste from register `a`
- `"+y` / `"+p` — yank / paste to the system clipboard (already set by default with `clipboard=unnamedplus`)
- `"_d` — delete without overwriting the current yank (e.g. `"_d` in visual)
- `:reg` — see all registers

---

## 3. Custom keymaps of this config

They all live in `lua/config/keymaps.lua` with their `desc` — you can also see them with which-key (press `<leader>` and wait).

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
| `<C-h>` | Split left |
| `<C-j>` | Split down |
| `<C-k>` | Split up |
| `<C-l>` | Split right |
| `<C-Arrow>` | Resize split |

### Buffers

| Shortcut | Action |
|---|---|
| `<S-l>` | Next buffer |
| `<S-h>` | Previous buffer |
| `<leader>bd` | Close current buffer |

### Moving lines

| Shortcut | Action |
|---|---|
| `<A-j>` (normal) | Move the current line down |
| `<A-k>` (normal) | Move the current line up |
| `<A-j>` / `<A-k>` (visual) | Move the selection |

### Improved visual

| Shortcut | Action |
|---|---|
| `<` / `>` (visual) | Indent keeping the selection |
| `p` (visual) | Paste without losing the yank |

### Diagnostics

| Shortcut | Action |
|---|---|
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |
| `<leader>cd` | Show the line's diagnostic |

### Accelerators (craftzdog style)

All of them are **accelerators within the vim model**, not Mac crutches. Designed so the yank register doesn't get polluted and editing is more efficient.

| Shortcut | Action |
|---|---|
| `<leader>p` (normal / visual) | Paste from **register 0** — always pastes the last yank, ignores deletes |
| `<leader>P` | Same but **before** the cursor |
| `<leader>d` (normal / visual) | Delete without polluting the register (to the black-hole `"_`) |
| `<leader>D` | Delete to EOL without polluting the register |
| `x` | Delete 1 char without polluting the register |
| `+` | Increment the number under the cursor (= `<C-a>`, smart via dial) |
| `<C-x>` | Decrement (smart via dial). `-` is not mapped: oil.nvim uses it for "parent dir" |

---

## 4. LSP — installed stack

| Language | LSP server | Notes |
|---|---|---|
| Go | `gopls` | full inlay hints, gofumpt + staticcheck on |
| TypeScript / JavaScript / React (.tsx) | `ts_ls` | a single server for the whole TS/JS ecosystem |
| Angular | `angularls` | takes the lead in Angular projects; ts_ls covers TS outside the project |
| Astro | `astro` | parses `.astro` with mixed frontmatter |
| Rust | `rust-analyzer` via `rustaceanvim` | does NOT go through lspconfig — its own plugin |
| PHP | `intelephense` | premium-tier without a license (~80% of features); supports projects up to 5MB |
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
| `go` | gopls | `brew install go` |
| `node` | ts_ls, angularls, astro, html, cssls, jsonls, yamlls, intelephense, emmet, bashls, marksman | you already have it (Claude Code requires it) |
| `python3` | basedpyright | macOS ships one; `pyenv` recommended for specific versions |
| `rustup` | rust-analyzer | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| `php` (optional) | intelephense validates paths | `brew install php` |

Mason downloads the rest on demand. `:Mason` to view/install/update.

**Check the LSP status in the current buffer:** `:LspInfo`

## LSP keymaps (active when a server is attached)

They're set automatically in any buffer with an active LSP.

| Shortcut | Action |
|---|---|
| `gd` | Goto definition — **Glance peek** if there are several results; jumps straight there if there's only one |
| `gD` | Goto declaration (direct jump, native LSP) |
| `gr` | References — Glance peek |
| `gi` | Goto implementation — Glance peek |
| `gt` | Goto type definition — Glance peek. **Careful:** in any buffer with LSP, `gt` is NOT "next tab" (`gT` still works) |
| `K` | If the cursor is over a closed fold, opens the ufo peek; if not, hover docs |
| `<leader>rn` | Rename symbol with **IncRename** — live preview of the call sites; the cmdline stays open for editing |
| `<leader>ca` | Code action (quick fix, refactor) |
| `<leader>cs` | Signature help |
| `<leader>cl` | Code lens (run) |
| `<leader>ch` | Toggle inlay hints (**they come enabled** by default) |

### Treesitter movement (across functions / classes)

| Shortcut | Action |
|---|---|
| `]f` / `[f` | Next / previous function |
| `]c` / `[c` | Next / previous class |

---

## 5. Telescope (fuzzy finder) — `<leader>f*`

| Shortcut | Action |
|---|---|
| `<leader>ff` | Find files (in cwd) |
| `<leader>fg` | Live grep (search text in the project) |
| `<leader>fb` | Open buffers |
| `<leader>fr` | Recent files |
| `<leader>fh` | Help tags (nvim docs) |
| `<leader>fc` | Available commands |
| `<leader>fk` | Active keymaps |
| `<leader>fd` | Workspace diagnostics |
| `<leader>fs` | Symbols in the current document |
| `<leader>fS` | Workspace symbols |
| `<leader>/` | Search inside the current buffer |

**Inside Telescope:**
- `<C-j>` / `<C-k>` — navigate results (same as `<C-n>` / `<C-p>`)
- `<CR>` — open
- `<C-x>` — open in a horizontal split
- `<C-v>` — open in a vertical split
- `<C-t>` — open in a tab
- `<Esc>` — close (no double escape)

---

## 6. Git — `<leader>g*` (gitsigns)

| Shortcut | Action |
|---|---|
| `]h` | Next hunk |
| `[h` | Previous hunk |
| `<leader>gs` | Stage hunk |
| `<leader>gr` | Reset hunk |
| `<leader>gp` | Preview hunk |
| `<leader>gb` | Toggle inline blame |
| `<leader>gd` | Diff the current buffer |

Gutter signs:
- `│` added / modified line
- `_` / `‾` deleted line
- `~` changed-and-deleted line
- `┆` untracked file

---

## 7. Formatting — `<leader>cf` (conform.nvim)

| Shortcut | Action |
|---|---|
| `<leader>cf` (normal / visual) | Format the buffer or selection |

**Automatic format on save** (defined in `plugins/conform.lua`) for:
- Go (`goimports` + `gofumpt`)
- Rust (`rustfmt`)
- Lua (`stylua`)
- Python (`ruff_organize_imports` + `ruff_format`)

**Available but NOT on-save** (run them manually with `<leader>cf`):
- TS/JS/JSON/YAML/MD → `prettierd` / `prettier`
- PHP → `php_cs_fixer`
- SQL → `sqlfluff`
- shell → `shfmt`

Mason installs the formatters on first use. If one is missing: `:Mason` → find it → `i` to install.

---

## 8. Folding (nvim-ufo)

The folds are provided by **nvim-ufo** (treesitter → indent chain), not by native folding. The `zR`/`zM`/`zr`/`zm` below are ufo functions.

| Shortcut | Action |
|---|---|
| `za` | Toggle the current fold |
| `zM` | Close all folds |
| `zR` | Open all folds |
| `zm` / `zr` | Close / open one fold level |
| `zc` / `zo` | Close / open fold |
| `zj` / `zk` | Next / previous fold |
| `K` | Peek the closed fold under the cursor (if there's no fold, LSP hover) |

By default you start with **everything expanded**, because of `foldlevel = 99` / `foldlevelstart = 99` in `options.lua`. Careful: `foldenable` is **`true`** — ufo needs it to render its virtual text.

---

## 9. Search and replace

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

## 10. Splits and tabs

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
- `gT` — previous tab. (`gt` and `<num>gt` do **not** work for navigating tabs: in any buffer with LSP, `gt` is clobbered by Glance type-definition, and the count doesn't avoid the mapping. Use `:tabnext` / `:tabn N`.)
- `<num>gt` — go to tab N

---

## 11. Maintenance

### Plugins (lazy.nvim)
- `:Lazy` — open the plugin manager UI
- `:Lazy sync` — update and install pending plugins
- `:Lazy update` — update plugins
- `:Lazy clean` — remove plugins that aren't listed
- `:Lazy profile` — see each plugin's load time
- `:Lazy log` — log of recent changes

### LSP servers (mason)
- `:Mason` — UI to install/uninstall LSPs, formatters, linters
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
- `:checkhealth lazy` — lazy only
- `:checkhealth mason` — mason only
- `:messages` — message history (useful after an error that flashed by)

---

## 12. which-key

If you forget a shortcut, press just `<leader>` and wait ~400ms. A popup appears with all the groups:

- `<leader>b` → buffer
- `<leader>c` → code (LSP / debug)
- `<leader>cg` → go debug
- `<leader>f` → find (telescope)
- `<leader>g` → git
- `<leader>r` → rename

Also: `<leader>?` shows only the keymaps active in the current buffer.

---

## 13. Useful tips

- **Macros**: `q<letter>` start recording, `q` stop, `@<letter>` run. `@@` repeats the last one.
- **Marks**: `m<letter>` marks a position, `'<letter>` jumps to the line, `` `<letter> `` jumps to the exact character. Uppercase marks (`mA`) are global across files.
- **Increment / decrement**: `<C-a>` adds 1 to the number under the cursor, `<C-x>` subtracts 1.
- **`gx`** — opens the URL under the cursor in the browser.
- **`gu` / `gU`** — lowercase / uppercase (with a motion, e.g. `guw` word to lowercase).
- **`>ip` / `<ip`** — indent / unindent paragraph.
- **`==`** — re-indent the line according to LSP/treesitter.
- **`gd` on LSP attach** = goto definition. Much more useful than the native `gd`.
- **`<C-r>=` in insert** — inline calculator (you type `5*7` Enter, it inserts `35`).

---

## 14. When something doesn't work

| Symptom | Diagnosis |
|---|---|
| A shortcut doesn't respond | `:checkhealth which-key` or `:WhichKey <leader>a` to see if it's registered |
| LSP doesn't complete | `:LspInfo` shows whether it's running. `:Mason` to check the server is installed |
| Odd color | `:Inspect` under the cursor shows which highlight group applies it |
| Language without highlight | `:TSInstall <lang>` to install the parser |
| A plugin doesn't load | `:Lazy` and look for the plugin — check for an installation error |
| Everything broke | `:Lazy restore` goes back to the lockfile (`lazy-lock.json`) |
