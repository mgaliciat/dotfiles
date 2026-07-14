-- ─── theme: light-2026 ───────────────────────────────────────
-- Clone of "2026 Light", VS Code's new default light theme
-- (the 2026 "Focus" refresh, same cycle that made Dark 2026 the default
-- in 1.113). Hex values taken straight from
-- extensions/theme-defaults/themes/2026-light.json in microsoft/vscode
-- (colors + tokenColors) — they're not a guess.
-- Mirror of the Ghostty theme `light-2026` and tmux/themes/light-2026.conf.
-- tokyonight base: variant `day` (the plugin's light one).
--
-- The repo's light theme convention (see paper/solarized-light): the
-- "bright" colors are MORE saturated/darker than the normal ones — more contrast
-- over a white background. VS Code doesn't define a 16-color ANSI set (it's a
-- UI-chrome + tokenColors format, not a terminal one), so that mapping here
-- is a reasoned construction from those same hex values.

local palette = {
  bg          = "#ffffff",       -- editor.background
  bg_dark     = "#eaeaea",       -- textCodeBlock.background — ANSI 0 dimmed / code bg
  bg_highlight= "#eaeaea",       -- editor.lineHighlightBackground — cursorline/visual
  bg_visual   = "#bfd9f2",       -- editor.selectionBackground (baked over white)
  bg_float    = "#fafafd",       -- editorWidget/menu background
  bg_popup    = "#fafafd",
  bg_search   = "#fdf6e3",       -- inputValidation.warningBackground — warm cream
  bg_sidebar  = "#fafafd",       -- sideBar/activityBar background
  bg_statusline = "#fafafd",     -- statusBar background

  fg          = "#202020",       -- foreground
  fg_dark     = "#606060",       -- descriptionForeground
  fg_gutter   = "#999999",       -- input.placeholderForeground — the most muted

  black       = "#57606a",       -- brackethighlighter — neutral gray
  red         = "#cf222e",       -- keyword / storage
  green       = "#116329",       -- entity.name.tag
  yellow      = "#667309",       -- chart yellow / git modified
  blue        = "#0069cc",       -- button.background / focusBorder — the iconic accent
  magenta     = "#8250df",       -- entity.name.function
  cyan        = "#1b7c83",       -- derived — the theme doesn't define an explicit cyan
  white       = "#6e7781",       -- comment

  bright_black   = "#1f2328",   -- variable.other — near-black ink
  bright_red     = "#ad0707",   -- errorForeground
  bright_green   = "#587c0c",   -- gitDecoration.addedResourceForeground
  bright_yellow  = "#b69500",   -- inputValidation.warningBorder — amber
  bright_blue    = "#1a5cff",   -- charts.blue — vivid blue
  bright_magenta = "#652d90",   -- charts.purple
  bright_cyan    = "#145e63",   -- derived, darker than cyan
  bright_white   = "#202020",   -- foreground — the strongest ink

  comment     = "#6e7781",       -- comment / punctuation.definition.comment
  border      = "#e4e5e6",       -- editorWidget.border / menu.border
  cursor      = "#0069cc",       -- editorCursor.foreground + accent
  orange      = "#953800",       -- entity.name / meta.definition.variable
  accent      = "#0069cc",
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
    c.purple    = palette.magenta
    c.orange    = palette.orange          -- variables/numbers, faithful to entity.name

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#f0f0f3" }
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

    -- Inline code: cream gray + the blue accent, same as
    -- textCodeBlock.background/textLink.foreground in the source theme.
    local code_bg = palette.bg_dark
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
