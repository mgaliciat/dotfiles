-- ─── glance.nvim ──────────────────────────────────────────────
-- Reemplaza `vim.lsp.buf.definition/references/implementation/
-- type_definition` con una ventana flotante tipo VS Code "Peek".
-- Mantenés el contexto: ves el resultado sin saltar fuera del
-- archivo actual, y desde la peek window podés navegar o entrar.
--
-- Hook `before_open`: si hay UN SOLO resultado salta directo (igual
-- que el flujo nativo de gd/gr/gi/gt). Si hay varios, abre la peek
-- — ahí es donde gana sobre el nativo, que tira un quickfix list.
--
-- Las keymaps gd/gr/gi/gt se rebindan en lsp.lua (LspAttach).

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
