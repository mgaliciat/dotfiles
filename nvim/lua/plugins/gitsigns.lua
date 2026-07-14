-- ─── gitsigns.nvim ────────────────────────────────────────────
-- Git markers in the signcolumn + hunk navigation + inline blame.

return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add          = { text = "│" },
      change       = { text = "│" },
      delete       = { text = "_" },
      topdelete    = { text = "‾" },
      changedelete = { text = "~" },
      untracked    = { text = "┆" },
    },
    current_line_blame = false,           -- toggle with <leader>gb if you want it
    on_attach = function(bufnr)
      local gs = require("gitsigns")
      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      map("n", "]h", function() gs.nav_hunk("next") end, "Next hunk")
      map("n", "[h", function() gs.nav_hunk("prev") end, "Prev hunk")
      map("n", "<leader>gs", gs.stage_hunk,        "Stage hunk")
      map("n", "<leader>gr", gs.reset_hunk,        "Reset hunk")
      map("n", "<leader>gp", gs.preview_hunk,      "Preview hunk")
      map("n", "<leader>gb", gs.toggle_current_line_blame, "Toggle blame")
      map("n", "<leader>gd", gs.diffthis,          "Diff this")
    end,
  },
}
