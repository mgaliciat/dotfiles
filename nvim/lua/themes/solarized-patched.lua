-- ─── theme: solarized-patched ────────────────────────────────
-- The "Solarized Dark Patched" cut, mirror of the Ghostty theme
-- `solarized-patched` and tmux/themes/solarized-patched.conf.
-- tokyonight base: variant `night`.
--
-- craftzdog's Ghostty names this theme; it ships inside Ghostty.app, so nvim had
-- nothing to point at until it was ported. Provenance and the full ANSI table
-- live in ghostty/themes/solarized-patched — that file is the source of truth
-- for these values, this one only maps them onto tokyonight's slots.
--
-- NOT `solarized-dark`: the patched cut re-tunes every hex (canvas #001e27, not
-- base03 #002b36). Don't merge the two.

local palette = {
  bg          = "#001e27",       -- patched canvas, darker than base03
  bg_dark     = "#002831",       -- palette 0 — code bg / sidebars
  bg_highlight= "#002831",       -- cursorline, selection
  bg_visual   = "#002831",
  bg_float    = "#002831",
  bg_popup    = "#002831",
  bg_search   = "#475b62",       -- needs body, not an accent
  bg_sidebar  = "#002831",
  bg_statusline = "#002831",

  fg          = "#708284",       -- body text
  fg_dark     = "#819090",       -- emphasized
  fg_gutter   = "#536870",

  black       = "#002831",
  red         = "#d11c24",
  green       = "#738a05",
  yellow      = "#a57706",
  blue        = "#2176c7",
  magenta     = "#c61c6f",
  cyan        = "#259286",
  white       = "#eae3cb",

  bright_black   = "#475b62",
  bright_red     = "#bd3613",   -- orange
  bright_green   = "#475b62",   -- repeats bright_black upstream
  bright_yellow  = "#536870",
  bright_blue    = "#708284",
  bright_magenta = "#5956ba",   -- violet
  bright_cyan    = "#819090",
  bright_white   = "#fcf4dc",

  -- Same structural slot Solarized uses for comments (ANSI 10). In this cut that
  -- is #475b62, dimmer than canonical's #586e75 — comments recede further here.
  comment     = "#475b62",
  border      = "#475b62",
  cursor      = "#708284",
  accent      = "#2176c7",       -- blue — Solarized's iconic accent
}

return {
  style = "night",
  palette = palette,

  -- Drop nvim's own canvas so Ghostty's glass (opacity 0.9 + blur) shows through.
  -- Without it nvim paints an opaque canvas over the translucent terminal and the
  -- seam is visible at every split edge. Set false if the glass ever comes off.
  --
  -- It also hides a deliberate mismatch: Ghostty's `background = #031219`
  -- override (craftzdog's) paints over this theme's #001e27, so with a
  -- transparent nvim every layer shows the one canvas the terminal draws.
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
    hl.CursorLine   = { bg = "#002831" }
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

    -- Inline code: palette 0 + Solarized orange.
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
