-- ─── theme: anthropic-brand ──────────────────────────────────
-- Mirror of ghostty/themes/anthropic-brand and tmux/themes/anthropic-brand.conf.
-- Read the ghostty file first: it carries the full derivation rationale and the
-- link to the upstream source (skills/brand-guidelines/SKILL.md in
-- github.com/anthropics/skills), which is the only normative publication of
-- these seven values.
--
--   Main    Dark #141413 · Light #faf9f5 · Mid Gray #b0aea5 · Light Gray #e8e6dc
--   Accent  Orange #d97757 · Blue #6a9bcc · Green #788c5d
--
-- tokyonight base: variant `night`.
-- Dark theme convention: the "bright" colors are LIGHTER than the normal ones.

local palette = {
  bg          = "#141413",       -- BRAND Dark
  bg_dark     = "#1B1B18",       -- sidebars
  bg_highlight= "#472D24",       -- selection — deep, desaturated Orange
  bg_visual   = "#472D24",
  bg_float    = "#21201D",       -- surface
  bg_popup    = "#21201D",
  bg_search   = "#47453E",
  bg_sidebar  = "#1B1B18",
  bg_statusline = "#1B1B18",

  fg          = "#E8E6DC",       -- BRAND Light Gray
  fg_dark     = "#B0AEA5",       -- BRAND Mid Gray
  fg_gutter   = "#727064",       -- line numbers

  black       = "#1E1D1A",
  red         = "#D96257",
  green       = "#788C5D",       -- BRAND Green
  yellow      = "#D2B470",
  blue        = "#6A9BCC",       -- BRAND Blue
  magenta     = "#C77591",
  cyan        = "#6BB6BD",
  white       = "#B0AEA5",       -- BRAND Mid Gray

  bright_black   = "#727064",
  bright_red     = "#D97757",    -- BRAND Orange
  bright_green   = "#96AE75",
  bright_yellow  = "#E2CC8D",
  bright_blue    = "#92B8DD",
  bright_magenta = "#DB94AC",
  bright_cyan    = "#91CFD4",
  bright_white   = "#FAF9F5",    -- BRAND Light

  -- Comments sit above the ANSI dim slot (#727064, 3.7:1) on purpose: in a
  -- terminal that value only has to mark inactive chrome, but in an editor it
  -- is prose you actually read.
  comment     = "#939080",
  border      = "#515048",
  cursor      = "#D97757",       -- BRAND Orange
  accent      = "#D99F8C",       -- Orange lifted, for focus rings
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
    c.border_highlight = palette.accent

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
    c.orange    = palette.cursor          -- BRAND Orange as the "semantic orange"

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#21201D" }
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

    -- Inline code: the selection inset + Orange.
    local code_bg = palette.bg_highlight  -- #472D24
    local code_fg = palette.bright_yellow -- Orange on terracotta is too close a
                                          -- pair to read; amber separates.
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = "#21201D" }
    hl.markdownCodeBlock               = { bg = "#21201D" }

    -- Headings walk the three brand accents in their published order:
    -- primary → secondary → tertiary.
    hl["@markup.heading.1.markdown"]   = { fg = palette.cursor,       bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.blue,         bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.bright_green, bold = true }

    hl["@markup.link.url"]   = { fg = palette.bright_blue, underline = true }
    hl["@markup.link.label"] = { fg = palette.cursor }
  end,
}
