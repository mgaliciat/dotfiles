-- ─── native keymaps ───────────────────────────────────────────
-- Only mappings that don't depend on plugins. Plugin-specific ones
-- live in each plugins/<name>.lua inside its `keys = {}`.

-- Leader = space. Set BEFORE loading lazy (which reads mapleader
-- when registering keys). It's here because options.lua runs before
-- keymaps.lua and lazy.lua — order defined in init.lua.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- Exit insert mode with jk (faster than <Esc>, doesn't collide with common words)
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Save / close
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa!<CR>", { desc = "Quit all (force)" })

-- Navigation between splits with Ctrl+hjkl (no <leader>, more fluid)
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Resize splits
map("n", "<C-Up>",    "<cmd>resize +2<CR>",          { desc = "Resize up" })
map("n", "<C-Down>",  "<cmd>resize -2<CR>",          { desc = "Resize down" })
map("n", "<C-Left>",  "<cmd>vertical resize -2<CR>", { desc = "Resize left" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Resize right" })

-- Move lines with Alt+j/k (in normal and visual mode)
map("n", "<A-j>", "<cmd>m .+1<CR>==",       { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==",       { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv",       { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv",       { desc = "Move selection up" })

-- Keep the selection when indenting (default deselects, annoying)
map("v", "<", "<gv", { desc = "Indent left & keep selection" })
map("v", ">", ">gv", { desc = "Indent right & keep selection" })

-- Paste over a selection without losing the yank (default: the selection replaces the register)
map("v", "p", '"_dP', { desc = "Paste without yank" })

-- Buffers
map("n", "<S-l>", "<cmd>bnext<CR>",     { desc = "Next buffer" })
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- Diagnostic navigation (native LSP, no plugin required)
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Prev diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count =  1 }) end, { desc = "Next diagnostic" })
map("n", "<leader>cd", vim.diagnostic.open_float,                  { desc = "Line diagnostics" })

-- ─── craftzdog-style accelerators ─────────────────────────────
-- Source: github.com/craftzdog/dotfiles-public. All of them are
-- "accelerators within the vim model", not Mac-style crutches.

-- Paste from register 0 = "last yank, ignores deletes".
-- Solves: you yanked something → deleted something else → `p` no longer pastes
-- the original yank. With <leader>p it always pastes the last yank.
map({ "n", "v" }, "<leader>p", '"0p', { desc = "Paste from yank register" })
map("n",          "<leader>P", '"0P', { desc = "Paste from yank register (before)" })

-- Delete without polluting the register (black-hole "_).
-- Use them when you want to delete something WITHOUT losing your last yank.
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete (no yank)" })
map({ "n", "v" }, "<leader>D", '"_D', { desc = "Delete to EOL (no yank)" })

-- `x` also to the black-hole — deleting 1 char is rarely something you want
-- to copy, and it pollutes the paste register.
map("n", "x", '"_x', { desc = "Delete char (no yank)" })

-- Increment with + (more ergonomic than <C-a>). `remap = true` so that
-- the + → <C-a> chain reaches dial.nvim (which intercepts <C-a>
-- with smart increment: bool, dates, semver, let↔const). Without
-- remap=true, the + would go to vim's native <C-a> (numbers only) and dial
-- would be left out. Do NOT map `-` as decrement: oil.nvim grabs `-`
-- for "open parent dir" (its keys={} wins because lazy registers after
-- this file) — for decrement use <C-x> directly (see dial.lua).
map("n", "+", "<C-a>", { desc = "Increment (dial)", remap = true })

-- 🤠 Cowboy mode: stops you if you hammer hjkl more than 10 times in
-- 2 sec. Educational — pushes you to learn real motions. It deliberately
-- doesn't cover +/<C-a>/<C-x> (see dial.lua: mashing increment is
-- legitimate use).
require("config.cowboy").setup()
