-- ─── todo-comments.nvim ───────────────────────────────────────
-- Highlight for TODO / FIX / HACK / NOTE / WARN / PERF in comments
-- + telescope picker with <leader>ft. `]T` / `[T` navigate between TODOs
-- in the current buffer — capital T: the lowercase pair is neotest's
-- "next failed test" (neotest.lua), which is the more urgent jump and
-- was silently shadowing this one depending on load order.
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
    { "]T",         function() require("todo-comments").jump_next() end, desc = "Next TODO" },
    { "[T",         function() require("todo-comments").jump_prev() end, desc = "Prev TODO" },
    { "<leader>ft", "<cmd>TodoTelescope<CR>",                            desc = "Find TODOs" },
  },
}
