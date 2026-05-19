-- ─── theme: anthropic-light ──────────────────────────────────
-- Espejo del bloque "Anthropic LIGHT" inline en ghostty/config.ghostty.
-- Paleta portada de ashwingopalsamy/claude-code-theme (VS Code,
-- WCAG-validated, normalizada de Anthropic brand-guidelines +
-- docs.anthropic.com CSS vars).
--
-- Brand anchors:
--   #CC785C interactive light (cursor accent)
--   #C96442 brand primary (terracota)
--   #FAF9F5 paper (bg) · #1A1917 ink (fg)
--
-- Base tokyonight: variant `day`.
-- Convención light theme: los "bright" son MÁS OSCUROS que los
-- normales (más saturación = más contraste sobre fondo claro).

local palette = {
  bg          = "#FAF9F5",       -- paper (Anthropic light bg oficial)
  bg_dark     = "#F0EEE6",       -- parchment (raised)
  bg_highlight= "#EAE7DF",       -- linen (selection / inset)
  bg_visual   = "#EAE7DF",
  bg_float    = "#F3F1E9",       -- surface
  bg_popup    = "#F3F1E9",
  bg_search   = "#E8C96B",       -- warning soft para search match
  bg_sidebar  = "#F0EEE6",
  bg_statusline = "#F0EEE6",

  fg          = "#1A1917",       -- ink (Anthropic dark)
  fg_dark     = "#6B665F",       -- foregroundMuted / charcoal
  fg_gutter   = "#8D877D",       -- foregroundSubtle / ash (line numbers)

  black       = "#1A1917",
  red         = "#A84B3A",       -- error light
  green       = "#2E7C4C",       -- success light
  yellow      = "#8A6220",       -- warning light
  blue        = "#207FDE",       -- info / highlights.blue
  magenta     = "#6A5BCC",
  cyan        = "#2E5F99",
  white       = "#746E64",       -- intermediate gray (no se evapora sobre cream)

  bright_black   = "#8D877D",   -- ash (color de comentarios)
  bright_red     = "#C45F4A",
  bright_green   = "#5E8F6D",
  bright_yellow  = "#9C7A39",
  bright_blue    = "#4F79A8",
  bright_magenta = "#6D5DBD",
  bright_cyan    = "#45809E",
  bright_white   = "#4A473F",   -- "bright" en light = MÁS oscuro

  comment     = "#6C655D",       -- syntax comment (contraste sobrado vs cream)
  border      = "#D9D5CC",       -- stone
  cursor      = "#CC785C",       -- interactive light (Claude accent)
  accent      = "#CC785C",
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
    c.orange    = palette.cursor          -- Claude accent como "naranja semántico"

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#F3F1E9" }       -- surface
    hl.CursorLineNr = { fg = palette.cursor, bold = true }
    hl.LineNr       = { fg = c.fg_gutter }

    hl.FloatBorder = { fg = palette.border, bg = c.bg_float }
    hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

    hl.TelescopeBorder       = { fg = palette.border, bg = c.bg_float }
    hl.TelescopePromptBorder = { fg = palette.cursor, bg = c.bg_float }
    hl.TelescopeMatching     = { fg = palette.bright_red, bold = true }

    hl.GitSignsAdd    = { fg = c.green }
    hl.GitSignsChange = { fg = c.yellow }
    hl.GitSignsDelete = { fg = c.red }

    -- Inline code: parchment + bright terracota.
    local code_bg = palette.bg_dark       -- #F0EEE6
    local code_fg = palette.bright_red    -- #C45F4A
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    -- Headings: jerarquía terracota → Claude accent → ámbar oscuro.
    hl["@markup.heading.1.markdown"]   = { fg = palette.bright_red, bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.cursor,     bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.yellow,     bold = true }

    hl["@markup.link.url"]   = { fg = palette.blue, underline = true }
    hl["@markup.link.label"] = { fg = palette.cursor }
  end,
}
