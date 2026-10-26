-- ─── theme: flexoki-light ────────────────────────────────────
-- Flexoki's light half, printing inks on warm paper, mirror of the Ghostty
-- theme `flexoki-light`. tokyonight base: variant `day`.
--
-- Hex from Flexoki itself (kepano/flexoki-neovim's palette.lua, the same
-- values Ghostty's built-in "Flexoki Light" ships); provenance, the one
-- deviation (ANSI 8) and the OLED rationale live in ghostty/themes/flexoki-light.
-- Derived, and marked so: the diff and search tints, set in OKLCH on each
-- accent's own hue.
--
-- Roles: blue functions and accent, rose keywords (tokyonight's purple follows
-- `_base` onto the magenta, h 350; Flexoki's own purple is not used anywhere),
-- cyan strings, orange numbers/constants and inline code, base-600 comments.
--
-- Light theme convention: the "bright" colors are Flexoki's 400s, LIGHTER than
-- the normal 600s, as in the Ghostty file.
--
-- tokyonight builds `day` by inverting `night` and derives several slots from
-- it BEFORE on_colors runs (diff, rainbow, the terminal table, diagnostics,
-- `black`), so those are re-pointed below; left alone they would carry
-- inverted tokyonight hues, purple among them.

local palette = {
  bg          = "#fffcf0",       -- paper
  bg_dark     = "#f2f0e5",       -- base-50 — code bg / sidebars
  bg_highlight= "#f2f0e5",       -- cursorline
  bg_visual   = "#cecdc3",       -- base-200, Ghostty's selection; ink 12.0:1
  bg_float    = "#f2f0e5",
  bg_popup    = "#f2f0e5",
  bg_search   = "#f5d983",       -- derived: yellow h 92 at L 0.89, ink 13.8:1
  bg_sidebar  = "#f2f0e5",
  bg_statusline = "#e6e4d9",     -- base-100

  fg          = "#100f0f",       -- ink, 18.6:1
  fg_dark     = "#575653",       -- base-700, 7.1:1
  fg_gutter   = "#878580",       -- base-500, 3.6:1

  black       = "#100f0f",
  red         = "#af3029",
  green       = "#66800b",
  yellow      = "#ad8301",
  blue        = "#205ea6",
  magenta     = "#a02f6f",
  cyan        = "#24837b",
  white       = "#6f6e69",

  bright_black   = "#878580",
  bright_red     = "#d14d41",
  bright_green   = "#879a39",
  bright_yellow  = "#d0a215",
  bright_blue    = "#4385be",
  bright_magenta = "#ce5d97",
  bright_cyan    = "#3aa99f",
  bright_white   = "#cecdc3",

  orange      = "#bc5215",       -- orange-600 (no ANSI slot), 4.7:1

  -- base-600, Flexoki's muted text `tx-2` (5.0:1). Its faint text `tx-3`,
  -- base-300 #b7b5ac, is 2.0:1 on the paper: decoration, not something to read.
  comment     = "#6f6e69",
  border      = "#b7b5ac",       -- base-300
  faint       = "#b7b5ac",       -- whitespace, non-text
  cursor      = "#100f0f",
  accent      = "#205ea6",       -- blue, the slot solarized-patched used too
}

-- Derived tints for diffs, ink on each at 12:1 or more.
local diff = {
  add    = "#e1eeca",            -- green h 123, L 0.93
  delete = "#fedbd6",            -- red   h 28,  L 0.92
  change = "#d9eaff",            -- blue  h 255, L 0.93
  text   = "#b3d4ff",            -- blue  h 255, L 0.86
}

return require("themes._base")({
  style = "day",
  palette = palette,

  -- Opaque: a light canvas cannot take Ghostty's glass (see colorscheme.lua).
  transparent = false,

  -- Inline code: base-50 + orange, 4.2:1.
  code = { fg = palette.orange },

  on_colors = function(c)
    c.orange   = palette.orange
    c.teal     = palette.cyan
    c.dark3    = palette.faint
    c.dark5    = palette.comment
    c.bg_dark1 = palette.bg_statusline

    -- tokyonight paints its `black` as ink ON an accent (IncSearch, the
    -- statusline's mode block); on paper that ink is the paper.
    c.black = palette.bg

    c.diff = diff

    c.error   = palette.red
    c.warning = palette.yellow
    c.info    = palette.blue
    c.hint    = palette.cyan
    c.todo    = palette.blue

    -- tokyonight's order, with the purple slot taken by the bright blue.
    c.rainbow = {
      palette.blue, palette.yellow, palette.green, palette.cyan,
      palette.magenta, palette.bright_blue, palette.orange, palette.red,
    }

    -- `:terminal` gets the Ghostty file's ANSI table, not tokyonight's.
    c.terminal = {
      black          = palette.black,
      black_bright   = palette.bright_black,
      red            = palette.red,
      red_bright     = palette.bright_red,
      green          = palette.green,
      green_bright   = palette.bright_green,
      yellow         = palette.yellow,
      yellow_bright  = palette.bright_yellow,
      blue           = palette.blue,
      blue_bright    = palette.bright_blue,
      magenta        = palette.magenta,
      magenta_bright = palette.bright_magenta,
      cyan           = palette.cyan,
      cyan_bright    = palette.bright_cyan,
      white          = palette.white,
      white_bright   = palette.bright_white,
    }
  end,

  on_highlights = function(hl)
    hl.ColorColumn       = { bg = palette.bg_dark }
    hl.TelescopeMatching = { fg = palette.orange, bold = true }

    hl["@markup.heading.1.markdown"]   = { fg = palette.blue,    bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.magenta, bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.orange,  bold = true }

    hl["@markup.link.url"]   = { fg = palette.blue, underline = true }
    hl["@markup.link.label"] = { fg = palette.cyan }
  end,
})
