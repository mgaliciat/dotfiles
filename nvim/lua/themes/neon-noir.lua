-- ─── theme: neon-noir ────────────────────────────────────────
-- Cross-stack mirror of the `neon-noir` theme (same id in ghostty/themes/neon-noir
-- and tmux/themes/neon-noir.conf — one palette, three layers).
-- True black (#000000) noir canvas + a cool, saturated neon spectrum.
--
-- DERIVED palette, NOT a port: it borrows the name and the intent of the
-- "Neon Noir" preset Xcode 27 ships, but Apple publishes no hex for its presets.
-- Full provenance note (and how to turn this into a real port) lives in the
-- header of ghostty/themes/neon-noir — read that before changing a value.
--
-- Anchors:
--   #ff4d9d cursor/accent (neon magenta · keywords)
--   #6fd3ff types, #5aa9ff functions, #4fd6a8 strings, #ffb454 numbers
--   #62788f comment (slate, 4.6:1 over #000 — legible without shouting)
--   #000000 true black bg · cool-biased ANSI, amber the only warm slot
--
-- tokyonight base: variant `night`.
-- bg_statusline = #000000 is deliberate: the statusline blends into the
-- editor in true black, avoiding the "floating rectangle" when lualine
-- uses a bg different from Normal.

local palette = {
  bg            = "#000000",       -- true black
  bg_dark       = "#080b10",       -- minimal raise (sidebars)
  bg_highlight  = "#325b90",       -- selection bg (deep blue band, 3.03:1 over #000)
  bg_visual     = "#325b90",
  bg_float      = "#0c1017",       -- popups: barely lifted off the canvas
  bg_popup      = "#0c1017",
  bg_search     = "#3d6eae",       -- search lighter than selection
  bg_sidebar    = "#080b10",
  bg_statusline = "#000000",       -- blends into the editor in true black

  fg            = "#dbe6f4",       -- cool off-white
  fg_dark       = "#8fa3b8",
  fg_gutter     = "#2b3746",       -- subtle but legible line numbers

  black         = "#10151d",       -- ansi0
  red           = "#ff5f6d",       -- ansi1
  green         = "#4fd6a8",       -- ansi2
  yellow        = "#ffb454",       -- ansi3
  blue          = "#5aa9ff",       -- ansi4
  magenta       = "#ff4d9d",       -- ansi5
  cyan          = "#6fd3ff",       -- ansi6
  white         = "#c3cddb",       -- ansi7

  bright_black   = "#62788f",      -- ansi8
  bright_red     = "#ff8a93",      -- ansi9
  bright_green   = "#7ee9c4",      -- ansi10
  bright_yellow  = "#ffcb7d",      -- ansi11
  bright_blue    = "#86c2ff",      -- ansi12
  bright_magenta = "#ff7fba",      -- ansi13
  bright_cyan    = "#9ce3ff",      -- ansi14
  bright_white   = "#ffffff",      -- ansi15

  comment       = "#62788f",       -- slate (same as bright_black — one dim value)
  border        = "#2c4f7c",       -- cool, not neutral
  cursor        = "#ff4d9d",       -- neon magenta (the theme's signature)
  accent        = "#ff4d9d",
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
    c.blue1     = palette.bright_blue
    c.blue2     = palette.blue
    c.blue5     = palette.cyan
    c.blue6     = palette.bright_cyan
    c.blue7     = palette.bright_blue
    c.cyan      = palette.cyan
    c.magenta   = palette.magenta
    c.magenta2  = palette.bright_magenta
    c.purple    = palette.bright_magenta
    c.orange    = palette.yellow          -- no orange slot in ANSI 16; amber is the only warm hue

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#0c1017" }       -- minimal lift over #000
    hl.CursorLineNr = { fg = palette.accent, bold = true }
    hl.LineNr       = { fg = c.fg_gutter }

    hl.FloatBorder = { fg = palette.border, bg = c.bg_float }
    hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

    hl.TelescopeBorder       = { fg = palette.border, bg = c.bg_float }
    hl.TelescopePromptBorder = { fg = palette.accent, bg = c.bg_float }
    hl.TelescopeMatching     = { fg = palette.accent, bold = true }

    hl.GitSignsAdd    = { fg = c.green }
    hl.GitSignsChange = { fg = c.yellow }
    hl.GitSignsDelete = { fg = c.red }

    -- Inline code: lifted noir black (ansi0) + the string mint.
    local code_bg = "#10151d"
    local code_fg = palette.green
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    -- Headings: magenta (accent) → cyan → blue. All neon, descending chroma.
    hl["@markup.heading.1.markdown"]   = { fg = palette.accent, bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.cyan,   bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.blue,   bold = true }

    hl["@markup.link.url"]   = { fg = palette.cyan, underline = true }
    hl["@markup.link.label"] = { fg = palette.accent }
  end,
}
