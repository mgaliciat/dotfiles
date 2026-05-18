-- ─── nvim-surround ────────────────────────────────────────────
-- Extiende la gramática vim (operator + textobject) con un operator
-- nuevo para envolver/cambiar/borrar delimitadores — algo que
-- vanilla nunca tuvo:
--
--   ys<motion><char>   surround     (e.g. ysiw" → wrap palabra en " )
--   cs<old><new>       change       (e.g. cs"'  → cambiar " por ' )
--   ds<char>           delete       (e.g. ds(   → borrar ( ) alrededor )
--   S<char>            (visual)     → wrap selección
--
-- Sin keymaps de leader; todo es ys/cs/ds + textobject.

return {
  "kylechui/nvim-surround",
  version = "*",
  event = { "BufReadPost", "BufNewFile" },
  opts = {},
}
