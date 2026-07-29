-- ─── dial.nvim ────────────────────────────────────────────────
-- Replaces vanilla <C-a>/<C-x> with "smart" increment:
--   42        → 43             (numbers, vim already did this)
--   0xff      → 0x100           (hex)
--   true      → false           (bool toggle)
--   2024/01/15 → 2024/01/16      (dates)
--   1.2.3     → 1.2.4            (semver)
--   let       → const            (cycles {let, const})
--
-- Keymaps:
--   <C-a> / <C-x>    increment/decrement (smart) — straight to dial
--   +                same via remap (keymaps.lua `+` → <C-a>)
--   -                ⚠️ NOT available: oil.nvim grabs `-` for
--                    "open parent dir". Use <C-x> for decrement.

return {
  "monaqa/dial.nvim",
  keys = {
    { "<C-a>", function() return require("dial.map").inc_normal() end, expr = true, desc = "Increment (smart)" },
    { "<C-x>", function() return require("dial.map").dec_normal() end, expr = true, desc = "Decrement (smart)" },
    { "<C-a>", function() return require("dial.map").inc_visual() end, expr = true, mode = "v", desc = "Increment (visual)" },
    { "<C-x>", function() return require("dial.map").dec_visual() end, expr = true, mode = "v", desc = "Decrement (visual)" },
  },
  config = function()
    local augend = require("dial.augend")
    require("dial.config").augends:register_group({
      default = {
        augend.integer.alias.decimal,
        augend.integer.alias.hex,
        augend.date.alias["%Y/%m/%d"],
        augend.date.alias["%Y-%m-%d"],
        augend.constant.alias.bool,
        augend.semver.alias.semver,
        augend.constant.new({ elements = { "let", "const" } }),
        augend.constant.new({ elements = { "and", "or" } }),
        augend.constant.new({ elements = { "&&", "||" } }),
      },
    })
  end,
}
