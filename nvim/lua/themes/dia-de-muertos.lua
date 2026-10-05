-- ─── theme: dia-de-muertos ───────────────────────────────────
-- The night of the vigil: a purple-black canvas lit by cempasúchil, rosa
-- mexicano and candle flame. Mirror of the Ghostty theme `dia-de-muertos`.
-- tokyonight base: variant `night`.
--
-- DERIVED, no published hex: the altar gives the HUES (morado, cempasúchil,
-- grana cochinilla, papel picado green, veladora, talavera, rosa mexicano,
-- turquoise, bone, copal), lightness and chroma are set per role in OKLCH.
-- Figures and rationale are in the ghostty file.
--
-- Roles: rosa mexicano keywords, cempasúchil numbers/constants and the
-- accent, talavera functions, turquoise types, papel picado green strings,
-- copal smoke comments.
--
-- Dark theme convention: the "bright" colors are LIGHTER than the normal ones.

local palette = {
  bg          = "#1d1022",       -- morado night, L 0.20
  bg_dark     = "#150918",       -- L 0.165 — code bg
  bg_highlight= "#29192e",       -- L 0.245 — cursorline
  bg_visual   = "#3d2644",       -- L 0.31 — selection
  bg_float    = "#29192e",
  bg_popup    = "#29192e",
  bg_search   = "#6a3a06",       -- cempasúchil hue at L 0.40, fg on it 7.4:1
  bg_sidebar  = "#29192e",
  bg_statusline = "#29192e",

  fg          = "#ede3d2",       -- hueso, L 0.92
  fg_dark     = "#c0b6a6",       -- L 0.78
  fg_gutter   = "#736278",       -- L 0.52, 3.3:1

  black       = "#47334d",
  red         = "#f75c61",       -- grana cochinilla
  green       = "#50bc59",       -- papel picado
  yellow      = "#e6b731",       -- veladora
  blue        = "#5d9bf7",       -- talavera
  magenta     = "#fd449d",       -- rosa mexicano
  cyan        = "#1abcb8",       -- turquoise
  white       = "#d2c9bb",

  bright_black   = "#9385a5",   -- copal smoke, the comment (5.3:1)
  bright_red     = "#ff9592",
  bright_green   = "#89d78c",
  bright_yellow  = "#f6d476",
  bright_blue    = "#95c0ff",   -- Ghostty's ANSI 12 is #ffbb76 on purpose (see there)
  bright_magenta = "#ff94bd",
  bright_cyan    = "#6dd9d5",
  bright_white   = "#faf5ea",

  orange        = "#fc9417",     -- cempasúchil (no ANSI slot)
  bright_orange = "#ffbb76",

  comment     = "#9385a5",
  border      = "#59445f",       -- L 0.42
  cursor      = "#fc9417",
  accent      = "#fc9417",
}

return require("themes._base")({
  style = "night",
  palette = palette,

  -- Ghostty runs its glass (background-opacity 0.9); without this nvim paints
  -- an opaque canvas over it and the seam shows at every split edge. The two
  -- move together (config.ghostty).
  transparent = true,

  code = { fg = palette.bright_orange },

  on_colors = function(c)
    c.green1    = palette.bright_green
    c.orange    = palette.orange
  end,

  on_highlights = function(hl)
    hl.TelescopeMatching     = { fg = palette.magenta, bold = true }

    hl["@markup.heading.1.markdown"]   = { fg = palette.accent,      bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.magenta,     bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.bright_cyan, bold = true }

    hl["@markup.link.url"]   = { fg = palette.cyan, underline = true }
    hl["@markup.link.label"] = { fg = palette.bright_magenta }
  end,
})
