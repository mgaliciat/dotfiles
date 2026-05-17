-- ─── lualine.nvim ─────────────────────────────────────────────
-- Statusline. Paleta espejo de `blueprint-engineering` (Ghostty).
-- Si cambias el theme, sincronizá esta paleta con la de
-- plugins/colorscheme.lua — son conceptualmente la misma fuente.

local bp = {
  cyan      = "#7dd3fc",   -- modo normal
  green     = "#7fdca4",   -- modo insert
  yellow    = "#e8c468",   -- modo visual
  red       = "#e87a7a",   -- modo replace
  blue      = "#5a9fff",   -- modo command
  bg        = "#0e2a47",
  bg_alt    = "#0a223a",
  fg        = "#cde3f5",
  fg_dim    = "#a5c4dc",
}

local theme = {
  normal = {
    a = { bg = bp.cyan,   fg = bp.bg, gui = "bold" },
    b = { bg = bp.bg_alt, fg = bp.fg },
    c = { bg = bp.bg,     fg = bp.fg_dim },
  },
  insert  = { a = { bg = bp.green,  fg = bp.bg, gui = "bold" } },
  visual  = { a = { bg = bp.yellow, fg = bp.bg, gui = "bold" } },
  replace = { a = { bg = bp.red,    fg = bp.bg, gui = "bold" } },
  command = { a = { bg = bp.blue,   fg = bp.bg, gui = "bold" } },
  inactive = {
    a = { bg = bp.bg, fg = bp.fg_dim },
    b = { bg = bp.bg, fg = bp.fg_dim },
    c = { bg = bp.bg, fg = bp.fg_dim },
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
