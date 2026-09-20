-- ─── theme: typesafe-dark ────────────────────────────────────
-- The sage of typesafe.ai taken down to a night canvas. Mirror of the Ghostty
-- theme `typesafe-dark` and tmux/themes/typesafe-dark.conf; dark companion of
-- `typesafe`, built from the same page tokens.
-- tokyonight base: variant `night`.
--
-- The page has no dark mode, so the canvas #182221 is derived: the sage hue of
-- #abbab9 at 11% lightness, saturation raised 10% → 17% so it does not read as
-- plain gray. Everything else is tuned to that canvas in OKLCH: the page's
-- tokens give the HUES, lightness and chroma are set per role (normals L 0.70,
-- brights 0.80, neutrals carry the canvas hue, the bg ladder climbs in even
-- steps). Figures and rationale are in the ghostty file.
--
-- Dark theme convention: the "bright" colors are LIGHTER than the normal ones.

local palette = {
  bg          = "#182221",       -- derived night canvas, L 0.242
  bg_dark     = "#0f1817",       -- ladder step down, L 0.20 — code bg
  bg_highlight= "#212d2c",       -- L 0.285 — cursorline
  bg_visual   = "#2b3837",       -- L 0.33 — selection
  bg_float    = "#212d2c",
  bg_popup    = "#212d2c",
  bg_search   = "#5b4404",       -- the yellow hue at L 0.40
  bg_sidebar  = "#212d2c",
  bg_statusline = "#212d2c",

  fg          = "#d8e0df",       -- sage-tinted white, L 0.90
  fg_dark     = "#a8b4b3",       -- L 0.76
  fg_gutter   = "#667574",       -- L 0.55, 3.4:1

  black       = "#364443",
  red         = "#ec737e",
  green       = "#42b970",
  yellow      = "#daa932",
  blue        = "#50a7e2",
  magenta     = "#d977bf",
  cyan        = "#17b6a8",
  white       = "#cbd3d2",

  bright_black   = "#8a9594",   -- comment color, L 0.66 (5.3:1)
  bright_red     = "#fe9ead",   -- the page's pink hue
  bright_green   = "#7ad59c",
  bright_yellow  = "#f2cd6f",
  bright_blue    = "#80c7f8",
  bright_magenta = "#ef9fda",
  bright_cyan    = "#69d3c7",
  bright_white   = "#f1f6f6",

  comment     = "#8a9594",
  border      = "#445352",       -- L 0.43
  cursor      = "#17b6a8",       -- the page's teal hue at the normals' L
  accent      = "#17b6a8",
}

return {
  style = "night",
  palette = palette,

  -- Drop nvim's own canvas so Ghostty's glass (opacity 0.95 + macos-glass-regular)
  -- shows through; otherwise nvim paints an opaque #182221 over the translucent
  -- terminal and the seam is visible at every split edge. Set false if the glass
  -- ever comes off — never on its own, the two move together (config.ghostty).
  transparent = true,

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
