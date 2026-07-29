# nvim cheatsheet

Most-used shortcuts from my config. `<leader>` = **space**. Leave insert: **`jk`**.

For everything else: **`<leader>fk`** opens the keymap search (telescope), and **`<leader>`** alone fires which-key with the continuation menu.

> Companion: `nvim/CHEATSHEET.md` covers more native vim and detail on LSP/telescope/treesitter, but it's **incomplete on plugins** (missing oil, flash, dap, ufo and several more, which are here).

---

## Files and folders

### oil.nvim — edit the directory as text (pure vim)
| Key | Action |
|-------|--------|
| `-` | open the current file's directory |
| `<leader>e` | open oil |
| `o` / `i` + text + `:w` | **create file** (`foo.lua`) |
| name with trailing `/` + `:w` | **create folder** (`utils/`) |
| `foo/bar/baz.lua` + `:w` | creates nested folders + file |
| edit line + `:w` | rename |
| `dd` + `:w` | delete |
| `q` | close |

> `:w` applies the changes to the filesystem (shows a preview before confirming).

### neo-tree — IDE-style sidebar
| Key | Action |
|-------|--------|
| `<leader>n` | toggle the tree |
| `<leader>N` | reveal current file in the tree |
| `a` | **add** — `foo.lua` file · `foo/` folder · `a/b/c.lua` full path |
| `d` / `r` | delete / rename |
| `c` / `m` | copy / move |
| `l` / `h` | open / collapse node |
| `q` | close panel |

---

## Search / navigate (telescope)
| Key | Action |
|-------|--------|
| `<leader>ff` | find files |
| `<leader>fg` | live grep (search the whole project) |
| `<leader>/` | search in the current buffer |
| `<leader>fb` | open buffers |
| `<leader>fr` | recent |
| `<leader>fs` / `<leader>fS` | document / workspace symbols |
| `<leader>fd` | diagnostics |
| `<leader>ft` | TODOs |
| `<leader>fc` / `<leader>fk` | commands / keymaps |
| `<leader>fh` | help tags |

### Quick jumps (flash)
| Key | Action |
|-------|--------|
| `s` + 2 chars | jump anywhere on screen |
| `S` | jump by treesitter nodes (normal/operator; in visual `S` is the nvim-surround wrap) |

---

## LSP — essential for reviewing generated code
| Key | Action |
|-------|--------|
| `gd` | go to definition (peek if there are several) |
| `gr` | references |
| `gi` / `gt` | implementation / type definition |
| `gD` | declaration |
| `K` | hover docs (or opens the peek of a fold) |
| `<leader>ca` | code action (fixes, imports, etc.) |
| `<leader>rn` | rename symbol (live preview) |
| `<leader>cs` | signature help |
| `<leader>ch` | toggle inlay hints |
| `<leader>cl` | run code lens (go test, etc.) |
| `[d` / `]d` | previous / next diagnostic |
| `<leader>cd` | line diagnostics |

---

## Git (gitsigns) — key when reviewing prompt diffs
| Key | Action |
|-------|--------|
| `<leader>gs` | stage hunk |
| `<leader>gr` | reset hunk (discard change) |
| `<leader>gp` | preview hunk |
| `<leader>gd` | file diff |
| `<leader>gb` | toggle line blame |

> Full lazygit: **`Alt+g`** in tmux (popup, no prefix). `prefix + g` is something else: the IDE layout.

---

## Format code
| Key | Action |
|-------|--------|
| `<leader>cf` | format buffer / selection |

> Go, Rust, Lua and Python are formatted **on save only**. Markdown / SQL / PHP: manual with `<leader>cf`.

---

## Quick editing
| Key | Action |
|-------|--------|
| `<A-j>` / `<A-k>` | move line (or selection) down / up |
| `<` / `>` in visual | indent and keep selection |
| `p` in visual | paste without losing the yank |
| `<leader>p` / `<leader>P` | paste last yank (ignores deletes) |
| `<leader>d` / `x` | delete without polluting the register |
| `+` / `<C-x>` | increment / decrement (dial: bool, dates, semver, let↔const; `-` belongs to oil.nvim) |

---

## Windows, buffers, file
| Key | Action |
|-------|--------|
| `<C-h/j/k/l>` | move between splits |
| `<C-arrows>` | resize split |
| `<S-l>` / `<S-h>` | next / previous buffer |
| `<leader>bd` | close buffer |
| `<leader>w` / `<leader>q` | save / close |
| `<leader>Q` | close everything (force) |
| `<Esc>` | clear search highlight |

---

## Folds, focus, plugins
| Key | Action |
|-------|--------|
| `zR` / `zM` | open / close all folds |
| `zr` / `zm` | decrease / increase fold level |
| `<leader>z` | zen mode (focus) |
| `<leader>Z` | zen zoom (window only) |
| `:Lazy` | manage plugins |
| `:Mason` | manage LSPs / formatters |
