-- ─── theme: obsidian ─────────────────────────────────────────
-- Espejo del theme Ghostty `obsidian` (high-contrast dark, cyan).
-- Base tokyonight: variant `night` (la dark más pura del plugin).

local palette = {
  bg          = "#000000",
  bg_dark     = "#0a0a0a",
  bg_highlight= "#0a3a52",
  bg_visual   = "#0a3a52",
  bg_float    = "#0a0a0a",
  bg_popup    = "#0a0a0a",
  bg_search   = "#003844",
  bg_sidebar  = "#0a0a0a",
  bg_statusline = "#0a0a0a",

  fg          = "#e8e8e8",
  fg_dark     = "#a0a0a0",
  fg_gutter   = "#404040",

  black       = "#000000",
  red         = "#ff4565",
  green       = "#3aff80",
  yellow      = "#ffd866",
  blue        = "#5ab0ff",
  magenta     = "#c678ff",
  cyan        = "#00e5ff",       -- ACCENT principal
  white       = "#e8e8e8",

  bright_black   = "#3a3a3a",
  bright_red     = "#ff6b80",
  bright_green   = "#5dff9d",
  bright_yellow  = "#ffe388",
  bright_blue    = "#7fc4ff",
  bright_magenta = "#d899ff",
  bright_cyan    = "#5cf0ff",
  bright_white   = "#ffffff",

  -- bright_black (#3a3a3a) es demasiado oscuro sobre #000 para texto:
  comment     = "#6a6a6a",
  border      = "#3a3a3a",
  cursor      = "#00e5ff",       -- cyan eléctrico
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
    c.border_highlight = palette.cursor  -- cyan acento para focus

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
    c.orange    = palette.cyan          -- no hay coral; el rol "acento principal" lo toma cyan

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#0a0a0a" }
    hl.CursorLineNr = { fg = palette.cursor, bold = true }
    hl.LineNr       = { fg = c.fg_gutter }

    hl.FloatBorder = { fg = palette.border, bg = c.bg_float }
    hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

    hl.TelescopeBorder       = { fg = palette.border, bg = c.bg_float }
    hl.TelescopePromptBorder = { fg = palette.cursor, bg = c.bg_float }
    hl.TelescopeMatching     = { fg = palette.bright_cyan, bold = true }

    hl.GitSignsAdd    = { fg = c.green }
    hl.GitSignsChange = { fg = c.yellow }
    hl.GitSignsDelete = { fg = c.red }

    -- Markdown inline code: bg apenas más claro que el bg principal,
    -- fg magenta para no robarle el cyan a UI/metadatos.
    local code_bg = palette.bg_dark
    local code_fg = palette.bright_magenta
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    -- Headings: jerarquía fría → amarillo de respiro.
    hl["@markup.heading.1.markdown"]   = { fg = palette.cyan,        bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.bright_cyan, bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.yellow,      bold = true }

    hl["@markup.link.url"]   = { fg = palette.bright_cyan, underline = true }
    hl["@markup.link.label"] = { fg = palette.cyan }
  end,
}
