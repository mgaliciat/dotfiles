-- ─── gitsigns.nvim ────────────────────────────────────────────
-- Git markers in the signcolumn + hunk navigation + inline blame.

return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    -- `▎` (left one-eighth block) instead of `│`: a box-drawing bar is one
    -- pixel wide and vanishes on a dark canvas; the block is a solid strip
    -- that reads from across the room. Deletes are the angle glyphs, which
    -- point at the gap where the lines were.
    signs = {
      add          = { text = "▎" },
      change       = { text = "▎" },
      delete       = { text = "" },
      topdelete    = { text = "" },
      changedelete = { text = "▎" },
      untracked    = { text = "▎" },
    },
    signs_staged = {
      add          = { text = "▎" },
      change       = { text = "▎" },
      delete       = { text = "" },
      topdelete    = { text = "" },
      changedelete = { text = "▎" },
    },
    -- Also paint the LINE NUMBER of a changed line (GitSigns*Nr): the sign
    -- column is one cell, the number is three — twice the ink for the same
    -- information.
    numhl = true,
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
      -- No `diffthis` here: the buffer-vs-index diff is codediff's
      -- `<leader>gv`, side by side with character-level highlighting.
    end,
  },
}
