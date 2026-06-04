-- ─── theme: carbon ───────────────────────────────────────────
-- Espejo cross-stack del tema `carbon` (mismo id en ghostty/themes/carbon
-- y tmux/themes/carbon.conf — una sola paleta, tres capas).
-- Minimal + funcional + alto contraste sobre true black (#000000).
-- Un único acento cálido: Claude orange #d97757 (de la brand palette
-- del repo — NO se inventan otros hex de acento).
--
-- Brand anchors:
--   #d97757 cursor/accent (Claude orange · el ÚNICO color cálido)
--   #e4e4e4 fg neutro de alto contraste sobre #000
--   #6a6a6a comment (gris medio, legible sin gritar)
--   #000000 bg true black · paleta ANSI monocroma + 6 hues desaturados
--
-- Base tokyonight: variant `night`.
-- bg_statusline = #000000 deliberado: el statusline se funde con el
-- editor en true black, evita el "rectángulo flotante" cuando lualine
-- usa un bg distinto del Normal.

local palette = {
  bg            = "#000000",       -- true black
  bg_dark       = "#0a0a0a",       -- raised mínimo (sidebars)
  bg_highlight  = "#2a2a2a",       -- selection bg (gris neutro)
  bg_visual     = "#2a2a2a",
  bg_float      = "#0d0d0d",       -- popups: apenas distinguibles del bg
  bg_popup      = "#0d0d0d",
  bg_search     = "#3a3a3a",       -- search más claro que selection
  bg_sidebar    = "#0a0a0a",
  bg_statusline = "#000000",       -- se funde con el editor en true black

  fg            = "#e4e4e4",       -- neutro alto contraste
  fg_dark       = "#a0a0a0",
  fg_gutter     = "#3a3a3a",       -- line numbers sutiles pero legibles

  black         = "#1c1c1c",       -- ansi0
  red           = "#e35f5f",       -- ansi1
  green         = "#9ec07c",       -- ansi2
  yellow        = "#d9a441",       -- ansi3
  blue          = "#7aa6c2",       -- ansi4
  magenta       = "#c08fb8",       -- ansi5
  cyan          = "#7fb5ad",       -- ansi6
  white         = "#d4d4d4",       -- ansi7

  bright_black   = "#4a4a4a",      -- ansi8
  bright_red     = "#ef7a7a",      -- ansi9
  bright_green   = "#b3d196",      -- ansi10
  bright_yellow  = "#e8be6a",      -- ansi11
  bright_blue    = "#9bc0d6",      -- ansi12
  bright_magenta = "#d4a8cd",      -- ansi13
  bright_cyan    = "#9fccc4",      -- ansi14
  bright_white   = "#ffffff",      -- ansi15

  comment       = "#6a6a6a",       -- gris medio
  border        = "#4a4a4a",       -- subtle
  cursor        = "#d97757",       -- Claude orange (brand del theme)
  accent        = "#d97757",       -- mismo orange (único cálido / focus)
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
    c.orange    = palette.accent          -- no hay orange en ANSI 16; el accent (Claude orange) es el único cálido

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#0d0d0d" }       -- mínimo lift sobre #000
    hl.CursorLineNr = { fg = palette.accent, bold = true }
    hl.LineNr       = { fg = c.fg_gutter }

    hl.FloatBorder = { fg = palette.border, bg = c.bg_float }
    hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

    hl.TelescopeBorder       = { fg = palette.border, bg = c.bg_float }
    hl.TelescopePromptBorder = { fg = palette.accent, bg = c.bg_float }
    hl.TelescopeMatching     = { fg = palette.accent, bold = true }

    hl.GitSignsAdd    = { fg = c.green }
    hl.GitSignsChange = { fg = c.yellow }
    hl.GitSignsDelete = { fg = c.red }

    -- Inline code: bg apenas raised (ansi0) + verde desaturado.
    local code_bg = "#1c1c1c"
    local code_fg = palette.green
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    -- Headings: jerarquía orange (acento) → blue → green (de cálido a frío).
    -- Solo h1 usa el acento — restraint minimalista, el resto baja a hues fríos.
    hl["@markup.heading.1.markdown"]   = { fg = palette.accent, bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.blue,   bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.green,  bold = true }

    hl["@markup.link.url"]   = { fg = palette.blue, underline = true }
    hl["@markup.link.label"] = { fg = palette.accent }
  end,
}
