-- ─── flash.nvim ───────────────────────────────────────────────
-- Modal motion: you press `s` + 2 chars and 1-letter labels appear
-- over every match on screen; pressing the label
-- jumps there. Replaces the `/<pat><CR>nnn` cycle for nearby nav.
--
-- Overriding `s` (substitute char) and `S` is deliberate and standard
-- in the community: `s` in vanilla is redundant with `cl`, so
-- the cost is ~0. Fits with "accelerators within the modal model".
--
-- `S` goes ONLY in n/o (not in x): in visual, `S` is nvim-surround's
-- wrap (S<char> wraps the selection — see surround.lua).
-- With x here, flash loaded later (VeryLazy > BufReadPost) and silently
-- clobbered that mapping. Treesitter-select in visual still works via `R`.
--
-- Bonus: `r` in operator-pending = remote ops (e.g. `yr` + jump
-- = yank somewhere else without moving the cursor).

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
