-- ─── theme: prism-night ──────────────────────────────────────
-- Espejo del theme Ghostty `prism-night` y de tmux/themes/prism-night.conf.
-- Paleta sampleada del wallpaper "prism" de macOS: azul medianoche
-- profundo + arco del espectro (naranja → amarillo → verde → cyan →
-- azul → violeta). Antes solo existía en Ghostty; ahora también en nvim.
--
-- Base tokyonight: variant `night`.
-- Convención dark theme: los "bright" son MÁS CLAROS que los normales.

local palette = {
  bg            = "#0a0e1a",       -- azul medianoche profundo
  bg_dark       = "#070a14",       -- sidebars más oscuros
  bg_highlight  = "#2e4a7a",       -- selection (azul medio)
  bg_visual     = "#2e4a7a",
  bg_float      = "#0d1120",       -- popups apenas distinguibles del bg
  bg_popup      = "#0d1120",
  bg_search     = "#3a4a6b",
  bg_sidebar    = "#070a14",
  bg_statusline = "#070a14",

  fg            = "#c8d3e8",       -- azul-gris claro
  fg_dark       = "#8896b8",
  fg_gutter     = "#3a4a6b",

  black         = "#1a2238",
  red           = "#ff6b5c",
  green         = "#a8d65c",
  yellow        = "#f5c842",
  blue          = "#4a7ec8",
  magenta       = "#b06bd9",
  cyan          = "#5ec9d4",
  white         = "#c8d3e8",

  bright_black   = "#3a4a6b",
  bright_red     = "#ff8a7c",
  bright_green   = "#c8e87a",
  bright_yellow  = "#ffd866",
  bright_blue    = "#6b9ee0",
  bright_magenta = "#c98ae8",
  bright_cyan    = "#7fd9e0",
  bright_white   = "#ffffff",

  comment       = "#6b7a9e",       -- muted blue-gray, legible sobre bg azul
  border        = "#3a4a6b",
  cursor        = "#ff9248",       -- naranja del prisma (acento del theme)
  accent        = "#ff9248",
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
    c.orange    = palette.cursor          -- naranja del prisma como "naranja semántico"

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#0d1120" }       -- mínimo lift sobre el bg
    hl.CursorLineNr = { fg = palette.cursor, bold = true }
    hl.LineNr       = { fg = c.fg_gutter }

    hl.FloatBorder = { fg = palette.border, bg = c.bg_float }
    hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

    hl.TelescopeBorder       = { fg = palette.border, bg = c.bg_float }
    hl.TelescopePromptBorder = { fg = palette.accent, bg = c.bg_float }
    hl.TelescopeMatching     = { fg = palette.bright_yellow, bold = true }

    hl.GitSignsAdd    = { fg = c.green }
    hl.GitSignsChange = { fg = c.yellow }
    hl.GitSignsDelete = { fg = c.red }

    -- Inline code: bg azul apenas raised + cyan del prisma.
    local code_bg = "#1a2238"
    local code_fg = palette.cyan
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    -- Headings: arco del prisma naranja → amarillo → verde.
    hl["@markup.heading.1.markdown"]   = { fg = palette.cursor,        bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.yellow,        bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.green,         bold = true }

    hl["@markup.link.url"]   = { fg = palette.cyan, underline = true }
    hl["@markup.link.label"] = { fg = palette.cursor }
  end,
}
