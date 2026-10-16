-- ─── mini.bracketed ───────────────────────────────────────────
-- Enabled for three targets that nothing else provides (the rest
-- duplicate a key that already exists: `]b` = <S-l>, `]j` = <C-o>,
-- `]o` = <leader>fr, `]u` = u, `]d` = the native mapping in keymaps.lua):
--
--   yank      ]y [y   THE reason it is here: after a `p`, cycles through
--                     earlier yanks in place (a yank ring without a plugin
--                     of its own)
--   conflict  ]x [x   merge-conflict markers
--   indent    ]i [i   next/previous change of indentation level — the
--                     quick way out of a deeply nested block
--
-- Everything else is off (empty suffix). The ones that would collide:
-- `]f/[f`, `]c/[c` are treesitter moves (treesitter.lua); `]t/[t` is
-- neotest's failed-test jump; `]d/[d` is native; `]h/[h` gitsigns;
-- `]]/[[` snacks.words.

return {
  "nvim-mini/mini.bracketed",
  event = "BufReadPost",
  opts = {
    buffer     = { suffix = "" },
    comment    = { suffix = "" },
    diagnostic = { suffix = "" },
    file       = { suffix = "" },
    jump       = { suffix = "" },
    location   = { suffix = "" },
    oldfile    = { suffix = "" },
    quickfix   = { suffix = "" },
    treesitter = { suffix = "" },
    undo       = { suffix = "" },
    window     = { suffix = "" },
  },
}
