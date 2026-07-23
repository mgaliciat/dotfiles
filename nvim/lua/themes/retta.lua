-- ─── theme: retta ────────────────────────────────────────────
-- Cross-stack mirror of the `retta` theme (same id in ghostty/themes/retta;
-- tmux mirror pending — one palette per layer, single source of truth is the
-- Eclipse "Retta" XML recovered from the eclipse-color-theme GitHub mirror).
-- High contrast "pumpkin spice": true black #000 + cream fg #f8e1aa, with
-- Retta's own semantic colors kept faithful — pumpkin keywords, sand-yellow
-- strings, blue-gray methods, red-orange classes.
--
-- Source anchors (verbatim from retta.xml unless marked derived):
--   #f8e1aa foreground/brackets/locals   #e79e3c keyword (pumpkin, = accent)
--   #d6c248 string/number/operator       #de6546 class/field
--   #a4b0c0 method                       #527d5d interface/enum + selection bg
--   #83786e comment                      #c97138 lineNumber
--   #395eb1 searchResultIndication       #2a2a2a currentLine
--
-- tokyonight base: variant `night`.

local palette = {
  bg            = "#000000",       -- true black (Retta background)
  bg_dark       = "#0a0a0a",       -- minimal raise (sidebars)
  bg_highlight  = "#2a2a2a",       -- Retta currentLine
  bg_visual     = "#527d5d",       -- Retta selectionBackground (verbatim)
  bg_float      = "#0d0d0d",       -- popups: barely distinguishable from bg
  bg_popup      = "#0d0d0d",
  bg_search     = "#395eb1",       -- Retta searchResultIndication (verbatim)
  bg_sidebar    = "#0a0a0a",
  bg_statusline = "#000000",       -- blends into the editor in true black

  fg            = "#f8e1aa",       -- Retta foreground (cream)
  fg_dark       = "#c9b787",       -- derived: dimmed cream
  fg_gutter     = "#c97138",       -- Retta lineNumber (burnt orange, verbatim)

  black         = "#2a2a2a",       -- ansi0
  red           = "#de6546",       -- ansi1 (class/field)
  green         = "#527d5d",       -- ansi2 (interface/enum)
  yellow        = "#e79e3c",       -- ansi3 (keyword pumpkin)
  blue          = "#a4b0c0",       -- ansi4 (method)
  magenta       = "#bfa4a4",       -- ansi5 (typeArgument rose)
  cyan          = "#6f9e94",       -- ansi6 (derived teal)
  white         = "#f8e1aa",       -- ansi7

  bright_black   = "#83786e",      -- ansi8 (Retta comment gray)
  bright_red     = "#e8836b",      -- ansi9
  bright_green   = "#6ea27e",      -- ansi10
  bright_yellow  = "#d6c248",      -- ansi11 (string/number yellow)
  bright_blue    = "#c2cbd8",      -- ansi12
  bright_magenta = "#d8c0c0",      -- ansi13
  bright_cyan    = "#8fbcb2",      -- ansi14
  bright_white   = "#fff6dc",      -- ansi15

  comment       = "#83786e",       -- Retta comment (verbatim)
  border        = "#5e5c56",       -- Retta occurrenceIndication gray
  cursor        = "#e79e3c",       -- pumpkin (the loudest color in the XML)
  accent        = "#e79e3c",
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
    -- tokyonight paints STRINGS with `green`: Retta strings are sand yellow,
    -- so green here is the string yellow — the "real" green stays for git/diff
    -- (set explicitly below) and for green1/green2.
    c.green     = palette.bright_yellow
    c.green1    = "#527d5d"
    c.green2    = "#527d5d"
    c.yellow    = palette.yellow
    c.blue      = palette.blue
    c.blue0     = palette.bright_blue
    c.blue1     = palette.blue
    c.blue2     = palette.blue
    c.blue5     = palette.cyan
    c.blue6     = palette.bright_cyan
    c.blue7     = palette.bright_blue
    c.cyan      = palette.cyan
    -- tokyonight paints KEYWORDS with magenta/purple: pumpkin, per Retta.
    c.magenta   = palette.yellow
    c.magenta2  = palette.bright_red
    c.purple    = palette.yellow
    c.orange    = palette.fg_gutter      -- burnt orange (Retta lineNumber)

    c.git = {
      add    = "#527d5d",
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = palette.bg_highlight }   -- Retta currentLine
    hl.CursorLineNr = { fg = palette.accent, bold = true }
    hl.LineNr       = { fg = palette.fg_gutter }

    hl.FloatBorder = { fg = palette.border, bg = c.bg_float }
    hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

    hl.TelescopeBorder       = { fg = palette.border, bg = c.bg_float }
    hl.TelescopePromptBorder = { fg = palette.accent, bg = c.bg_float }
    hl.TelescopeMatching     = { fg = palette.accent, bold = true }

    hl.GitSignsAdd    = { fg = "#527d5d" }
    hl.GitSignsChange = { fg = palette.yellow }
    hl.GitSignsDelete = { fg = palette.red }

    -- Types/classes: Retta paints them red-orange, tokyonight defaults to blue.
    hl.Type      = { fg = palette.red }
    hl["@type"]  = { fg = palette.red }

    -- Inline code: raised currentLine bg + string yellow.
    local code_bg = "#1a1a1a"
    local code_fg = palette.bright_yellow
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.comment }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    -- Headings: the Retta spectrum, loudest to quietest — pumpkin → sand → green.
    hl["@markup.heading.1.markdown"]   = { fg = palette.accent, bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.bright_yellow, bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.bright_green, bold = true }

    hl["@markup.link.url"]   = { fg = palette.blue, underline = true }
    hl["@markup.link.label"] = { fg = palette.accent }
  end,
}
