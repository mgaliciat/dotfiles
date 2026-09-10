-- ─── incline.nvim ─────────────────────────────────────────────
-- A floating filename anchored to the top-right corner of every
-- window. Replaces dropbar.nvim (sep-2026), which put a navigable
-- `path → symbol → cursor` breadcrumb in the winbar of each window.
--
-- The trade, deliberately: dropbar answered "where am I inside this
-- file" and cost a permanent row per split plus the `<leader>h` picker;
-- incline answers "which file is this split, and does it have focus"
-- and costs no row at all — it floats over the buffer instead of
-- reserving space. With splits, telling them apart at a glance is the
-- job that actually came up; the breadcrumb was read far less than the
-- row it occupied would suggest. Symbol context is still reachable
-- through the LSP (`gd`, the symbol pickers, treesitter's `]f`/`[f`).
--
-- Don't run both: incline's float lands on the right end of the winbar
-- dropbar draws into, so they overlap and each hides half of the other.
-- That overlap is why incline was dropped in e51e305 (2026-09-06) — a
-- dedupe pass that kept dropbar. This is the same call resolved the
-- other way a day later, not a new plugin: if it goes again, the
-- question to settle first is which of the two owns the winbar, because
-- adding one back on top of the other is what gets undone every time.
--
-- Colours are DERIVED from the active colorscheme, not hardcoded.
-- craftzdog reads `solarized-osaka.colors` directly, which only works
-- because that is the one theme he ships; here `vim.g.theme` selects
-- from a whole matrix (see lua/config/options.lua), so the palette is
-- pulled out of highlight groups every theme is guaranteed to define.
-- `Normal` has no bg under a transparent theme, hence the fallback to
-- `NormalFloat`, which the `floats = "dark"` style keeps opaque. No theme
-- sets `transparent` since the glass was dropped (2026-09-09), so the
-- fallback is currently unused — it stays because it costs one `or` and is
-- exactly what breaks if transparency comes back.

local function hl_hex(group, attr)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  return hl[attr] and string.format("#%06x", hl[attr]) or nil
end

return {
  "b0o/incline.nvim",
  event = "BufReadPre",
  priority = 1200,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local accent = hl_hex("Function", "fg") or "#7aa2f7"
    local canvas = hl_hex("Normal", "bg") or hl_hex("NormalFloat", "bg") or "#000000"
    local muted  = hl_hex("Comment", "fg") or "#666666"

    require("incline").setup({
      highlight = {
        groups = {
          InclineNormal   = { guibg = accent, guifg = canvas },
          InclineNormalNC = { guibg = canvas, guifg = muted },
        },
      },
      window = { margin = { vertical = 0, horizontal = 1 } },
      -- The float sits on the first row of the window, so it covers text
      -- whenever the cursor is up there; hiding it on the cursor line
      -- gives the line back while you're editing it.
      hide = { cursorline = true },
      render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
        if filename == "" then filename = "[No Name]" end
        if vim.bo[props.buf].modified then
          filename = "[+] " .. filename
        end

        local icon, color = require("nvim-web-devicons").get_icon_color(filename)
        if not icon then return { filename } end
        return { { icon, guifg = color }, { " " }, { filename } }
      end,
    })
  end,
}
