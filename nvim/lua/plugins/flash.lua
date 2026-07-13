-- ─── flash.nvim ───────────────────────────────────────────────
-- Motion modal: presionás `s` + 2 chars y aparecen labels de 1
-- letra sobre todos los matches en pantalla; presionar el label
-- salta ahí. Reemplaza el ciclo `/<pat><CR>nnn` para nav cercana.
--
-- Override `s` (substitute char) y `S` es deliberado y estándar
-- en la comunidad: `s` en vanilla es redundante con `cl`, así que
-- el costo es ~0. Encaja con "aceleradores dentro del modelo modal".
--
-- `S` va SOLO en n/o (no en x): en visual, `S` es el wrap de
-- nvim-surround (S<char> envuelve la selección — ver surround.lua).
-- Con x acá, flash cargaba después (VeryLazy > BufReadPost) y pisaba
-- ese mapping en silencio. Treesitter-select en visual sigue vía `R`.
--
-- Bonus: `r` en operator-pending = remote ops (e.g. `yr` + jump
-- = yank en otro lugar sin mover el cursor).

return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {},
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,             desc = "Flash jump" },
    { "S", mode = { "n", "o" },      function() require("flash").treesitter() end,       desc = "Flash treesitter" },
    { "r", mode = "o",               function() require("flash").remote() end,           desc = "Remote flash" },
    { "R", mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter search" },
  },
}
