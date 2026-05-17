-- ─── colorscheme: blueprint-engineering ──────────────────────
-- Paleta espejo del theme Ghostty `blueprint-engineering` para que
-- terminal y editor compartan look. Base: tokyonight-night
-- (~200 highlight groups ya afinados para LSP/treesitter/telescope/
-- gitsigns); override total de la paleta vía on_colors + on_highlights
-- para evitar re-implementar todos los grupos a mano.
--
-- Si cambias el theme de Ghostty, actualiza también esta paleta —
-- son la misma fuente de verdad conceptual, dos archivos físicos
-- (ghostty/themes/blueprint-engineering ↔ este archivo).

local blueprint = {
  -- Base
  bg          = "#0e2a47",   -- background
  bg_dark     = "#0a223a",   -- ANSI 0 (más oscuro que bg) — sidebar, float bg
  bg_highlight= "#1e4571",   -- selection bg, cursorline
  bg_visual   = "#1e4571",
  bg_float    = "#0a223a",
  bg_popup    = "#0a223a",
  bg_search   = "#3b5675",
  bg_sidebar  = "#0a223a",
  bg_statusline = "#0a223a",

  fg          = "#cde3f5",   -- foreground principal
  fg_dark     = "#a5c4dc",   -- fg menos prominente (línea inactiva)
  fg_gutter   = "#3b5675",   -- números de línea, signs

  -- ANSI palette
  black       = "#0a223a",
  red         = "#e87a7a",
  green       = "#7fdca4",
  yellow      = "#e8c468",
  blue        = "#5a9fff",
  magenta     = "#c89fff",
  cyan        = "#7dd3fc",
  white       = "#cde3f5",

  -- Brights
  bright_black   = "#3b5675",   -- ← color de comentarios (típico ANSI 8)
  bright_red     = "#ff9999",
  bright_green   = "#9ce4b8",
  bright_yellow  = "#f5d27c",
  bright_blue    = "#85b8ff",
  bright_magenta = "#d8b8ff",
  bright_cyan    = "#a5dff5",
  bright_white   = "#e8f4ff",

  -- Derivados semánticos
  comment     = "#3b5675",   -- bright_black — apagado pero legible sobre bg
  border      = "#3b5675",
  cursor      = "#7dd3fc",
}

return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    style = "night",
    transparent = false,
    terminal_colors = true,
    styles = {
      comments = { italic = true },
      keywords = { italic = false },
      functions = {},
      variables = {},
      sidebars = "dark",
      floats = "dark",
    },
    -- on_colors: reemplaza la paleta interna del theme. Todos los
    -- highlight groups que dependen de estos colores se actualizan
    -- automáticamente. Esto es por qué usamos tokyonight en vez de
    -- escribir el theme from scratch.
    on_colors = function(c)
      c.bg            = blueprint.bg
      c.bg_dark       = blueprint.bg_dark
      c.bg_float      = blueprint.bg_float
      c.bg_popup      = blueprint.bg_popup
      c.bg_search     = blueprint.bg_search
      c.bg_sidebar    = blueprint.bg_sidebar
      c.bg_statusline = blueprint.bg_statusline
      c.bg_highlight  = blueprint.bg_highlight
      c.bg_visual     = blueprint.bg_visual

      c.fg            = blueprint.fg
      c.fg_dark       = blueprint.fg_dark
      c.fg_gutter     = blueprint.fg_gutter
      c.fg_sidebar    = blueprint.fg_dark
      c.fg_float      = blueprint.fg

      c.comment       = blueprint.comment
      c.border        = blueprint.border
      c.border_highlight = blueprint.cyan

      -- Mapeo ANSI → roles semánticos del theme
      c.red           = blueprint.red
      c.red1          = blueprint.bright_red
      c.green         = blueprint.green
      c.green1        = blueprint.bright_green
      c.green2        = blueprint.green
      c.yellow        = blueprint.yellow
      c.blue          = blueprint.blue
      c.blue0         = blueprint.bright_blue
      c.blue1         = blueprint.bright_blue
      c.blue2         = blueprint.blue
      c.blue5         = blueprint.cyan
      c.blue6         = blueprint.bright_cyan
      c.blue7         = blueprint.bright_blue
      c.cyan          = blueprint.cyan
      c.magenta       = blueprint.magenta
      c.magenta2      = blueprint.bright_magenta
      c.purple        = blueprint.magenta
      c.orange        = blueprint.yellow      -- blueprint no tiene orange; uso ámbar

      -- Git diff (alineado con gitsigns)
      c.git = {
        add    = blueprint.green,
        change = blueprint.yellow,
        delete = blueprint.red,
      }

      -- Terminal embebido (:terminal) usa la misma paleta ANSI
      c.terminal_black = blueprint.bright_black
    end,
    on_highlights = function(hl, c)
      -- Cursorline más sutil que la selection (evita confusión visual)
      hl.CursorLine = { bg = "#143256" }
      hl.CursorLineNr = { fg = c.cyan, bold = true }
      hl.LineNr = { fg = c.fg_gutter }

      -- Floating windows con borde cyan (look "blueprint technical")
      hl.FloatBorder = { fg = c.cyan, bg = c.bg_float }
      hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

      -- Telescope: borde cyan, prompt destacado
      hl.TelescopeBorder       = { fg = c.cyan, bg = c.bg_float }
      hl.TelescopePromptBorder = { fg = c.cyan, bg = c.bg_float }
      hl.TelescopeMatching     = { fg = c.yellow, bold = true }

      -- Diff signs (gitsigns / signcolumn)
      hl.GitSignsAdd    = { fg = c.green }
      hl.GitSignsChange = { fg = c.yellow }
      hl.GitSignsDelete = { fg = c.red }
    end,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight-night")
  end,
}
