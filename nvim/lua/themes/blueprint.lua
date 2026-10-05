-- ─── theme: blueprint ────────────────────────────────────────
-- The drafting sheet at night: a near-black canvas with cyan line work,
-- marked up in redline pencil and highlighter. Mirror of the Ghostty theme
-- `blueprint`. tokyonight base: variant `night`.
--
-- DERIVED, no published hex: the blueprint/cyanotype sheet gives the HUES
-- (near-black canvas, cyanotype white, cyan drafting line, redline
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
  bg          = "#0a0a0a",       -- neutral near-black, L 0.145
  bg_dark     = "#040404",       -- L 0.11 — code bg
  bg_highlight= "#191919",       -- L 0.215 — cursorline
  bg_visual   = "#2b2b2b",       -- L 0.29 — selection
  bg_float    = "#191919",
  bg_popup    = "#191919",
  bg_search   = "#0d515c",       -- cyan hue at L 0.40, fg on it 7.3:1
  bg_sidebar  = "#191919",
  bg_statusline = "#191919",

  fg          = "#d7ecf5",       -- cyanotype white, 16.2:1
  fg_dark     = "#a8bbc5",       -- 10.0:1
  fg_gutter   = "#696969",       -- 3.6:1

  black       = "#383838",
  red         = "#f75d59",       -- redline pencil
  green       = "#57c173",
  yellow      = "#e9c944",       -- highlighter
  blue        = "#66a0ee",
  magenta     = "#dd71c8",
  cyan        = "#33c6d9",
  white       = "#becdd5",

  bright_black   = "#8c8c8c",   -- graphite, the comment (5.9:1)
  bright_red     = "#fda19a",
  bright_green   = "#95dfa4",
  bright_yellow  = "#f5de87",
  bright_blue    = "#97c9fd",
  bright_magenta = "#edacde",
  bright_cyan    = "#86e2f0",
  bright_white   = "#edf7fb",

  orange        = "#f79643",     -- surveyor's orange (no ANSI slot)
  bright_orange = "#fdbf89",

  comment     = "#8c8c8c",
  border      = "#484848",       -- L 0.40
  cursor      = "#4be4ff",       -- drafting line, 13.0:1
  accent      = "#4be4ff",
}

return require("themes._base")({
  style = "night",
  palette = palette,

  -- Leaves the canvas to Ghostty, so its blueprint shader draws the grid
  -- straight through nvim instead of having to recognise a repainted canvas,
  -- and nothing changes if the glass comes back.
  transparent = true,

  -- 13.8:1 on the code bg; the code bg patch, not the hue, is what sets it
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
