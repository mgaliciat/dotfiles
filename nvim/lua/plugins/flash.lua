-- ─── flash.nvim ───────────────────────────────────────────────
-- Motion modal: presionás `s` + 2 chars y aparecen labels de 1
-- letra sobre todos los matches en pantalla; presionar el label
-- salta ahí. Reemplaza el ciclo `/<pat><CR>nnn` para nav cercana.
--
-- Override `s` (substitute char) y `S` es deliberado y estándar
-- en la comunidad: `s` en vanilla es redundante con `cl`, así que
-- el costo es ~0. Encaja con "aceleradores dentro del modelo modal".
--
-- Bonus: `r` en operator-pending = remote ops (e.g. `yr` + jump
-- = yank en otro lugar sin mover el cursor).

return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {},
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,             desc = "Flash jump" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end,       desc = "Flash treesitter" },
    { "r", mode = "o",               function() require("flash").remote() end,           desc = "Remote flash" },
    { "R", mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter search" },
  },
}
