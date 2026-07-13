-- ─── mini.bracketed ───────────────────────────────────────────
-- Bracket-nav unificada estilo `]x/[x`. Lo más útil que agrega
-- vs. el setup actual: `]y/[y` cicla por **yank history** (no solo
-- el último yank — pasás por todos los registros recientes).
--
-- Targets activos (default suffix entre paréntesis):
--   buffer       ]b [b        siguiente/anterior buffer
--   conflict     ]x [x        marker de merge conflict
--   diagnostic   ]d [d        (ya lo tenías nativo — mini lo shadow-ea,
--                              misma key + misma acción, sin conflicto)
--   indent       ]i [i        cambia nivel de indentación
--   jump         ]j [j        jumplist (alternativa a <C-o>/<C-i>)
--   location     ]l [l        location list
--   oldfile      ]o [o        archivos recientes
--   undo         ]u [u        undo states (linealiza el undo tree)
--
-- Targets DESHABILITADOS para no chocar con tu setup:
--   file         []  (vacío)  — `]f/[f` ya lo usás para treesitter functions
--   comment      []  (vacío)  — `]c/[c` ya lo usás para treesitter classes
--   quickfix     []  (vacío)  — preferís telescope para esto
--   window       []  (vacío)  — ya tenés <C-h/j/k/l>
--   treesitter   []  (vacío)  — `]t/[t` ya lo usa todo-comments (next/prev
--                              TODO); sin esto ambos mapean ]t/[t global y
--                              gana uno u otro según orden de carga
--   yank         (suffix por default) — ESTA es la joya: ciclar yank history

return {
  "nvim-mini/mini.bracketed",
  event = "BufReadPost",
  config = function()
    require("mini.bracketed").setup({
      file       = { suffix = "" },
      comment    = { suffix = "" },
      quickfix   = { suffix = "" },
      window     = { suffix = "" },
      treesitter = { suffix = "" },
    })
  end,
}
