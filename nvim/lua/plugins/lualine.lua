-- ─── lualine.nvim ─────────────────────────────────────────────
-- Statusline. Paleta espejo de `anthropic-paper` (Ghostty).
-- Si cambias el theme, sincronizá esta paleta con la de
-- plugins/colorscheme.lua — son conceptualmente la misma fuente.
--
-- Convención light theme: los segments de modo usan colores
-- saturados (brights, más oscuros) como bg con fg cream — el
-- mismo patrón contraste-fuerte que el blueprint, pero invertido
-- en luminosidad para que se lea sobre fondo claro.

local pp = {
  -- Mode highlights (saturados, contraste vs cream)
  blue      = "#456080",   -- modo normal (bright_blue)
  green     = "#557030",   -- modo insert (bright_green)
  yellow    = "#a07010",   -- modo visual (bright_yellow)
  red       = "#9a3520",   -- modo replace (bright_red)
  coral     = "#d97757",   -- modo command (Claude orange acento)

  -- Surfaces
  bg        = "#f5ead0",   -- bg principal (paper cream)
  bg_alt    = "#ede0c2",   -- bg secciones b (un poco más sucio)
  fg        = "#2a1f15",   -- ink sepia
  fg_dim    = "#7a6a55",   -- bright_black — inactive segments
  fg_cream  = "#f5ead0",   -- fg sobre mode highlights oscuros
}

local theme = {
  normal = {
    a = { bg = pp.blue,   fg = pp.fg_cream, gui = "bold" },
    b = { bg = pp.bg_alt, fg = pp.fg },
    c = { bg = pp.bg,     fg = pp.fg_dim },
  },
  insert  = { a = { bg = pp.green,  fg = pp.fg_cream, gui = "bold" } },
  visual  = { a = { bg = pp.yellow, fg = pp.fg_cream, gui = "bold" } },
  replace = { a = { bg = pp.red,    fg = pp.fg_cream, gui = "bold" } },
  command = { a = { bg = pp.coral,  fg = pp.fg_cream, gui = "bold" } },
  inactive = {
    a = { bg = pp.bg, fg = pp.fg_dim },
    b = { bg = pp.bg, fg = pp.fg_dim },
    c = { bg = pp.bg, fg = pp.fg_dim },
  },
}

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = theme,
      component_separators = "",
      section_separators = { left = "", right = "" },
      globalstatus = true,
      disabled_filetypes = { statusline = { "dashboard", "alpha" } },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", { "diff", symbols = { added = " ", modified = " ", removed = " " } } },
      lualine_c = {
        { "filename", path = 1 },
        { "diagnostics", sources = { "nvim_lsp" } },
      },
      lualine_x = { "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  },
}
