-- ─── theme: typesafe-dark ────────────────────────────────────
-- The sage of typesafe.ai taken down to a night canvas. Mirror of the Ghostty
-- theme `typesafe-dark` and tmux/themes/typesafe-dark.conf; dark companion of
-- `typesafe`, built from the same page tokens.
-- tokyonight base: variant `night`.
--
-- The page has no dark mode, so the canvas #182221 is derived: the sage hue of
-- #abbab9 at 11% lightness, saturation raised 10% → 17% so it does not read as
-- plain gray. Over this canvas the page's own accents (teal #09aea1, green
-- #03aa5c, magenta #d45bb6, pink #f386a1, gray #858585, whites #dedede/#fefefe)
-- clear 4.5:1 as they are and go in verbatim; red, yellow, blue and the
-- lighter brights are constructed. Contrast figures are in the ghostty file.
--
-- Dark theme convention: the "bright" colors are LIGHTER than the normal ones.

local palette = {
  bg          = "#182221",       -- derived night canvas
  bg_dark     = "#111818",       -- canvas one step down — code bg
  bg_highlight= "#1f2b2a",       -- cursorline, one step up
  bg_visual   = "#2c3a39",       -- selection, two steps up
  bg_float    = "#1f2b2a",
  bg_popup    = "#1f2b2a",
  bg_search   = "#5a4a15",       -- dark amber over the night sage
  bg_sidebar  = "#1f2b2a",
  bg_statusline = "#1f2b2a",

  fg          = "#dedede",       -- the page's #dedede token; #fefefe stays in ANSI 15
  fg_dark     = "#a9b5b4",
  fg_gutter   = "#5f6f6e",

  black       = "#34403f",
  red         = "#e05a6a",
  green       = "#03aa5c",
  yellow      = "#d9a72a",
  blue        = "#4d9fd6",
  magenta     = "#d45bb6",
  cyan        = "#09aea1",
  white       = "#dedede",

  bright_black   = "#858585",   -- comment color, the page's gray
  bright_red     = "#f386a1",   -- the page's pink
  bright_green   = "#3fc98a",
  bright_yellow  = "#ecc457",
  bright_blue    = "#7fbde6",
  bright_magenta = "#e58ccf",
  bright_cyan    = "#4fd0c4",
  bright_white   = "#fefefe",

  comment     = "#858585",
  border      = "#3f4f4e",
  cursor      = "#09aea1",       -- the page's teal, verbatim
  accent      = "#09aea1",
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

    -- Inline code: deeper sage + the bright teal, the page's accent hue.
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
