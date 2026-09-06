-- ─── grug-far.nvim ────────────────────────────────────────────
-- Search & replace across the project, on the same ripgrep telescope
-- greps with. The UI is a buffer with four fields (search, replace,
-- files filter, flags) and the live match list below; every match is
-- editable in place and `<localleader>r` (inside the buffer) applies
-- the replacement to disk. That is the whole reason it exists next to
-- `<leader>fg`: telescope finds, this one changes — the alternative is
-- `<C-q>` to quickfix + `:cdo s///`, which has no preview and no undo
-- across files.
--
-- Keys under <leader>s ("search & replace"), both prefilled:
--   <leader>sr  word under the cursor / visual selection, project-wide
--   <leader>sf  same, limited to the current file (paths prefilled)
-- The buffer's own keys are in `:h grug-far` — the ones worth knowing:
-- `<localleader>r` replace all, `<localleader>j/k` next/prev match,
-- `<localleader>l` open location, `<localleader>t` toggle regex/fixed.
--
-- `with_visual_selection` is the plugin's own visual-mode entry: it
-- reads the selection itself, so no `"<,'>` juggling here.

return {
  "MagicDuck/grug-far.nvim",
  cmd = "GrugFar",
  opts = {},
  keys = {
    { "<leader>sr", function()
        require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
      end,
      desc = "Search & replace (word)" },
    { "<leader>sr", function() require("grug-far").with_visual_selection() end,
      mode = "v", desc = "Search & replace (selection)" },
    { "<leader>sf", function()
        require("grug-far").open({
          prefills = { search = vim.fn.expand("<cword>"), paths = vim.fn.expand("%") },
        })
      end,
      desc = "Search & replace in current file" },
    { "<leader>sf", function()
        require("grug-far").with_visual_selection({ prefills = { paths = vim.fn.expand("%") } })
      end,
      mode = "v", desc = "Search & replace selection in current file" },
  },
}
