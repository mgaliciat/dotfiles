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
- `io` / `ao` — inner / around **block / conditional / loop** (treesitter)
- `iq` / `aq` — inner / around **any quote** (whichever of `"` `'` `` ` `` is closest)
- `ib` / `ab` — inner / around **any bracket** (`()` `[]` `{}`)
- `i?` / `a?` — prompts for the two delimiters

All of these come from mini.ai, which also adds two prefixes: **`n`** for the *next* object and **`l`** for the *last* one, without moving the cursor first — `cin"` changes the next string on the line, `dal(` deletes the previous call's parens, `yinf` yanks the next function. Counts work: `v2af` selects the second enclosing function.

Examples: `daw` deletes a word + space. `ci"` changes the content between quotes. `vaf` selects a whole function. `ciq` changes the string under the cursor whatever quote it uses.

### Surround (nvim-surround) — a new operator, no leader keys

| Keys | Action | Example |
|---|---|---|
| `ys<motion><char>` | Wrap a motion / text object | `ysiw"` → wrap word in `"` |
| `yss<char>` | Wrap the whole line | `yss)` |
| `cs<old><new>` | Change delimiters | `cs"'` → `"` becomes `'` |
| `ds<char>` | Delete delimiters | `ds(` |
| `S<char>` (visual) | Wrap the selection | select, `S}` |

Closing char (`)`, `}`, `]`) wraps tight; opening char (`(`, `{`, `[`) adds a space inside. `t` asks for an HTML tag.

### Auto-pairs, auto-tags, comments (no keys to learn)

- **mini.pairs** — typing `(` `[` `{` `"` `'` `` ` `` inserts the closer; `<BS>` between a pair deletes both, `<CR>` between `{}` opens a block. It skips pairing when the next char is a word char or the same closer, inside strings/comments (treesitter), and when the line is already unbalanced. Typing the closer over an existing one just moves past it.
- **nvim-ts-autotag** — in html / tsx / jsx / astro / vue / svelte / xml, `<div>` inserts `</div>` and renaming one side of a tag renames the other. Typing `</` does not auto-complete (deliberate: it collides with closing an outer tag by hand).
- **`gc` is context-aware** — native commenting (`gcc` line, `gc<motion>`, `gc` in visual) picks the comment syntax from the treesitter node under the cursor, so in a `.astro` or `.tsx` the JS half gets `//` and the markup half `<!-- -->` / `{/* */}`.

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

Rendering: every line shows a short `●` at the right, except the line the cursor is on, which shows the full multi-line message underneath (`virtual_lines`). Move the cursor onto an error to read the whole rustc / tsc text without `<leader>cd`.

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

### harpoon — the task's hot files

A per-project list of the handful of files you keep bouncing between, by slot number. Buffers (`<S-h>`/`<S-l>`) walk everything in order and recent files are history; this is intent. Marks persist per cwd.

| Key | Action |
|---|---|
| `<leader>m` | Mark the current file (appends to the list) |
| `<leader>M` | The list as an editable buffer: reorder lines to renumber, delete a line to unmark, `q` saves and closes |
| `<leader>1` … `<leader>4` | Jump to slot 1–4 |

No `]h`/`[h` cycling — gitsigns owns those for hunks.

### Sessions — `<leader>S*` (persistence)

One session per cwd and git branch: buffers, splits, folds, cursor positions. Saved automatically on exit once at least one real file is open; **never restored automatically** — `nvim` alone still lands on the dashboard.

| Shortcut | Action |
|---|---|
| `<leader>Sr` or `s` on the dashboard | Restore the session for this directory |
| `<leader>Sl` | Restore the most recent session, whatever the directory |
| `<leader>Ss` | Pick a session from the list |
| `<leader>Sd` | Don't save this session on exit (keeps the one on disk) |

---

## 5. Telescope (fuzzy finder) — `<leader>f*`

| Shortcut | Action |
|---|---|
| `<leader>ff` | Find files (in cwd) |
| `<leader>fg` | Live grep — rg flags allowed inline: `foo -g *.go`, `foo src/`, `-w foo`, `"two words"`. A bare word is auto-quoted |
| `<leader>fw` (normal / visual) | Grep the word under the cursor / the selection, project-wide |
| `<leader>fG` | Live grep rooted at the current file's directory (monorepos) |
| `<leader>fR` | Resume the last picker with its prompt and selection |
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
- `<C-q>` — send the results to the quickfix list
- `<C-g>` (live grep only) — quote what you typed and append ` --iglob ` to narrow by file
- `<Esc>` — close (no double escape)

All rg-backed pickers see dotfiles (`--hidden`); `.git/`, `node_modules`, `vendor`, `target`, `dist`, `build` stay out.

---

## 6. LSP

### Installed stack

| Language | LSP server | Notes |
|---|---|---|
| Go | `gopls` | full inlay hints, gofumpt + staticcheck on, code lenses |
| TypeScript / JavaScript / React (.tsx) | `ts_ls` | one server for the whole TS/JS ecosystem |
| JS / TS / Vue / Svelte / Astro (rules) | `eslint` | the project's eslint config as diagnostics; no config → silent. `:LspEslintFixAll` or the "fix all" code action |
| Angular | `angularls` | takes the lead in Angular projects; ts_ls covers TS outside the project |
| Astro | `astro` | parses `.astro` with mixed frontmatter |
| Rust | `rust-analyzer` via `rustaceanvim` | does NOT go through lspconfig — its own plugin (§7) |
| PHP | `intelephense` | premium-tier without a license (~80% of features); projects up to 5MB |
| Python | `basedpyright` + `ruff` | basedpyright = type checking; ruff = linter + formatter + import sorter |
| YAML | `yamlls` | automatic schemas via SchemaStore (k8s, GitHub Actions, etc.) |
| JSON | `jsonls` | automatic schemas via SchemaStore (package.json, tsconfig, etc.) |
| HTML | `html` + `emmet_ls` | emmet expands `div.foo>span` → markup |
| CSS / SCSS / Less | `cssls` + `emmet_ls` | |
| Bash / sh / zsh | `bashls` | runs shellcheck (mason installs it; bash/sh only — shellcheck has no zsh dialect) |
| Lua | `lua_ls` | knows nvim's APIs for your config |
| Markdown | `marksman` | links, refs, headings |

**SYSTEM prerequisites** (mason does NOT install them):

| Toolchain | For which LSP | How to install |
|---|---|---|
| `go` | gopls, gotestsum | `brew install go` |
| `node` | ts_ls, angularls, astro, html, cssls, jsonls, yamlls, intelephense, emmet, bashls, marksman | you already have it (Claude Code requires it) |
| `python3` | basedpyright | macOS ships one; `pyenv` for specific versions |
| `rustup` | rust-analyzer | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| `php` (optional) | intelephense validates paths | `brew install php` |

Mason downloads the rest on demand. `:Mason` to view/install/update. `:LspInfo` shows the LSP status in the current buffer.

**Linters that are not language servers** (nvim-lint, run after save and on leaving insert, diagnostics land in the same list): `golangci-lint` for Go, `markdownlint-cli2` for Markdown, `hadolint` for Dockerfiles. The repo's config file wins where one exists.

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
| `<leader>ca` (normal / visual) | Code action (quick fix, imports, refactor, ESLint "fix all") — opens as a telescope dropdown, `<C-j>`/`<C-k>` and `<CR>` |
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

Registers itself on `.rs` buffers; **not** in the lspconfig loop. Same `gd` / `gr` / `<leader>ca` keymaps as any LSP buffer (`K` is rustaceanvim's hover with actions: go to impl, run test, open docs), plus its own, buffer-local under `<leader>c`:

| Shortcut | Command | Action |
|---|---|---|
| `<leader>cr` | `:RustLsp runnables` | Pick a target / test to run |
| `<leader>ce` | `:RustLsp explainError` | Long-form explanation of the error under the cursor (`rustc --explain`) |
| `<leader>cE` | `:RustLsp expandMacro` | Expand the macro under the cursor |
| `<leader>cx` | `:RustLsp renderDiagnostic` | The diagnostic as cargo prints it |
| `<leader>cp` | `:RustLsp parentModule` | Jump to the parent module |
| `<leader>cC` | `:RustLsp openCargo` | Jump to `Cargo.toml` |
| `<leader>ck` | `:RustLsp openDocs` | docs.rs for the symbol under the cursor |

Clippy runs on save; lifetime-elision inlay hints are always on. The toolchain is rustup's (`rustup component add rust-analyzer rustfmt rust-src clippy`); nothing for Rust comes from mason.

**Inside `Cargo.toml`** (crates.nvim, buffer-local): `<leader>cv` versions popup · `<leader>cF` features · `<leader>cu` / `<leader>cU` update (compatible) / upgrade (latest) the crate under the cursor, or the selection in visual · `<leader>cA` upgrade all · `<leader>ck` docs.rs · `<leader>cR` repository.

---

## 8. Git — `<leader>g*`

Three layers: gitsigns for the hunk under the cursor, Neogit for the porcelain (status, commit, log), codediff for reviewing diffs and history side by side.

### Hunks (gitsigns)

| Shortcut | Action |
|---|---|
| `]h` / `[h` | Next / previous hunk |
| `<leader>gs` | Stage hunk |
| `<leader>gr` | Reset hunk (discard the change) |
| `<leader>gp` | Preview hunk |
| `<leader>gb` | Toggle inline blame for the current line |
| `<leader>gd` | Diff the current buffer against the index |

Gutter signs: `│` added / modified · `_` / `‾` deleted · `~` changed-and-deleted · `┆` untracked.

### Porcelain (Neogit)

| Shortcut | Action |
|---|---|
| `<leader>gg` | Status buffer — stage with `s`, unstage `u`, commit `c`, push `p`, `?` for the full menu |
| `<leader>gc` | Commit |
| `<leader>gl` | Log |

### Review (codediff + commit pickers)

| Shortcut | Action |
|---|---|
| `<leader>gv` | Working tree vs index, side by side |
| `<leader>gB` | Current branch vs its base (`origin/HEAD...`) |
| `<leader>gh` (normal / visual) | History of the current file / of the selected lines |
| `<leader>gH` | History of the whole repo |
| `<leader>gf` / `<leader>gF` | Telescope picker of repo / file commits — `<CR>` opens the commit in codediff, `<C-y>` yanks its hash |

Full TUI: **`Alt+g`** in tmux opens lazygit in a popup (no prefix). `prefix + g` is something else — the IDE layout.

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

mason-tool-installer installs the formatters at startup (stylua, gofumpt, goimports, shfmt, prettierd). Two are listed but deliberately not installed because they need a system runtime the machines don't have: `php_cs_fixer` (php) and `sqlfluff` (python ≥ 3.10; macOS ships 3.9). `:ConformInfo` shows which formatter applies to the current buffer.

---

## 10. Tests — `<leader>t*` (neotest)

Go through neotest-golang (gotestsum, `-race -count=1`), Rust through rustaceanvim's own adapter. There is no debugger in this config (DAP was removed in sep-2026): a failing test's output (`<leader>to`) plus the diagnostics is the loop.

| Shortcut | Action |
|---|---|
| `<leader>tt` | Run the nearest test |
| `<leader>tf` | Run the current file |
| `<leader>ta` | Run everything under cwd |
| `<leader>tl` | Re-run the last run |
| `<leader>ts` | Toggle the summary tree (run / jump / expand from there) |
| `<leader>to` | Output of the test under the cursor in a float |
| `<leader>tO` | Toggle the output panel |
| `<leader>tS` | Stop the run |

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
| `:Snacks.dashboard()` | snacks.dashboard | Splash screen when opening nvim with no args — `f` files, `g` grep, `r` recent, `s` restore session, `n` new, `c` config, `L` Lazy, `q` quit. Then a **Projects** list (git roots of recent files, numbered): a key `cd`s there and restores that directory's session, or opens the file picker if it has none |
| any prompt for text | snacks.input | `vim.ui.input` is a small floating window (neo-tree add/rename, grug-far prompts) — `<Esc>` cancels, `<CR>` confirms |

Also on: snacks indent guides with scope highlight, incline (per-window filename floats), lualine, highlight-colors (inline `#hex` swatches). Smooth scroll is off (it fought the trackpad).

---

## 13. Search and replace

### Search in the buffer
- `/<pattern>` — search forward
- `?<pattern>` — search backward
- `n` / `N` — next / previous
- `*` / `#` — search the word under the cursor
- `<Esc>` — clear the highlight (custom)

### Search in the project
Telescope, §5: `<leader>fg` live grep with rg flags, `<leader>fw` word under the cursor, `<leader>fG` current file's directory, `<leader>fR` resume.

### Replace in the buffer — `:substitute`
- `:s/old/new/` — first occurrence in the line
- `:s/old/new/g` — all in the line
- `:%s/old/new/g` — all in the file
- `:%s/old/new/gc` — all in the file with confirmation
- `:'<,'>s/old/new/g` — in the visual selection

Useful flags: `c` confirm, `i` case-insensitive, `I` case-sensitive.

### Replace across the project — `<leader>s*` (grug-far)

A buffer with four fields (search, replace, files filter, flags) and the live match list below. Every match is editable in place; nothing touches disk until you apply.

| Shortcut | Action |
|---|---|
| `<leader>sr` (normal / visual) | Search & replace the word under the cursor / the selection, project-wide |
| `<leader>sf` (normal / visual) | Same, limited to the current file |

**Inside the grug-far buffer** (`<localleader>` = space): `<space>r` replace all · `<space>j` / `<space>k` apply just the next / previous match · `<Down>` / `<Up>` walk the matches, `<CR>` jump to one, `<space>o` open it · `<space>s` sync your in-place edits of the result list to disk (`<space>l` for one line) · `<space>q` send to quickfix · `<space>t` history · `<space>c` close · `g?` all keys. Flags field takes rg flags (`-i`, `-w`, `--fixed-strings`); `\1` back-references work in the replace field.

The old route still works: `<C-q>` in Telescope sends the matches to quickfix, then `:cdo s/old/new/g | update`.

### Quickfix list (nvim-bqf)

`:copen` / `:cclose` open and close it, `]q` / `[q` walk the entries (native). Inside the window:

| Key | Action |
|---|---|
| `p` | Toggle the floating preview of the entry under the cursor (auto-shown by default) |
| `<C-f>` / `<C-b>` | Scroll the preview |
| `zf` | fzf over the entries: type to filter, `<Tab>` to mark, `<CR>` builds a **new** quickfix list from the marks |
| `<Tab>` / `<S-Tab>` | Sign / unsign the entry (moves down / up) |
| `zn` / `zN` | New list from the signed / the unsigned entries |
| `<` / `>` | Older / newer quickfix list |
| `<CR>` / `o` / `O` | Open the entry / open and close the window / open in a new tab |

Typical: `<leader>fg` → `<C-q>` → `zf` to keep the 12 hits that matter → `:cdo s/old/new/g | update`.

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
- `:checkhealth lazy` / `:checkhealth mason` — one component
- `:messages` — message history (`:Noice` is the richer version)

---

## 16. which-key groups

Press `<leader>` and wait ~400ms (`timeoutlen`):

- `<leader>a` → ai (claude code)
- `<leader>b` → buffer
- `<leader>c` → code (LSP / format)
- `<leader>f` → find (telescope)
- `<leader>g` → git
- `<leader>r` → rename
- `<leader>s` → search & replace (grug-far)
- `<leader>S` → session (persistence)
- `<leader>t` → test (neotest)

Single keys outside a group: `<leader>m` / `<leader>M` / `<leader>1-4` harpoon, `<leader>h` dropbar, `<leader>e` oil, `<leader>n` neo-tree, `<leader>z` zen.

---

## 17. Claude Code — `<leader>a*` (claudecode.nvim)

nvim hosts the editor side of the VS Code extension's protocol; the Claude process itself runs in the same tmux popup session `Alt+c` uses for this directory, so the shell and the editor share one conversation. A session started from the shell before nvim needs a manual `/ide` once.

| Shortcut | Action |
|---|---|
| `<leader>ac` | Open the popup on this directory's session (creates it if needed) |
| `<leader>ar` | Resume a session (picker) |
| `<leader>aC` | Continue the last session |
| `<leader>ab` | Add the current buffer to Claude's context |
| `<leader>as` (visual) | Send the selection |
| `<leader>as` (in neo-tree / oil) | Add the file under the cursor |
| `<leader>aa` / `<leader>ad` | Accept / deny the diff Claude proposed (in the diff buffer) |
| `<leader>am` | Select model |
| `<leader>aS` | Connection status |

---

## 18. Useful tips

- **Macros**: `q<letter>` start recording, `q` stop, `@<letter>` run. `@@` repeats the last one.
- **Marks**: `m<letter>` marks a position, `'<letter>` jumps to the line, `` `<letter> `` jumps to the exact character. Uppercase marks (`mA`) are global across files.
- **`gx`** — opens the URL under the cursor in the browser.
- **`gu` / `gU`** — lowercase / uppercase (with a motion, e.g. `guw`).
- **`>ip` / `<ip`** — indent / unindent paragraph.
- **`==`** — re-indent the line according to LSP/treesitter.
- **`<C-r>=` in insert** — inline calculator (`5*7` Enter inserts `35`).
- **Reviewing a generated diff**: `]h` through the hunks, `<leader>gp` to see the old text, `<leader>gr` to throw a hunk away, `gd` / `gr` (Glance) to check a symbol without leaving the file, `<leader>fd` for everything the LSP disagrees with.

---

## 19. When something doesn't work

| Symptom | Diagnosis |
|---|---|
| A shortcut doesn't respond | `<leader>fk` to see if it's registered; `:WhichKey <leader>a` for a group |
| LSP doesn't complete | `:LspInfo` shows whether it's running. `:Mason` to check the server is installed |
| Odd color | `:Inspect` under the cursor shows which highlight group applies it |
| Language without highlight | `:TSInstall <lang>` to install the parser |
| A plugin doesn't load | `:Lazy` and look for the plugin — check for an installation error |
| Format on save did nothing | `:ConformInfo` — the formatter may not be installed (`:Mason`) |
| Everything broke | `:Lazy restore` goes back to the lockfile (`lazy-lock.json`) |
