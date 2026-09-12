-- ─── stack theme ──────────────────────────────────────────────
-- nvim is ONE layer of the "stack theme" (alongside Ghostty and tmux). The
-- selection is this string, versioned and the source of truth: a `git pull`
-- propagates the theme to the other machines. To change the look edit this
-- line (and the equivalent ones in Ghostty and tmux — they share the id) and commit.
-- There's no switcher or pointer; it requires restarting nvim.
--
-- Canonical family (id = same string in Ghostty/nvim/tmux):
--   "dark-2026"        clone of "Dark 2026", VS Code's dark default
--                       (extensions/theme-defaults/themes/2026-dark.json)
--   "light-2026"       clone of "2026 Light", its light companion
--   "carbon"           minimal true-black, high contrast, Claude orange accent
--   "solarized-osaka"  craftzdog deep-ocean ← separate plugin
--   "neon-noir"        true black noir canvas + neon spectrum (derived from
--                       Xcode 27's "Neon Noir" preset — not a literal port)
--   "naysayer"         Jonathan Blow's editor: deep teal bg, sand fg, loud comments
--   "anthropic-dark"   dark Claude.ai (brown-black + Claude orange)
--   "anthropic-warm"   warm dark sepia/terracotta
--   "prism-night"      midnight blue + prism arc
--   "paper"            light cream + sepia ink
--   "solarized-light"  canonical Solarized Light
-- (The solarized-osaka-{day,moon,storm} variants and "obsidian" are still
--  valid themes here, but outside the matrix.)
vim.g.theme = "solarized-osaka"

-- ─── remote-plugin providers ──────────────────────────────────
-- Nothing here is a remote plugin (every plugin is Lua), so the Python,
-- Ruby, Perl and Node providers only ever probe for host packages that
-- aren't installed and report it in :checkhealth. Off = no probe.
-- `:python3` / `:ruby` etc. become unavailable, which nothing uses.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- ─── filetype detection ───────────────────────────────────────
-- Filetypes the LSP configs target that nvim's built-in detection
-- doesn't produce on its own (:checkhealth vim.lsp flags them as
-- "Unknown filetype"). Dotted types keep the parent's behaviour —
-- `yaml.docker-compose` still gets yamlls and the yaml parser, and
-- SchemaStore matches the compose schema on the filename anyway;
-- `markdown.mdx` keeps marksman, render-markdown and the markdown
-- autocmds. `gotmpl` is what gopls wants for Go templates.
vim.filetype.add({
  extension = {
    mdx    = "markdown.mdx",
    tmpl   = "gotmpl",
    gotmpl = "gotmpl",
  },
  filename = {
    ["compose.yml"]         = "yaml.docker-compose",
    ["compose.yaml"]        = "yaml.docker-compose",
    ["docker-compose.yml"]  = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    [".gitlab-ci.yml"]      = "yaml.gitlab",
    [".gitlab-ci.yaml"]     = "yaml.gitlab",
  },
  pattern = {
    ["docker%-compose%..*%.ya?ml"] = "yaml.docker-compose",   -- docker-compose.override.yml
    ["compose%..*%.ya?ml"]         = "yaml.docker-compose",   -- compose.prod.yml
    [".*/values%.ya?ml"]           = "yaml.helm-values",      -- helm chart values
    [".*/values%-.*%.ya?ml"]       = "yaml.helm-values",      -- values-prod.yaml
  },
})

-- ─── vim.opt ──────────────────────────────────────────────────
-- Good defaults. Follows the spirit of the dotfiles: comment the WHY,
-- not the WHAT — vim.opt.number = true needs no comment.

local opt = vim.opt

-- Lines
opt.number = true
opt.relativenumber = true            -- jumps with `5j`, `10k` without counting
opt.cursorline = true
opt.scrolloff = 8                    -- 8 lines of margin when scrolling
opt.sidescrolloff = 8
-- Wrap ON (2026-09-04): a long line continues on the next screen row instead
-- of scrolling the whole pane sideways — with a 32-col tree on the left the
-- horizontal scroll hid the start of every line you were reading.
-- linebreak breaks at a word, not mid-token; breakindent keeps the
-- continuation under the code's indent so a wrapped line still reads as one
-- statement; showbreak marks where that happened. codediff sets nowrap on
-- its own diff windows, because wrap breaks side-by-side alignment.
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.showbreak = "↪ "

-- Indentation
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
-- Languages with their own convention override via autocmd (autocmds.lua):
-- Go uses real tabs; PHP is usually 4 spaces.

-- Search
opt.ignorecase = true
opt.smartcase = true                 -- ignores case unless you type uppercase
-- (incsearch and hlsearch are nvim defaults; not restated here.)

-- UI
-- (termguicolors is auto-detected since nvim 0.10; Ghostty and tmux-256color
--  both declare RGB, so it's on without a line here.)
opt.signcolumn = "yes"               -- always visible: avoids layout shift when LSP/git signs appear
opt.showmode = false                 -- lualine already shows the mode
opt.cmdheight = 1
opt.pumheight = 10                   -- max items in the completion popup
opt.splitright = true                -- vsplits to the right (intuitive on wide screens)
opt.splitbelow = true
opt.fillchars = { eob = " " }        -- hides ~ on empty lines at the end of the buffer

-- Buffers / files (hidden=on and backup=off are nvim defaults)
opt.undofile = true                  -- persistent undo across sessions (in ~/.local/share/nvim/undo/)
opt.swapfile = false                 -- more annoying than helpful with undofile + git
opt.updatetime = 250                 -- gitsigns/lsp respond faster (default 4000ms)
opt.timeoutlen = 400                 -- chord timeout (which-key respects this)

-- Clipboard
opt.clipboard = "unnamedplus"        -- shares yank with the system clipboard

-- Wildmenu. (No completeopt: blink.cmp drives insert completion and
-- ignores it.)
opt.wildmode = "longest:full,full"

-- Folding: native, from the treesitter tree (nvim 0.9+). nvim-ufo did this
-- with two plugins and was dropped (sep-2026) — the peek-on-K and the
-- "N lines" suffix weren't worth them. `foldtext = ""` keeps the folded
-- line syntax-highlighted instead of the grey `+--` text. Buffers without
-- a parser get no folds rather than indent folds; the only ones that
-- matter here (logs, plain text) aren't folded anyway.
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""
opt.foldcolumn = "1"                 -- fold markers in the gutter
opt.foldlevel = 99                   -- open everything by default
opt.foldlevelstart = 99
opt.fillchars:append({ fold = " ", foldopen = "▾", foldclose = "▸", foldsep = " " })

-- Invisible characters
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Diagnostic UI. Two renderings that split by cursor line (nvim 0.11+):
-- the short `●` virtual text on every line EXCEPT the one you're on, and
-- the full multi-line message (`virtual_lines`) under the current line
-- only. Long rustc / tsc messages used to be truncated at the window
-- edge; now they wrap below the line you are reading, and the rest of
-- the buffer stays as quiet as before. Both `current_line` flags are
-- needed — with only the second, the current line shows both.
vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 4, current_line = false },
  virtual_lines = { current_line = true },
  signs = true,
  underline = true,
  update_in_insert = false,          -- noisy while typing
  severity_sort = true,
  float = { border = "rounded", source = true },
})
