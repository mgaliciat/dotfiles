-- ─── colorscheme: anthropic-paper ────────────────────────────
-- Paleta espejo del theme Ghostty `anthropic-paper` para que
-- terminal y editor compartan look. Base: tokyonight-day
-- (variant light, ~200 highlight groups ya afinados para fondo
-- claro); override total de la paleta vía on_colors + on_highlights
-- para no re-implementar todos los grupos a mano.
--
-- Si cambias el theme de Ghostty, actualizá también esta paleta —
-- son la misma fuente de verdad conceptual, dos archivos físicos
-- (ghostty/themes/anthropic-paper ↔ este archivo).
--
-- Convención light theme: los "bright" son MÁS OSCUROS que los
-- normales (más saturación = más contraste sobre fondo claro).
-- Al revés de los dark themes.

local paper = {
  -- Base
  bg          = "#f5ead0",   -- background (paper cream)
  bg_dark     = "#ede0c2",   -- ANSI 0 dimmed — sidebar, float bg
  bg_highlight= "#d4c298",   -- selection bg, cursorline visual
  bg_visual   = "#d4c298",
  bg_float    = "#ede0c2",
  bg_popup    = "#ede0c2",
  bg_search   = "#e8c068",   -- amarillo apagado para search match
  bg_sidebar  = "#ede0c2",
  bg_statusline = "#ede0c2",

  fg          = "#2a1f15",   -- ink sepia (texto principal)
  fg_dark     = "#5a4830",   -- fg menos prominente (línea inactiva)
  fg_gutter   = "#b0a280",   -- línea de números, signs

  -- ANSI palette (espejo de ghostty/themes/anthropic-paper)
  black       = "#3a2e1f",
  red         = "#b8493a",
  green       = "#6b8f4a",
  yellow      = "#c08a1e",
  blue        = "#5a7a8e",
  magenta     = "#8a5a3f",
  cyan        = "#5a8a7e",
  white       = "#2a1f15",

  -- Brights (más oscuros que normales en light theme)
  bright_black   = "#7a6a55",   -- ← color de comentarios (típico ANSI 8)
  bright_red     = "#9a3520",
  bright_green   = "#557030",
  bright_yellow  = "#a07010",
  bright_blue    = "#456080",
  bright_magenta = "#70432f",
  bright_cyan    = "#3f6f60",
  bright_white   = "#1a1208",

  -- Derivados semánticos
  comment     = "#7a6a55",   -- bright_black — legible pero apagado
  border      = "#b0a280",
  cursor      = "#d97757",   -- Claude orange (igual que ghostty cursor)
}

return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    style = "day",           -- variant LIGHT (no "night")
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
      c.bg            = paper.bg
      c.bg_dark       = paper.bg_dark
      c.bg_float      = paper.bg_float
      c.bg_popup      = paper.bg_popup
      c.bg_search     = paper.bg_search
      c.bg_sidebar    = paper.bg_sidebar
      c.bg_statusline = paper.bg_statusline
      c.bg_highlight  = paper.bg_highlight
      c.bg_visual     = paper.bg_visual

      c.fg            = paper.fg
      c.fg_dark       = paper.fg_dark
      c.fg_gutter     = paper.fg_gutter
      c.fg_sidebar    = paper.fg_dark
      c.fg_float      = paper.fg

      c.comment       = paper.comment
      c.border        = paper.border
      c.border_highlight = paper.cursor   -- coral acento para focus

      -- Mapeo ANSI → roles semánticos del theme
      c.red           = paper.red
      c.red1          = paper.bright_red
      c.green         = paper.green
      c.green1        = paper.bright_green
      c.green2        = paper.green
      c.yellow        = paper.yellow
      c.blue          = paper.blue
      c.blue0         = paper.bright_blue
      c.blue1         = paper.bright_blue
      c.blue2         = paper.blue
      c.blue5         = paper.cyan
      c.blue6         = paper.bright_cyan
      c.blue7         = paper.bright_blue
      c.cyan          = paper.cyan
      c.magenta       = paper.magenta
      c.magenta2      = paper.bright_magenta
      c.purple        = paper.magenta
      c.orange        = paper.cursor      -- coral Claude para "orange" semántico

      -- Git diff (alineado con gitsigns)
      c.git = {
        add    = paper.green,
        change = paper.yellow,
        delete = paper.red,
      }

      -- Terminal embebido (:terminal) usa la misma paleta ANSI
      c.terminal_black = paper.bright_black
    end,
    on_highlights = function(hl, c)
      -- Cursorline más sutil que la selection (evita confusión visual).
      -- Sobre fondo claro: un cream un poco más sucio que el bg principal.
      hl.CursorLine = { bg = "#ebe0c0" }
      hl.CursorLineNr = { fg = paper.cursor, bold = true }
      hl.LineNr = { fg = c.fg_gutter }

      -- Floating windows con borde tierra (look "paper kraft")
      hl.FloatBorder = { fg = paper.border, bg = c.bg_float }
      hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

      -- Telescope: borde tierra, prompt destacado en coral
      hl.TelescopeBorder       = { fg = paper.border, bg = c.bg_float }
      hl.TelescopePromptBorder = { fg = paper.cursor, bg = c.bg_float }
      hl.TelescopeMatching     = { fg = paper.bright_red, bold = true }

      -- Diff signs (gitsigns / signcolumn)
      hl.GitSignsAdd    = { fg = c.green }
      hl.GitSignsChange = { fg = c.yellow }
      hl.GitSignsDelete = { fg = c.red }

      -- ─── markdown inline code ───────────────────────────────
      -- tokyonight-day por default pinta `inline code` con bg
      -- gris-azulado oscuro que sobre cream queda como bloque
      -- pesado con texto casi invisible. Lo reemplazamos por
      -- "paper card": fondo cream tostado (apenas más oscuro
      -- que el bg principal) + fg terracota saturada.
      -- Cubrimos los tres nombres porque tokyonight setea unos,
      -- treesitter otros, y vim-markdown otros más.
      local code_bg = paper.bg_dark      -- #ede0c2
      local code_fg = paper.bright_red   -- #9a3520
      hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
      hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
      hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
      hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
      hl.markdownCode                    = { bg = code_bg, fg = code_fg }
      hl.markdownCodeDelimiter           = { fg = paper.fg_gutter } -- backticks discretos

      -- Code blocks (fenced ```): mismo bg para coherencia visual.
      hl["@markup.raw.block"]            = { bg = code_bg }
      hl.markdownCodeBlock               = { bg = code_bg }

      -- Headings markdown: jerarquía clara en sepia + acentos.
      hl["@markup.heading.1.markdown"]   = { fg = paper.bright_red, bold = true }
      hl["@markup.heading.2.markdown"]   = { fg = paper.cursor,     bold = true }
      hl["@markup.heading.3.markdown"]   = { fg = paper.yellow,     bold = true }

      -- Links: azul humo subrayado (look "tinta sobre papel").
      hl["@markup.link.url"]             = { fg = paper.blue, underline = true }
      hl["@markup.link.label"]           = { fg = paper.cursor }
    end,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight-day")
  end,
}
