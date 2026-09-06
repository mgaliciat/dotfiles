-- ─── mini.ai ──────────────────────────────────────────────────
-- Extends `a`/`i` text objects. Replaces the `select` mappings that lived
-- in treesitter.lua (same keys, same treesitter queries — mini.ai's
-- `gen_spec.treesitter` reads nvim-treesitter-textobjects' `textobjects.scm`)
-- and adds what those could not do:
--
--   iq / aq      any quote  (`"`, `'`, `` ` `` — whichever is closest)
--   ib / ab      any bracket (`()`, `[]`, `{}`)
--   it / at      HTML/JSX tag
--   i? / a?      prompt for the two delimiters
--   in( / il"    NEXT / LAST object without moving the cursor first:
--                `cin"` changes the content of the next string on the
--                line, `dal(` deletes the previous call's parens
--   2if          counts work: the 2nd enclosing function
--
-- Treesitter-backed (from the queries): f function, c class, a argument
-- (mini.ai's own `a` is bracket-and-comma based and gets fooled by nested
-- calls; `@parameter` doesn't), o block / conditional / loop.
--
-- `n_lines = 500`: how far up/down it searches for a match — the default 50
-- misses the enclosing function in anything but a tiny file.
--
-- Not covered on purpose: `d` digits / `g` whole buffer (never missed them),
-- and no `search_method` override — `cover_or_next` (the default) is what
-- makes `ci"` on a line before the quotes still work.

return {
  "nvim-mini/mini.ai",
  event = "VeryLazy",
  dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
  opts = function()
    local ai = require("mini.ai")
    return {
      n_lines = 500,
      custom_textobjects = {
        f = ai.gen_spec.treesitter({ a = "@function.outer",  i = "@function.inner" }),
        c = ai.gen_spec.treesitter({ a = "@class.outer",     i = "@class.inner" }),
        a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
        o = ai.gen_spec.treesitter({
          a = { "@block.outer", "@conditional.outer", "@loop.outer" },
          i = { "@block.inner", "@conditional.inner", "@loop.inner" },
        }),
      },
    }
  end,
}
