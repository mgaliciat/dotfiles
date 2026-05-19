-- ─── theme: warm ─────────────────────────────────────────────
-- Espejo del theme Ghostty `anthropic-warm` (dark sepia/naranja).
-- Base tokyonight: variant `night`.
--
-- Convención dark theme: los "bright" son MÁS CLAROS que los normales.

local palette = {
  bg          = "#1a1814",       -- dark warm (no negro puro, tira a sepia)
  bg_dark     = "#14110d",       -- más oscuro para sidebars
  bg_highlight= "#3a2e1f",       -- selection bg
  bg_visual   = "#3a2e1f",
  bg_float    = "#14110d",
  bg_popup    = "#14110d",
  bg_search   = "#5a4520",       -- ámbar oscuro saturado para search match
  bg_sidebar  = "#14110d",
  bg_statusline = "#14110d",

  fg          = "#e8dcc4",       -- cream warm
  fg_dark     = "#a89880",
  fg_gutter   = "#4a3f33",

  black       = "#1a1814",
  red         = "#c8553d",
  green       = "#87a96b",
  yellow      = "#d9a441",
  blue        = "#6b8e9e",
  magenta     = "#b08968",
  cyan        = "#8aa9a1",
  white       = "#c4b8a0",

  bright_black   = "#4a3f33",
  bright_red     = "#e07856",
  bright_green   = "#a3c485",
  bright_yellow  = "#e8c068",
  bright_blue    = "#8aabbc",
  bright_magenta = "#d97757",   -- Claude coral
  bright_cyan    = "#a5c4bc",
  bright_white   = "#f5ead0",

  comment     = "#8a7a60",       -- gris-tierra medio sobre bg warm
  border      = "#4a3f33",
  cursor      = "#d97757",       -- Claude coral
}

return {
  style = "night",
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
    hl.CursorLine   = { bg = "#221e18" }       -- apenas más claro que bg
    hl.CursorLineNr = { fg = palette.cursor, bold = true }
    hl.LineNr       = { fg = c.fg_gutter }

    hl.FloatBorder = { fg = palette.border, bg = c.bg_float }
    hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

    hl.TelescopeBorder       = { fg = palette.border, bg = c.bg_float }
    hl.TelescopePromptBorder = { fg = palette.cursor, bg = c.bg_float }
    hl.TelescopeMatching     = { fg = palette.bright_yellow, bold = true }

    hl.GitSignsAdd    = { fg = c.green }
    hl.GitSignsChange = { fg = c.yellow }
    hl.GitSignsDelete = { fg = c.red }

    -- Inline code: bg apenas más oscuro que el bg principal,
    -- fg coral cálido (rebota con el acento del cursor).
    local code_bg = palette.bg_dark
    local code_fg = palette.bright_magenta   -- = #d97757 coral
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    -- Headings: jerarquía cálida coral → ámbar → verde oliva.
    hl["@markup.heading.1.markdown"]   = { fg = palette.cursor,         bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.bright_yellow,  bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.bright_green,   bold = true }

    hl["@markup.link.url"]   = { fg = palette.bright_blue, underline = true }
    hl["@markup.link.label"] = { fg = palette.cursor }
  end,
}
