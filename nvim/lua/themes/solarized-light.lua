-- ─── theme: solarized-light ──────────────────────────────────
-- Ethan Schoonover's canonical Solarized Light, mirror of the Ghostty
-- theme `solarized-light` and tmux/themes/solarized-light.conf.
-- tokyonight base: variant `day` (the plugin's light one).
--
-- Light theme convention: the "bright" colors are the DARK base tones
-- (base03/base01/base00/base0) — over a light background they give more contrast.
-- ANSI mapping = the canonical Solarized scheme (not the dark convention).

local palette = {
  bg          = "#fdf6e3",       -- base3
  bg_dark     = "#eee8d5",       -- base2 — ANSI 0 dimmed / code bg
  bg_highlight= "#eee8d5",       -- base2 — selection bg, cursorline visual
  bg_visual   = "#eee8d5",
  bg_float    = "#eee8d5",
  bg_popup    = "#eee8d5",
  bg_search   = "#e3c88f",       -- muted yellow
  bg_sidebar  = "#eee8d5",
  bg_statusline = "#eee8d5",

  fg          = "#657b83",       -- base00 — body text
  fg_dark     = "#586e75",       -- base01 — emphasized
  fg_gutter   = "#93a1a1",       -- base1

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

  comment     = "#93a1a1",       -- base1 — Solarized comments
  border      = "#93a1a1",
  cursor      = "#586e75",       -- base01
  accent      = "#268bd2",       -- blue — Solarized's iconic accent
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
    c.border_highlight = palette.accent  -- blue accent for focus

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
    c.purple    = palette.bright_magenta  -- violet
    c.orange    = palette.bright_red       -- Solarized's semantic orange

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#eee8d5" }
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

    -- Inline code: base2 + Solarized orange.
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
