-- ─── theme: gray ─────────────────────────────────────────────
-- Mirror of the Ghostty theme `gray` (neutral gray bg + near-black ink).
-- tokyonight base: variant `day` (the plugin's light one).
--
-- Light/gray theme convention: the "bright" colors are DARKER than the
-- normal ones (more saturation = more contrast over the gray background).

local palette = {
  bg          = "#b5b5b5",       -- neutral gray
  bg_dark     = "#a8a8a8",       -- ANSI 0 dimmed
  bg_highlight= "#969696",       -- selection bg, cursorline visual
  bg_visual   = "#969696",
  bg_float    = "#a8a8a8",
  bg_popup    = "#a8a8a8",
  bg_search   = "#c8b050",       -- muted yellow
  bg_sidebar  = "#a8a8a8",
  bg_statusline = "#a8a8a8",

  fg          = "#0e0e0e",       -- near-black ink
  fg_dark     = "#3a3a3a",
  fg_gutter   = "#767676",

  black       = "#1a1a1a",
  red         = "#a03028",
  green       = "#3f6f2f",
  yellow      = "#8a6a10",
  blue        = "#2f5a80",
  magenta     = "#7a3f6a",
  cyan        = "#2f6f6a",
  white       = "#0e0e0e",

  bright_black   = "#4a4a4a",   -- comment color
  bright_red     = "#802015",
  bright_green   = "#2f5a20",
  bright_yellow  = "#6a5008",
  bright_blue    = "#204560",
  bright_magenta = "#5a2f50",
  bright_cyan    = "#1f5550",
  bright_white   = "#000000",

  comment     = "#4a4a4a",
  border      = "#767676",
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
    c.border_highlight = palette.cursor  -- coral accent for focus

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
    c.orange    = palette.cursor          -- coral takes the "semantic orange" role

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#aaaaaa" }
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

    -- Inline code: darker gray + saturated terracotta.
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
