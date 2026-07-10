-- ─── theme: dark-2026 ────────────────────────────────────────
-- Clon de "Dark 2026", el nuevo theme oscuro por default de VS Code
-- (refresh "Focus" de 2026, default desde 1.113 del 25 de marzo de 2026).
-- Hex sacados directo de
-- extensions/theme-defaults/themes/2026-dark.json en microsoft/vscode
-- (colors + tokenColors) — no son un guess. Companion oscuro de
-- `light-2026` (mismo refresh, mismo criterio de extracción).
-- Espejo del theme Ghostty `dark-2026` y tmux/themes/dark-2026.conf.
-- Base tokyonight: variant `night`.
--
-- Convención dark theme del repo (ver carbon/xcode-oled): los "bright"
-- son más claros/vívidos que los normales — convención ANSI estándar,
-- sin invertir. VS Code no define ANSI de 16 colores (es un formato
-- UI-chrome + tokenColors, no terminal), así que ese mapeo acá es una
-- construcción razonada a partir de esos mismos hex.

local palette = {
  bg          = "#121314",       -- editor.background
  bg_dark     = "#191a1b",       -- sideBar/activityBar/statusBar background
  bg_highlight= "#242526",       -- textCodeBlock/hover background — cursorline/visual
  bg_visual   = "#245c73",       -- editor.selectionBackground (horneado sobre el bg)
  bg_float    = "#202122",       -- menu/widget/quickInput background
  bg_popup    = "#202122",
  bg_search   = "#352a05",       -- inputValidation.warningBackground — ámbar oscuro
  bg_sidebar  = "#191a1b",
  bg_statusline = "#191a1b",

  fg          = "#bbbebf",       -- editor.foreground
  fg_dark     = "#8c8c8c",       -- descriptionForeground
  fg_gutter   = "#555555",       -- disabledForeground/placeholderForeground — el más apagado

  black       = "#242526",       -- textCodeBlock/hover — gris oscuro (bg+1 nivel)
  red         = "#ff7b72",       -- keyword / storage
  green       = "#7ee787",       -- entity.name.tag
  yellow      = "#e5ba7d",       -- gitDecoration.modifiedResourceForeground
  magenta     = "#d2a8ff",       -- entity.name.function
  cyan        = "#48a0c7",       -- textLink.foreground — teal-azul
  white       = "#8b949e",       -- comment
  blue        = "#79c0ff",       -- constant/support — azul de tokenColors

  bright_black   = "#555555",   -- disabledForeground
  bright_red     = "#ffa198",   -- invalid/error token
  bright_green   = "#86cf86",   -- charts.green
  bright_yellow  = "#cca700",   -- notificationsWarningIcon — ámbar saturado
  bright_blue    = "#57a3f8",   -- charts.blue — azul vívido
  bright_magenta = "#ad80d7",   -- charts.purple
  bright_cyan    = "#53a5ca",   -- textLink.activeForeground
  bright_white   = "#ffffff",   -- button.foreground / badge.foreground

  comment     = "#8b949e",       -- comment / punctuation.definition.comment
  border      = "#2a2b2c",       -- editorWidget.border / menu.border
  cursor      = "#3994bc",       -- menu.selectionBorder — acento teal-azul icónico
  orange      = "#ffa657",       -- entity.name / meta.definition.variable
  accent      = "#3994bc",
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
    c.border_highlight = palette.accent  -- teal-azul acento para focus

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
    c.orange    = palette.orange          -- variables/números, fiel a entity.name

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#1a1c1d" }
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

    -- Inline code: gris oscuro (bg+1) + teal-azul de acento, igual que
    -- textCodeBlock.background/textLink.foreground en el theme fuente.
    local code_bg = palette.bg_highlight
    local code_fg = palette.accent
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    hl["@markup.heading.1.markdown"]   = { fg = palette.accent,  bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.magenta, bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.bright_yellow, bold = true }

    hl["@markup.link.url"]   = { fg = palette.accent, underline = true }
    hl["@markup.link.label"] = { fg = palette.accent }
  end,
}
