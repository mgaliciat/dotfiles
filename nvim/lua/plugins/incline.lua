-- ─── incline.nvim ─────────────────────────────────────────────
-- Floating filename in the top-right corner of each split.
-- Solves the classic problem: the statusline (lualine) only shows
-- the path of the active split — in layouts with 3+ windows you don't know
-- which file is which without focusing it first.
--
-- Colors: derived from the ACTIVE stack theme (vim.g.theme) so that the
-- indicator follows the cross-stack palette — the versioned family lives in
-- lua/themes/<id>.lua, where we get accent/bg from. solarized-osaka is the
-- plugin (it has no themes/<id>.lua), so for it we fall back to its native
-- palette. Active (focus): box with bg=accent and dark text. NC (inactive):
-- dim fg over a floating bg.

return {
  "b0o/incline.nvim",
  dependencies = {
    "craftzdog/solarized-osaka.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  event = "BufReadPre",
  priority = 1200,
  config = function()
    -- By default: solarized-osaka palette (covers osaka and any id without a
    -- themes/<id>.lua module). If the active theme DOES have a module, we use it.
    local accent, bg_active, fg_nc, bg_nc
    local pal_ok, mod = pcall(require, "themes." .. (vim.g.theme or "carbon"))
    if pal_ok and type(mod) == "table" and mod.palette then
      local p = mod.palette
      -- `accent` doesn't exist in every theme (anthropic-warm/paper/obsidian
      -- only define `cursor`); cursor IS the focus color, so it works as a
      -- fallback. Without this, those themes left guibg=nil → indicator with no bg.
      accent    = p.accent or p.cursor
      bg_active = p.bg_float or p.bg
      fg_nc     = p.fg_dark or p.comment
      bg_nc     = p.bg_float or p.bg_dark or p.bg
    else
      local ok, sol = pcall(require, "solarized-osaka.colors")
      local c = ok and sol.setup() or {
        magenta500 = "#d33682", base03 = "#002b36",
        base04     = "#001e26", violet500 = "#6c71c4",
      }
      accent, bg_active, fg_nc, bg_nc = c.magenta500, c.base04, c.violet500, c.base03
    end

    require("incline").setup({
      highlight = {
        groups = {
          InclineNormal   = { guibg = accent, guifg = bg_active },
          InclineNormalNC = { guifg = fg_nc,  guibg = bg_nc },
        },
      },
      window = { margin = { vertical = 0, horizontal = 1 } },
      -- Hides the indicator when the cursor is on the same row so
      -- it doesn't cover text.
      hide = { cursorline = true },
      render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
        if filename == "" then filename = "[No Name]" end
        if vim.bo[props.buf].modified then
          filename = "[+] " .. filename
        end
        local icon, color = require("nvim-web-devicons").get_icon_color(filename)
        return { { icon, guifg = color }, { " " }, { filename } }
      end,
    })
  end,
}
