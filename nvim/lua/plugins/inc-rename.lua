-- ─── inc-rename.nvim ──────────────────────────────────────────
-- LSP rename with live preview: you start `:IncRename foo` and
-- while you type the new name, you see the changes highlighted at
-- every call site. Much better UX than vanilla
-- vim.lsp.buf.rename (blind input box).
--
-- The <leader>rn keymap in lsp.lua is switched to this version —
-- see lua/plugins/lsp.lua (on-attach handler).

return {
  "smjonas/inc-rename.nvim",
  cmd = "IncRename",
  config = true,
}
