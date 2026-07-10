-- ─── theme: xcode-oled ───────────────────────────────────────
-- Espejo de ghostty/themes/xcode-oled y tmux/themes/xcode-oled.conf.
-- Syntax de Xcode "Default (Dark)" sobre true black (#000000) para OLED.
--
-- Los hex son los que shippea Apple en el plist Default (Dark).xccolortheme
-- (ver el header del theme de Ghostty para la proveniencia y por qué los
-- ports a VS Code no sirven de fuente). Única desviación: el bg, que en
-- Xcode es #1f1f24 y acá es negro puro.
--
-- Brand anchors:
--   #fc5fa3 keyword rosa (cursor · el color más icónico del theme)
--   #9ef1dd type aqua    (accent: focus/interactive)
--   #fc6a5d string salmón · #d0bf69 number gold
--   #000000 bg true black · #ffffff fg (xcode.syntax.plain)
--
-- Base tokyonight: variant `night`.
-- bg_statusline = #000000 deliberado: en OLED el statusline se funde con
-- el editor y evita el "rectángulo flotante" de un bg distinto al Normal.

local palette = {
  bg            = "#000000",       -- true black OLED
  bg_dark       = "#0a0a0a",       -- raised mínimo (sidebars)
  bg_highlight  = "#515b70",       -- DVTSourceTextSelectionColor (Apple)
  bg_visual     = "#515b70",
  bg_float      = "#0d0d0d",       -- popups: apenas distinguibles del bg
  bg_popup      = "#0d0d0d",
  bg_search     = "#515b70",
  bg_sidebar    = "#0a0a0a",
  bg_statusline = "#000000",       -- se funde con el editor en OLED

  fg            = "#ffffff",       -- xcode.syntax.plain
  fg_dark       = "#dfdfe0",
  fg_gutter     = "#424d5b",       -- DVTSourceTextInvisiblesColor: sutil pero legible

  black         = "#1f1f24",       -- el bg propio de Xcode
  red           = "#fc6a5d",       -- string
  green         = "#67b7a4",       -- identifier.function (teal-verde, "project")
  yellow        = "#d0bf69",       -- number
  blue          = "#41a1c0",       -- declaration.other
  magenta       = "#fc5fa3",       -- keyword
  cyan          = "#5dd8ff",       -- declaration.type
  white         = "#dfdfe0",

  -- Apple no define brights. 10/11/12/15 son hex suyos (el "claro" del
  -- mismo token); 9/13/14 son el normal +0.08 de lightness en HSL.
  bright_black   = "#6c7986",      -- comment
  bright_red     = "#fd8f85",      -- derivado
  bright_green   = "#9ef1dd",      -- identifier.type (aqua)
  bright_yellow  = "#ffdb8b",      -- markup.aside.kind
  bright_blue    = "#5482ff",      -- url
  bright_magenta = "#fd87ba",      -- derivado
  bright_cyan    = "#86e2ff",      -- derivado
  bright_white   = "#ffffff",      -- plain

  comment       = "#6c7986",       -- xcode.syntax.comment
  border        = "#515b70",
  cursor        = "#fc5fa3",       -- keyword rosa (brand del theme)
  accent        = "#9ef1dd",       -- type aqua (focus/interactive)

  -- Fuera del ANSI 16, pero Xcode los usa mucho y tokyonight tiene slot.
  purple        = "#d0a8ff",       -- identifier.type.system
  purple_deep   = "#a167e6",       -- identifier.function.system
  orange        = "#fd8f3f",       -- preprocessor / macro
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
    c.blue1     = palette.cyan
    c.blue2     = palette.blue
    c.blue5     = palette.cyan
    c.blue6     = palette.bright_cyan
    c.blue7     = palette.bright_blue
    c.cyan      = palette.cyan
    c.magenta   = palette.magenta
    c.magenta2  = palette.bright_magenta
    -- Xcode SÍ tiene púrpura propio (los identificadores "system"), así
    -- que no hace falta reciclar el magenta acá — otros themes del repo
    -- sí lo hacen porque su paleta ANSI no trae púrpura.
    c.purple    = palette.purple
    c.orange    = palette.orange

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

    -- Inline code: bg apenas raised + aqua (el "type" de Xcode).
    local code_bg = "#1f1f24"                  -- el bg propio de Xcode como raised
    local code_fg = palette.bright_green
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    -- Headings: jerarquía rosa → aqua → gold (keyword, type, number).
    hl["@markup.heading.1.markdown"]   = { fg = palette.magenta,      bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.bright_green, bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.yellow,       bold = true }

    hl["@markup.link.url"]   = { fg = palette.bright_blue, underline = true }
    hl["@markup.link.label"] = { fg = palette.magenta }

    -- ─── syntax: roles de Xcode, no los de tokyonight ──────────
    -- ESTO es el theme. Sin este bloque tokyonight aplica SU semántica
    -- sobre nuestra paleta (String→green, Keyword→cyan) y queda un tema
    -- con los colores de Xcode pero el highlighting de otro editor.
    -- Cada grupo se ata al token equivalente del plist de Apple.
    --
    -- Criterio en los dos casos donde treesitter y Xcode no se solapan:
    --   · @variable → fg plano. Xcode pinta de teal los identificadores
    --     que su índice resuelve; treesitter pinta TODOS. Colorear cada
    --     local sería mucho más ruidoso que el editor real.
    --   · @operator y puntuación → fg plano, como en Xcode.
    local xc = {
      keyword   = palette.magenta,      -- xcode.syntax.keyword
      string    = palette.red,          -- xcode.syntax.string
      number    = palette.yellow,       -- xcode.syntax.number / .character
      comment   = palette.comment,      -- xcode.syntax.comment
      preproc   = palette.orange,       -- xcode.syntax.preprocessor / .identifier.macro
      typ       = palette.bright_green, -- xcode.syntax.identifier.type      (aqua, "project")
      typ_sys   = palette.purple,       -- xcode.syntax.identifier.type.system
      func      = palette.green,        -- xcode.syntax.identifier.function  (teal, "project")
      func_sys  = palette.purple_deep,  -- xcode.syntax.identifier.function.system
      attribute = "#bf8555",            -- xcode.syntax.attribute
      declared  = palette.cyan,         -- xcode.syntax.declaration.type
      plain     = palette.fg,           -- xcode.syntax.plain
    }

    -- Grupos clásicos de vim (los usa el syntax legacy y varios plugins).
    hl.Comment    = { fg = xc.comment, italic = true }
    hl.Keyword    = { fg = xc.keyword }
    hl.Statement  = { fg = xc.keyword }
    hl.Conditional= { fg = xc.keyword }
    hl.Repeat     = { fg = xc.keyword }
    hl.Exception  = { fg = xc.keyword }
    hl.Operator   = { fg = xc.plain }
    hl.String     = { fg = xc.string }
    hl.Character  = { fg = xc.number }
    hl.Number     = { fg = xc.number }
    hl.Float      = { fg = xc.number }
    hl.Boolean    = { fg = xc.func_sys }
    hl.Constant   = { fg = xc.func }
    hl.Identifier = { fg = xc.plain }
    hl.Function   = { fg = xc.func }
    hl.Type       = { fg = xc.typ }
    hl.StorageClass = { fg = xc.keyword }
    hl.Structure  = { fg = xc.typ }
    hl.PreProc    = { fg = xc.preproc }
    hl.Include    = { fg = xc.preproc }
    hl.Define     = { fg = xc.preproc }
    hl.Macro      = { fg = xc.preproc }
    hl.Special    = { fg = xc.number }

    -- Treesitter (lo que realmente pinta en este nvim).
    hl["@comment"]              = { fg = xc.comment, italic = true }
    hl["@keyword"]              = { fg = xc.keyword }
    hl["@keyword.function"]     = { fg = xc.keyword }
    hl["@keyword.operator"]     = { fg = xc.keyword }
    hl["@keyword.return"]       = { fg = xc.keyword }
    hl["@keyword.conditional"]  = { fg = xc.keyword }
    hl["@keyword.repeat"]       = { fg = xc.keyword }
    hl["@keyword.exception"]    = { fg = xc.keyword }
    hl["@keyword.import"]       = { fg = xc.preproc }
    hl["@keyword.directive"]    = { fg = xc.preproc }
    hl["@keyword.storage"]      = { fg = xc.keyword }
    hl["@string"]               = { fg = xc.string }
    hl["@string.escape"]        = { fg = xc.number }
    hl["@string.special"]       = { fg = xc.number }
    hl["@character"]            = { fg = xc.number }
    hl["@number"]               = { fg = xc.number }
    hl["@number.float"]         = { fg = xc.number }
    hl["@boolean"]              = { fg = xc.func_sys }
    hl["@constant"]             = { fg = xc.func }
    hl["@constant.builtin"]     = { fg = xc.func_sys }
    hl["@constant.macro"]       = { fg = xc.preproc }
    hl["@type"]                 = { fg = xc.typ }
    hl["@type.definition"]      = { fg = xc.declared }
    hl["@type.builtin"]         = { fg = xc.typ_sys }
    hl["@constructor"]          = { fg = xc.typ }
    hl["@function"]             = { fg = xc.func }
    hl["@function.call"]        = { fg = xc.func }
    hl["@function.method"]      = { fg = xc.func }
    hl["@function.method.call"] = { fg = xc.func }
    hl["@function.builtin"]     = { fg = xc.func_sys }
    hl["@function.macro"]       = { fg = xc.preproc }
    hl["@variable"]             = { fg = xc.plain }
    hl["@variable.builtin"]     = { fg = xc.func_sys }
    hl["@variable.parameter"]   = { fg = xc.plain }
    hl["@variable.member"]      = { fg = xc.func }
    hl["@property"]             = { fg = xc.func }
    hl["@field"]                = { fg = xc.func }
    hl["@attribute"]            = { fg = xc.attribute }
    hl["@module"]               = { fg = xc.typ }
    hl["@operator"]             = { fg = xc.plain }
    hl["@punctuation.bracket"]  = { fg = xc.plain }
    hl["@punctuation.delimiter"]= { fg = xc.plain }
    hl["@punctuation.special"]  = { fg = xc.plain }

    -- LSP semantic tokens: ganan sobre treesitter cuando el server los
    -- manda, así que sin esto un buffer con LSP activo revierte a los
    -- colores de tokyonight y el theme se ve distinto según el filetype.
    hl["@lsp.type.class"]     = { fg = xc.typ }
    hl["@lsp.type.enum"]      = { fg = xc.typ }
    hl["@lsp.type.interface"] = { fg = xc.typ }
    hl["@lsp.type.struct"]    = { fg = xc.typ }
    hl["@lsp.type.type"]      = { fg = xc.typ }
    hl["@lsp.type.function"]  = { fg = xc.func }
    hl["@lsp.type.method"]    = { fg = xc.func }
    hl["@lsp.type.property"]  = { fg = xc.func }
    hl["@lsp.type.variable"]  = { fg = xc.plain }
    hl["@lsp.type.parameter"] = { fg = xc.plain }
    hl["@lsp.type.macro"]     = { fg = xc.preproc }
    hl["@lsp.type.keyword"]   = { fg = xc.keyword }
    hl["@lsp.type.string"]    = { fg = xc.string }
    hl["@lsp.type.number"]    = { fg = xc.number }
    hl["@lsp.type.comment"]   = { fg = xc.comment, italic = true }
  end,
}
