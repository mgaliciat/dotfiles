-- ─── theme: typesafe ─────────────────────────────────────────
-- The sage canvas of typesafe.ai + near-black ink. Mirror of the Ghostty
-- theme `typesafe` and tmux/themes/typesafe.conf.
-- tokyonight base: variant `day` (the plugin's light one).
--
-- Canvas #abbab9 and the teal #09aea1 (cursor, borders) are the page's own
-- CSS, verbatim. Everything else is tuned to that canvas in OKLCH, same recipe
-- as typesafe-dark: the page's tokens give the HUES, lightness and chroma are
-- set per role (normals L 0.43, brights 0.34, neutrals carry the canvas hue,
-- the bg ladder steps down evenly). Figures and rationale are in the ghostty
-- file.
--
-- Light theme convention: the "bright" colors are DARKER than the
-- normal ones (more contrast over a light background).

local palette = {
  bg          = "#abbab9",       -- page canvas, L 0.777
  bg_dark     = "#a1b0af",       -- L 0.745 — code bg
  bg_highlight= "#a4b3b2",       -- L 0.755 — cursorline
  bg_visual   = "#94a4a3",       -- L 0.705 — selection
  bg_float    = "#a4b3b2",
  bg_popup    = "#a4b3b2",
  bg_search   = "#d5ba82",       -- the yellow hue at L 0.80
  bg_sidebar  = "#a4b3b2",
  bg_statusline = "#a4b3b2",

  fg          = "#0a1110",       -- sage-tinted near-black, L 0.17
  fg_dark     = "#303a3a",       -- L 0.34
  fg_gutter   = "#697877",       -- L 0.56

  black       = "#2f3b3a",
  red         = "#901c32",
  green       = "#026031",
  yellow      = "#735601",
  blue        = "#005581",
  magenta     = "#80246c",
  cyan        = "#065d55",
  white       = "#1a2120",

  bright_black   = "#45504f",   -- comment color, L 0.42 (4.2:1)
  bright_red     = "#6c0027",
  bright_green   = "#004424",
  bright_yellow  = "#533f03",
  bright_blue    = "#033c5b",
  bright_magenta = "#610951",
  bright_cyan    = "#03413c",
  bright_white   = "#020505",

  comment     = "#45504f",
  border      = "#748483",       -- L 0.60
  cursor      = "#09aea1",       -- the page's teal, verbatim
  accent      = "#09aea1",
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
    c.border_highlight = palette.accent  -- teal for focus

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
    c.orange    = palette.bright_yellow   -- no orange on the page; amber takes the role

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = palette.bg_highlight }
    hl.CursorLineNr = { fg = palette.bright_cyan, bold = true }
    hl.LineNr       = { fg = c.fg_gutter }

    hl.FloatBorder = { fg = palette.border, bg = c.bg_float }
    hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

    hl.TelescopeBorder       = { fg = palette.border, bg = c.bg_float }
    hl.TelescopePromptBorder = { fg = palette.accent, bg = c.bg_float }
    hl.TelescopeMatching     = { fg = palette.bright_red, bold = true }

    hl.GitSignsAdd    = { fg = c.green }
    hl.GitSignsChange = { fg = c.yellow }
    hl.GitSignsDelete = { fg = c.red }

    -- Inline code: darker sage + the dark teal, the page's accent hue.
    local code_bg = palette.bg_dark
    local code_fg = palette.bright_cyan
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    hl["@markup.heading.1.markdown"]   = { fg = palette.fg,             bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.bright_cyan,    bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.bright_magenta, bold = true }

    hl["@markup.link.url"]   = { fg = palette.blue, underline = true }
    hl["@markup.link.label"] = { fg = palette.bright_cyan }
  end,
}
