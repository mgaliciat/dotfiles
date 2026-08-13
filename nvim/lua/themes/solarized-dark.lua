-- ─── theme: solarized-dark ───────────────────────────────────
-- Ethan Schoonover's canonical Solarized Dark, mirror of the Ghostty
-- theme `solarized-dark` and tmux/themes/solarized-dark.conf.
-- tokyonight base: variant `night`.
--
-- The original, NOT the osaka fork (which lives in its own plugin spec):
-- base03 canvas, published accents, no re-tuning. Comments are base01 —
-- deliberately the dimmest thing on screen, the inverse of naysayer.

local palette = {
  bg          = "#002b36",       -- base03
  bg_dark     = "#073642",       -- base02 — code bg / sidebars
  bg_highlight= "#073642",       -- base02 — cursorline, selection
  bg_visual   = "#073642",
  bg_float    = "#073642",
  bg_popup    = "#073642",
  bg_search   = "#586e75",       -- base01 — search needs body, not an accent
  bg_sidebar  = "#073642",
  bg_statusline = "#073642",

  fg          = "#839496",       -- base0 — body text
  fg_dark     = "#93a1a1",       -- base1 — emphasized
  fg_gutter   = "#586e75",       -- base01

  black       = "#073642",       -- base02
  red         = "#dc322f",
  green       = "#859900",
  yellow      = "#b58900",
  blue        = "#268bd2",
  magenta     = "#d33682",
  cyan        = "#2aa198",
  white       = "#eee8d5",       -- base2

  bright_black   = "#002b36",   -- base03
  bright_red     = "#cb4b16",   -- orange
  bright_green   = "#586e75",   -- base01
  bright_yellow  = "#657b83",   -- base00
  bright_blue    = "#839496",   -- base0
  bright_magenta = "#6c71c4",   -- violet
  bright_cyan    = "#93a1a1",   -- base1
  bright_white   = "#fdf6e3",   -- base3

  comment     = "#586e75",       -- base01 — Solarized comments
  border      = "#586e75",
  cursor      = "#93a1a1",       -- base1
  accent      = "#268bd2",       -- blue — Solarized's iconic accent
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
    c.border_highlight = palette.accent  -- blue accent for focus

    c.red       = palette.red
    c.red1      = palette.bright_red
    c.green     = palette.green
    c.green1    = palette.green
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
    c.purple    = palette.bright_magenta  -- violet
    c.orange    = palette.bright_red       -- Solarized's semantic orange

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#073642" }
    hl.CursorLineNr = { fg = palette.accent, bold = true }
    hl.LineNr       = { fg = c.fg_gutter }

    hl.FloatBorder = { fg = palette.border, bg = c.bg_float }
    hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

    hl.TelescopeBorder       = { fg = palette.border, bg = c.bg_float }
    hl.TelescopePromptBorder = { fg = palette.accent, bg = c.bg_float }
    hl.TelescopeMatching     = { fg = palette.bright_red, bold = true }

    hl.GitSignsAdd    = { fg = c.green }
    hl.GitSignsChange = { fg = c.yellow }
    hl.GitSignsDelete = { fg = c.red }

    -- Inline code: base02 + Solarized orange.
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

    hl["@markup.heading.1.markdown"]   = { fg = palette.blue,    bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.magenta, bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.yellow,  bold = true }

    hl["@markup.link.url"]   = { fg = palette.blue, underline = true }
    hl["@markup.link.label"] = { fg = palette.accent }
  end,
}
