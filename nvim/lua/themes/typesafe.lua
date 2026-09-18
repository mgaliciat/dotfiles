-- ─── theme: typesafe ─────────────────────────────────────────
-- The sage canvas of typesafe.ai + near-black ink. Mirror of the Ghostty
-- theme `typesafe` and tmux/themes/typesafe.conf.
-- tokyonight base: variant `day` (the plugin's light one).
--
-- Canvas #abbab9 and the black text (#000 token) are the page's own CSS,
-- verbatim; the teal #09aea1 is its accent token. The site is a Framer build with no 16-colour
-- set and its accents are too light to read as text on the canvas, so the
-- ANSI slots are derived: same hue, darkened past 3:1 (normals) / 4.3:1
-- (brights). Provenance and the contrast figures are in the ghostty file.
--
-- Light theme convention: the "bright" colors are DARKER than the
-- normal ones (more contrast over a light background).

local palette = {
  bg          = "#abbab9",       -- page canvas
  bg_dark     = "#9dabaa",       -- canvas half a step down — ANSI 0 dimmed / code bg
  bg_highlight= "#a3b2b1",       -- cursorline
  bg_visual   = "#8fa09f",       -- selection, one full step down
  bg_float    = "#a3b2b1",
  bg_popup    = "#a3b2b1",
  bg_search   = "#c9c58a",       -- muted yellow over sage
  bg_sidebar  = "#a3b2b1",
  bg_statusline = "#a3b2b1",

  fg          = "#000000",       -- the page's #000 token; #1e1e1e ink stays in ANSI 7
  fg_dark     = "#3f4b4a",
  fg_gutter   = "#7d8c8b",

  black       = "#3d4746",
  red         = "#a8283f",
  green       = "#046637",
  yellow      = "#7a5d08",
  blue        = "#1f5f8c",
  magenta     = "#9a2f80",
  cyan        = "#06655e",
  white       = "#1e1e1e",

  bright_black   = "#4f5b5a",   -- comment color
  bright_red     = "#8a1a30",
  bright_green   = "#034d2a",
  bright_yellow  = "#5e4705",
  bright_blue    = "#164a70",
  bright_magenta = "#7a2064",
  bright_cyan    = "#044f49",
  bright_white   = "#000000",

  comment     = "#4f5b5a",
  border      = "#7d8c8b",
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
