-- ─── theme: retta ────────────────────────────────────────────
-- Cross-stack mirror of the `retta` theme (same id in ghostty/themes/retta;
-- one palette per layer, single source of truth is the Eclipse "Retta" XML
-- recovered from the eclipse-color-theme GitHub mirror).
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

return require("themes._base")({
  style = "night",
  palette = palette,

  -- Inline code: raised currentLine bg + string yellow.
  code = { bg = "#1a1a1a", fg = palette.bright_yellow, delimiter = palette.comment },

  on_colors = function(c)
    -- tokyonight paints STRINGS with `green`: Retta strings are sand yellow,
    -- so green here is the string yellow — the "real" green (palette.green)
    -- stays on git add and green1/green2, where the shared mapping puts it.
    c.green     = palette.bright_yellow
    c.blue1     = palette.blue
    -- tokyonight paints KEYWORDS with magenta/purple: pumpkin, per Retta.
    c.magenta   = palette.yellow
    c.magenta2  = palette.bright_red
    c.purple    = palette.yellow
    c.orange    = palette.fg_gutter      -- burnt orange (Retta lineNumber)
  end,

  on_highlights = function(hl)
    hl.TelescopeMatching     = { fg = palette.accent, bold = true }

    -- Types/classes: Retta paints them red-orange, tokyonight defaults to blue.
    hl.Type      = { fg = palette.red }
    hl["@type"]  = { fg = palette.red }

    -- Headings: the Retta spectrum, loudest to quietest — pumpkin → sand → green.
    hl["@markup.heading.1.markdown"]   = { fg = palette.accent, bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.bright_yellow, bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.bright_green, bold = true }

    hl["@markup.link.url"]   = { fg = palette.blue, underline = true }
    hl["@markup.link.label"] = { fg = palette.accent }
  end,
})
