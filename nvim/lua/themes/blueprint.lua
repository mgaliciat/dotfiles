-- ─── theme: blueprint ────────────────────────────────────────
-- The drafting sheet at night: a Prussian-blue canvas with cyan line work,
-- marked up in redline pencil and highlighter. Mirror of the Ghostty theme
-- `blueprint`. tokyonight base: variant `night`.
--
-- DERIVED, no published hex: the blueprint/cyanotype sheet gives the HUES
-- (night Prussian blue, cyanotype white, cyan drafting line, redline
-- correction pencil, highlighter yellow, surveyor's orange, graphite),
-- lightness and chroma are set per role in OKLCH. Figures and rationale are
-- in the ghostty file.
--
-- Roles: cyan drafting line for the accent, blue functions, pale blue types,
-- green strings, magenta keywords, surveyor's orange numbers/constants,
-- graphite comments. Types stay on tokyonight's blue1 slot (bright_blue):
-- painted cyan they would run together with modules, operators and
-- punctuation, which tokyonight paints from the same cyan.
--
-- Dark theme convention: the "bright" colors are LIGHTER than the normal ones.

local palette = {
  bg          = "#04172c",       -- night Prussian blue, L 0.20
  bg_dark     = "#020f1f",       -- L 0.165 — code bg
  bg_highlight= "#0d2137",       -- L 0.245 — cursorline
  bg_visual   = "#18324e",       -- L 0.31 — selection
  bg_float    = "#0d2137",
  bg_popup    = "#0d2137",
  bg_search   = "#0d515c",       -- cyan hue at L 0.40, fg on it 7.3:1
  bg_sidebar  = "#0d2137",
  bg_statusline = "#0d2137",

  fg          = "#d7ecf5",       -- cyanotype white, 14.8:1
  fg_dark     = "#a8bbc5",       -- 9.1:1
  fg_gutter   = "#566b83",       -- 3.3:1

  black       = "#263d58",
  red         = "#f75d59",       -- redline pencil
  green       = "#57c173",
  yellow      = "#e9c944",       -- highlighter
  blue        = "#66a0ee",
  magenta     = "#dd71c8",
  cyan        = "#33c6d9",
  white       = "#becdd5",

  bright_black   = "#7090ac",   -- graphite, the comment (5.4:1)
  bright_red     = "#fda19a",
  bright_green   = "#95dfa4",
  bright_yellow  = "#f5de87",
  bright_blue    = "#97c9fd",
  bright_magenta = "#edacde",
  bright_cyan    = "#86e2f0",
  bright_white   = "#edf7fb",

  orange        = "#f79643",     -- surveyor's orange (no ANSI slot)
  bright_orange = "#fdbf89",

  comment     = "#7090ac",
  border      = "#394f68",       -- L 0.42
  cursor      = "#4be4ff",       -- drafting line, 11.9:1
  accent      = "#4be4ff",
}

return require("themes._base")({
  style = "night",
  palette = palette,

  -- Ghostty runs its glass (background-opacity 0.9); without this nvim paints
  -- an opaque canvas over it and the seam shows at every split edge. The two
  -- move together (config.ghostty).
  transparent = true,

  -- 13:1 on the code bg; the code bg patch, not the hue, is what sets it
  -- apart from the accent.
  code = { fg = palette.bright_cyan },

  on_colors = function(c)
    c.green1    = palette.bright_green
    c.orange    = palette.orange
  end,

  on_highlights = function(hl)
    hl.TelescopeMatching     = { fg = palette.yellow, bold = true }

    -- H3 is the warm bright_orange, not bright_cyan: next to the accent H1
    -- the two cyans measure 1.02:1 and the ladder would read as two levels.
    hl["@markup.heading.1.markdown"]   = { fg = palette.accent,        bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.yellow,        bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.bright_orange, bold = true }

    hl["@markup.link.url"]   = { fg = palette.cyan, underline = true }
    hl["@markup.link.label"] = { fg = palette.bright_blue }
  end,
})
