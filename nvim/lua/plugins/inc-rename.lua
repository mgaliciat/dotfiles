-- ─── inc-rename.nvim ──────────────────────────────────────────
-- Rename de LSP con preview en vivo: arrancás `:IncRename foo` y
-- mientras tipeás el nombre nuevo, ves los cambios highlighted en
-- todos los call sites. Mucho mejor UX que el vainilla
-- vim.lsp.buf.rename (input box ciego).
--
-- El keymap <leader>rn del lsp.lua se cambia a esta versión —
-- ver lua/plugins/lsp.lua (on-attach handler).

return {
  "smjonas/inc-rename.nvim",
  cmd = "IncRename",
  config = true,
}
