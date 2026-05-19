-- ─── theme: paper ────────────────────────────────────────────
-- Espejo del theme Ghostty `anthropic-paper` (light cream + sepia).
-- Base tokyonight: variant `day` (la light del plugin).
--
-- Convención light theme: los "bright" son MÁS OSCUROS que los
-- normales (más saturación = más contraste sobre fondo claro).
-- Al revés de los dark themes.

local palette = {
  bg          = "#f5ead0",       -- paper cream
  bg_dark     = "#ede0c2",       -- ANSI 0 dimmed
  bg_highlight= "#d4c298",       -- selection bg, cursorline visual
  bg_visual   = "#d4c298",
  bg_float    = "#ede0c2",
  bg_popup    = "#ede0c2",
  bg_search   = "#e8c068",       -- amarillo apagado
  bg_sidebar  = "#ede0c2",
  bg_statusline = "#ede0c2",

  fg          = "#2a1f15",       -- ink sepia
  fg_dark     = "#5a4830",
  fg_gutter   = "#b0a280",

  black       = "#3a2e1f",
  red         = "#b8493a",
  green       = "#6b8f4a",
  yellow      = "#c08a1e",
  blue        = "#5a7a8e",
  magenta     = "#8a5a3f",
  cyan        = "#5a8a7e",
  white       = "#2a1f15",

  bright_black   = "#7a6a55",   -- color de comentarios
  bright_red     = "#9a3520",
  bright_green   = "#557030",
  bright_yellow  = "#a07010",
  bright_blue    = "#456080",
  bright_magenta = "#70432f",
  bright_cyan    = "#3f6f60",
  bright_white   = "#1a1208",

  comment     = "#7a6a55",
  border      = "#b0a280",
  cursor      = "#d97757",       -- Claude coral
}

return {
  style = "day",
  palette = palette,

  on_colors = function(c)
    c.bg            = palette.bg
    c.bg_dark       = palette.bg_dark
    c.bg_float      = palette.bg_float
    c.bg_popup      = palette.bg_popup
    c.bg_search     = palette.bg_search
    c.bg_sidebar    = palette.bg_sidebar
    c.bg_statusline = palette.bg_statusline
    c.bg_highlight  = palette.bg_highlight
    c.bg_visual     = palette.bg_visual

    c.fg            = palette.fg
    c.fg_dark       = palette.fg_dark
    c.fg_gutter     = palette.fg_gutter
    c.fg_sidebar    = palette.fg_dark
    c.fg_float      = palette.fg

    c.comment       = palette.comment
    c.border        = palette.border
    c.border_highlight = palette.cursor  -- coral acento para focus

    c.red       = palette.red
    c.red1      = palette.bright_red
    c.green     = palette.green
    c.green1    = palette.bright_green
    c.green2    = palette.green
    c.yellow    = palette.yellow
    c.blue      = palette.blue
    c.blue0     = palette.bright_blue
    c.blue1     = palette.bright_blue
    c.blue2     = palette.blue
    c.blue5     = palette.cyan
    c.blue6     = palette.bright_cyan
    c.blue7     = palette.bright_blue
    c.cyan      = palette.cyan
    c.magenta   = palette.magenta
    c.magenta2  = palette.bright_magenta
    c.purple    = palette.magenta
    c.orange    = palette.cursor          -- coral toma el rol "naranja semántico"

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#ebe0c0" }
    hl.CursorLineNr = { fg = palette.cursor, bold = true }
    hl.LineNr       = { fg = c.fg_gutter }

    hl.FloatBorder = { fg = palette.border, bg = c.bg_float }
    hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

    hl.TelescopeBorder       = { fg = palette.border, bg = c.bg_float }
    hl.TelescopePromptBorder = { fg = palette.cursor, bg = c.bg_float }
    hl.TelescopeMatching     = { fg = palette.bright_red, bold = true }

    hl.GitSignsAdd    = { fg = c.green }
    hl.GitSignsChange = { fg = c.yellow }
    hl.GitSignsDelete = { fg = c.red }

    -- Inline code: cream tostado + terracota saturada.
    local code_bg = palette.bg_dark
    local code_fg = palette.bright_red
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    hl["@markup.heading.1.markdown"]   = { fg = palette.bright_red, bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.cursor,     bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.yellow,     bold = true }

    hl["@markup.link.url"]   = { fg = palette.blue, underline = true }
    hl["@markup.link.label"] = { fg = palette.cursor }
  end,
}
