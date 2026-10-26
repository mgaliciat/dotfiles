-- ─── theme: slate ────────────────────────────────────────────
-- Tailwind's slate greys at night: a soft blue-grey canvas with Tailwind's
-- own accents and no purple. Mirror of the Ghostty theme `slate`.
-- tokyonight base: variant `night`.
--
-- Hex from the Tailwind CSS v3 default palette, verbatim; which swatch fills
-- which slot, and the contrast figures, are in the ghostty file. Derived, and
-- marked so: the search and diff tints, set in OKLCH on each accent's own hue.
--
-- Roles: sky accent, blue functions, pale blue types, green strings, pink
-- keywords (tokyonight's purple follows `_base` onto the magenta, h 350),
-- orange numbers/constants, slate-400 comments.
--
-- Dark theme convention: the "bright" colors are LIGHTER than the normal ones.
--
-- tokyonight derives several slots from its own `night` palette BEFORE
-- on_colors runs (diff, rainbow, the terminal table, diagnostics, `black`), so
-- those are re-pointed below; left alone they would carry tokyonight's
-- lavender and violet into rainbow delimiters and `:terminal`.

local palette = {
  bg          = "#0f172a",       -- slate-900, L 0.21
  bg_dark     = "#020617",       -- slate-950 — code bg
  bg_highlight= "#1e293b",       -- slate-800 — cursorline
  bg_visual   = "#334155",       -- slate-700 — selection, fg on it 8.4:1
  bg_float    = "#1e293b",
  bg_popup    = "#1e293b",
  bg_search   = "#054e6b",       -- derived: sky h 233 at L 0.40, fg on it 7.4:1
  bg_sidebar  = "#1e293b",
  bg_statusline = "#1e293b",

  fg          = "#e2e8f0",       -- slate-200, 14.5:1
  fg_dark     = "#cbd5e1",       -- slate-300, 12.0:1
  fg_gutter   = "#64748b",       -- slate-500, 3.8:1

  black       = "#334155",
  red         = "#f87171",       -- red-400
  green       = "#4ade80",       -- green-400
  yellow      = "#facc15",       -- yellow-400
  blue        = "#60a5fa",       -- blue-400
  magenta     = "#f472b6",       -- pink-400
  cyan        = "#22d3ee",       -- cyan-400
  white       = "#cbd5e1",

  bright_black   = "#64748b",   -- slate-500, ANSI 8 (3.8:1)
  bright_red     = "#fca5a5",
  bright_green   = "#86efac",
  bright_yellow  = "#fde047",
  bright_blue    = "#93c5fd",
  bright_magenta = "#f9a8d4",
  bright_cyan    = "#67e8f9",
  bright_white   = "#f1f5f9",

  orange        = "#fb923c",     -- orange-400 (no ANSI slot), 7.9:1
  bright_orange = "#fdba74",

  comment     = "#94a3b8",       -- slate-400, 7.0:1, one step above ANSI 8
  border      = "#475569",       -- slate-600
  cursor      = "#38bdf8",       -- sky-400, 8.3:1
  accent      = "#38bdf8",
}

-- Derived tints for diffs, fg on each at 6.9:1 or more.
local diff = {
  add    = "#194828",            -- green h 152, L 0.36
  delete = "#682224",            -- red   h 22,  L 0.36
  change = "#1f3654",            -- blue  h 255, L 0.33
  text   = "#284e7d",            -- blue  h 255, L 0.42
}

return require("themes._base")({
  style = "night",
  palette = palette,

  -- Opaque: Ghostty runs solid (background-opacity 1.0) and slate has no
  -- shader to see through to.
  transparent = false,

  -- Inline code: slate-950 + bright cyan, 13.9:1; the darker patch, not the
  -- hue, is what sets it apart from the accent.
  code = { fg = palette.bright_cyan },

  on_colors = function(c)
    c.green1   = palette.bright_green
    c.orange   = palette.orange
    c.teal     = palette.cyan
    c.dark3    = palette.border
    c.dark5    = palette.comment
    c.bg_dark1 = palette.bg_dark

    -- tokyonight paints its `black` as ink ON an accent (IncSearch, the
    -- statusline's mode block): the canvas.
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
    hl.TelescopeMatching = { fg = palette.yellow, bold = true }

    hl["@markup.heading.1.markdown"]   = { fg = palette.accent,  bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.magenta, bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.orange,  bold = true }

    hl["@markup.link.url"]   = { fg = palette.cyan, underline = true }
    hl["@markup.link.label"] = { fg = palette.bright_blue }
  end,
})
