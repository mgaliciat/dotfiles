-- ─── mini.bracketed ───────────────────────────────────────────
-- Unified bracket-nav in `]x/[x` style. The most useful thing it adds
-- vs. the current setup: `]y/[y` cycles through **yank history** (not just
-- the last yank — you go through all the recent registers).
--
-- Active targets (default suffix in parentheses):
--   buffer       ]b [b        next/previous buffer
--   conflict     ]x [x        merge conflict marker
--   diagnostic   ]d [d        (you already had it natively — mini shadows it,
--                              same key + same action, no conflict)
--   indent       ]i [i        changes indentation level
--   jump         ]j [j        jumplist (alternative to <C-o>/<C-i>)
--   location     ]l [l        location list
--   oldfile      ]o [o        recent files
--   undo         ]u [u        undo states (linearizes the undo tree)
--
-- DISABLED targets so they don't collide with your setup:
--   file         []  (empty)  — `]f/[f` you already use for treesitter functions
--   comment      []  (empty)  — `]c/[c` you already use for treesitter classes
--   quickfix     []  (empty)  — you prefer telescope for this
--   window       []  (empty)  — you already have <C-h/j/k/l>
--   treesitter   []  (empty)  — `]t/[t` is already used by todo-comments (next/prev
--                              TODO); without this both map ]t/[t globally and
--                              one or the other wins depending on load order
--   yank         (default suffix) — THIS is the gem: cycling yank history

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
