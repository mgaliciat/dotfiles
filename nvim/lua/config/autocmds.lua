-- ─── autocmds ─────────────────────────────────────────────────

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank (visual feedback without plugins)
autocmd("TextYankPost", {
  group = augroup("highlight_yank", { clear = true }),
  callback = function() vim.highlight.on_yank({ timeout = 200 }) end,
})

-- Trim whitespace on save. Restores the cursor to avoid jumps.
autocmd("BufWritePre", {
  group = augroup("trim_whitespace", { clear = true }),
  callback = function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd([[%s/\s\+$//e]])
    pcall(vim.api.nvim_win_set_cursor, 0, pos)
  end,
})

-- Per-language conventions. vim.opt_local only affects the current buffer.
-- Go uses real tabs (gofmt inserts them — fighting that is a losing battle).
autocmd("FileType", {
  group = augroup("ft_go", { clear = true }),
  pattern = "go",
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- PHP, Rust: 4 spaces by convention
autocmd("FileType", {
  group = augroup("ft_four_space", { clear = true }),
  pattern = { "php", "rust" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
})

-- Markdown: wrap on + spellcheck. No relative numbers (distracting when writing prose).
autocmd("FileType", {
  group = augroup("ft_markdown", { clear = true }),
  pattern = { "markdown", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true            -- wrap respects words
    vim.opt_local.spell = true
    vim.opt_local.spelllang = { "en", "es" }  -- bilingual, like your repo
    vim.opt_local.relativenumber = false
  end,
})

-- Close utility buffers with `q` (no need for :q)
autocmd("FileType", {
  group = augroup("close_with_q", { clear = true }),
  pattern = { "help", "lspinfo", "man", "qf", "checkhealth", "startuptime" },
  callback = function(ev)
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
  end,
})

-- Restore cursor position when reopening a file
autocmd("BufReadPost", {
  group = augroup("restore_cursor", { clear = true }),
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
