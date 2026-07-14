-- ─── nvim-surround ────────────────────────────────────────────
-- Extends the vim grammar (operator + textobject) with a new
-- operator to wrap/change/delete delimiters — something
-- vanilla never had:
--
--   ys<motion><char>   surround     (e.g. ysiw" → wrap word in " )
--   cs<old><new>       change       (e.g. cs"'  → change " for ' )
--   ds<char>           delete       (e.g. ds(   → delete surrounding ( ) )
--   S<char>            (visual)     → wrap selection
--
-- No leader keymaps; everything is ys/cs/ds + textobject.

return {
  "kylechui/nvim-surround",
  version = "*",
  event = { "BufReadPost", "BufNewFile" },
  opts = {},
}
