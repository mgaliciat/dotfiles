-- ─── todo-comments.nvim ───────────────────────────────────────
-- Highlight para TODO / FIX / HACK / NOTE / WARN / PERF en comentarios
-- + picker telescope con <leader>ft. `]t` / `[t` navegan entre TODOs
-- en el buffer actual.
--
-- `signs = false` para no competir con gitsigns y diagnostics LSP por
-- el signcolumn — el highlight in-line ya es suficiente señal.

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
