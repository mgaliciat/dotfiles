-- ─── todo-comments.nvim ───────────────────────────────────────
-- Highlight for TODO / FIX / HACK / NOTE / WARN / PERF in comments
-- + telescope picker with <leader>ft. `]t` / `[t` navigate between TODOs
-- in the current buffer.
--
-- `signs = false` so it doesn't compete with gitsigns and LSP diagnostics for
-- the signcolumn — the inline highlight is already signal enough.

return {
  "folke/todo-comments.nvim",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    signs = false,
  },
  keys = {
    { "]t",         function() require("todo-comments").jump_next() end, desc = "Next TODO" },
    { "[t",         function() require("todo-comments").jump_prev() end, desc = "Prev TODO" },
    { "<leader>ft", "<cmd>TodoTelescope<CR>",                            desc = "Find TODOs" },
  },
}
