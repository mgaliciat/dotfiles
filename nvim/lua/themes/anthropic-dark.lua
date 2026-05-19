-- ─── theme: anthropic-dark ───────────────────────────────────
-- Espejo del bloque "Anthropic DARK" inline en ghostty/config.ghostty.
-- Paleta portada de ashwingopalsamy/claude-code-theme (VS Code,
-- WCAG-validated, normalizada de Anthropic brand-guidelines +
-- docs.anthropic.com CSS vars).
--
-- Brand anchors:
--   #D97757 secondary (Claude orange · cursor accent)
--   #D4967E interactive dark (focus/accent)
--   #141413 ink/bg · #EAE7DF fg · #2B2A27 bg inset
--
-- Base tokyonight: variant `night`.
-- Convención dark theme: los "bright" son MÁS CLAROS que los normales.

local palette = {
  bg          = "#141413",       -- Anthropic ink (bg dark)
  bg_dark     = "#1A1917",       -- bg raised (sidebars)
  bg_highlight= "#2B2A27",       -- selection bg / bg inset
  bg_visual   = "#2B2A27",
  bg_float    = "#1F1D1A",       -- surface
  bg_popup    = "#1F1D1A",
  bg_search   = "#4A473F",       -- border tone para search match
  bg_sidebar  = "#1A1917",
  bg_statusline = "#1A1917",

  fg          = "#EAE7DF",       -- foreground dark
  fg_dark     = "#A9A39A",       -- foregroundMuted
  fg_gutter   = "#6B665F",       -- foregroundSubtle (line numbers)

  black       = "#1A1917",
  red         = "#D47563",       -- error dark
  green       = "#9ACA86",       -- success dark
  yellow      = "#E8C96B",       -- warning dark
  blue        = "#61AAF2",       -- info / highlights.blueSoft
  magenta     = "#9B87F5",       -- highlights.violet
  cyan        = "#8CC4FF",
  white       = "#D9D5CC",       -- neutral.stone

  bright_black   = "#6B665F",   -- neutral.charcoal
  bright_red     = "#F09884",
  bright_green   = "#B6E0A5",
  bright_yellow  = "#F2D98F",
  bright_blue    = "#A2D2FF",
  bright_magenta = "#C9BCFF",
  bright_cyan    = "#BDE0FF",
  bright_white   = "#F5F2E9",

  comment     = "#B8AFA3",       -- syntax comment (warm gray legible)
  border      = "#4A473F",
  cursor      = "#D97757",       -- Claude orange (brand secondary)
  accent      = "#D4967E",       -- interactive dark (focus)
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
    c.orange    = palette.cursor          -- Claude orange como "naranja semántico"

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#1F1D1A" }       -- surface (apenas más claro que bg)
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

    -- Inline code: bg inset + Claude orange.
    local code_bg = palette.bg_highlight  -- #2B2A27
    local code_fg = palette.cursor        -- Claude orange
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    -- Headings: jerarquía Claude orange → ámbar → verde.
    hl["@markup.heading.1.markdown"]   = { fg = palette.cursor,         bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.bright_yellow,  bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.bright_green,   bold = true }

    hl["@markup.link.url"]   = { fg = palette.bright_blue, underline = true }
    hl["@markup.link.label"] = { fg = palette.cursor }
  end,
}
