-- ─── glance.nvim ──────────────────────────────────────────────
-- Replaces `vim.lsp.buf.definition/references/implementation/
-- type_definition` with a floating window like VS Code's "Peek".
-- You keep the context: you see the result without jumping out of the
-- current file, and from the peek window you can navigate or enter.
--
-- `before_open` hook: if there's a SINGLE result it jumps straight there (same
-- as the native gd/gr/gi/gt flow). If there are several, it opens the peek
-- — that's where it wins over the native one, which dumps a quickfix list.
--
-- The gd/gr/gi/gt keymaps are rebound in lsp.lua (LspAttach).

return {
  "dnlhc/glance.nvim",
  cmd = { "Glance" },
  opts = {
    border = { enable = true },
    list = { position = "left" },
    folds = { folded = false },
    hooks = {
      before_open = function(results, open, jump, method)
        if #results == 1 then
          jump(results[1])
        else
          open(results)
        end
      end,
    },
  },
}
