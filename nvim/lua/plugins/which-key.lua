-- ─── which-key.nvim ───────────────────────────────────────────
-- Popup que muestra los mappings disponibles tras un prefijo (e.g.
-- al presionar <leader>, espera `timeoutlen` y muestra el menú).
-- Lee los `desc` que define cada keymap → no requiere registrar
-- nombres aquí.

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = 400,   -- alineado con vim.opt.timeoutlen
    spec = {
      -- Grupos: nombres visibles para los prefijos. Los mappings
      -- individuales (con sus desc) se descubren solos.
      { "<leader>b",  group = "buffer" },
      { "<leader>c",  group = "code (LSP / debug)" },
      { "<leader>cg", group = "go debug" },
      { "<leader>f",  group = "find (telescope)" },
      { "<leader>g",  group = "git" },
      { "<leader>r",  group = "rename" },
    },
  },
  keys = {
    { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer keymaps" },
  },
}
