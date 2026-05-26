-- ─── theme: oled-neon ────────────────────────────────────────
-- Espejo del bloque `oled-neon` en ghostty/themes/oled-neon.
-- Paleta Dracula adaptada para OLED: true black (#000000) + acentos
-- neón saturados (verde láser, magenta neon, cyan brillante).
--
-- Brand anchors:
--   #50fa7b cursor (verde láser · máxima visibilidad sobre #000)
--   #ff79c6 magenta neon (modos, headings primarios)
--   #8be9fd cyan brillante (links, accents)
--   #000000 bg true black · #f8f8f2 fg Dracula
--
-- Base tokyonight: variant `night`.
-- bg_statusline = #000000 deliberado: el statusline se mezcla con el
-- editor en OLED, evita el "rectángulo flotante" que se ve cuando
-- lualine usa un bg distinto del Normal.

local palette = {
  bg            = "#000000",       -- true black OLED
  bg_dark       = "#0a0a0a",       -- raised mínimo (sidebars)
  bg_highlight  = "#2a2a4a",       -- selection bg (azul-violeta oscuro)
  bg_visual     = "#2a2a4a",
  bg_float      = "#0d0d0d",       -- popups: apenas distinguibles del bg
  bg_popup      = "#0d0d0d",
  bg_search     = "#44475a",       -- Dracula classic selection
  bg_sidebar    = "#0a0a0a",
  bg_statusline = "#000000",       -- se funde con el editor en OLED

  fg            = "#f8f8f2",       -- Dracula fg
  fg_dark       = "#bfbfbf",
  fg_gutter     = "#4a4a4a",       -- bright_black, line numbers sutiles pero legibles

  black         = "#1a1a1a",
  red           = "#ff5555",
  green         = "#50fa7b",
  yellow        = "#f1fa8c",
  blue          = "#6272a4",       -- Dracula comment-blue
  magenta       = "#ff79c6",
  cyan          = "#8be9fd",
  white         = "#bfbfbf",

  bright_black   = "#4a4a4a",
  bright_red     = "#ff6e6e",
  bright_green   = "#69ff94",
  bright_yellow  = "#ffffa5",
  bright_blue    = "#9eb0e0",
  bright_magenta = "#ff92df",
  bright_cyan    = "#a4ffff",
  bright_white   = "#ffffff",

  comment       = "#6272a4",       -- Dracula classic comment
  border        = "#44475a",
  cursor        = "#50fa7b",       -- verde láser (brand del theme)
  accent        = "#ff79c6",       -- magenta neon (focus/interactive)
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
    c.orange    = palette.bright_yellow   -- no hay orange en ANSI 16; ámbar como sustituto semántico

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#0d0d0d" }       -- mínimo lift sobre #000
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

    -- Inline code: bg apenas raised + cyan neon.
    local code_bg = "#1a1a1a"
    local code_fg = palette.cyan
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    -- Headings: jerarquía magenta → cyan → verde (neón de mayor a menor saturación).
    hl["@markup.heading.1.markdown"]   = { fg = palette.magenta, bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.cyan,    bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.green,   bold = true }

    hl["@markup.link.url"]   = { fg = palette.cyan, underline = true }
    hl["@markup.link.label"] = { fg = palette.magenta }
  end,
}
