-- ─── theme: carbon ───────────────────────────────────────────
-- Cross-stack mirror of the `carbon` theme (same id in ghostty/themes/carbon
-- and tmux/themes/carbon.conf — one palette, three layers).
-- Minimal + functional + high contrast over true black (#000000).
-- A single warm accent: Claude orange #d97757 (from the repo's brand
-- palette — do NOT invent other accent hex values).
--
-- Brand anchors:
--   #d97757 cursor/accent (Claude orange · the ONLY warm color)
--   #e4e4e4 neutral high-contrast fg over #000
--   #6a6a6a comment (mid gray, legible without shouting)
--   #000000 true black bg · monochrome ANSI palette + 6 desaturated hues
--
-- tokyonight base: variant `night`.
-- bg_statusline = #000000 is deliberate: the statusline blends into the
-- editor in true black, avoiding the "floating rectangle" when lualine
-- uses a bg different from Normal.

local palette = {
  bg            = "#000000",       -- true black
  bg_dark       = "#0a0a0a",       -- minimal raise (sidebars)
  bg_highlight  = "#2a2a2a",       -- selection bg (neutral gray)
  bg_visual     = "#2a2a2a",
  bg_float      = "#0d0d0d",       -- popups: barely distinguishable from bg
  bg_popup      = "#0d0d0d",
  bg_search     = "#3a3a3a",       -- search lighter than selection
  bg_sidebar    = "#0a0a0a",
  bg_statusline = "#000000",       -- blends into the editor in true black

  fg            = "#e4e4e4",       -- neutral high contrast
  fg_dark       = "#a0a0a0",
  fg_gutter     = "#3a3a3a",       -- subtle but legible line numbers

  black         = "#1c1c1c",       -- ansi0
  red           = "#e35f5f",       -- ansi1
  green         = "#9ec07c",       -- ansi2
  yellow        = "#d9a441",       -- ansi3
  blue          = "#7aa6c2",       -- ansi4
  magenta       = "#c08fb8",       -- ansi5
  cyan          = "#7fb5ad",       -- ansi6
  white         = "#d4d4d4",       -- ansi7

  bright_black   = "#4a4a4a",      -- ansi8
  bright_red     = "#ef7a7a",      -- ansi9
  bright_green   = "#b3d196",      -- ansi10
  bright_yellow  = "#e8be6a",      -- ansi11
  bright_blue    = "#9bc0d6",      -- ansi12
  bright_magenta = "#d4a8cd",      -- ansi13
  bright_cyan    = "#9fccc4",      -- ansi14
  bright_white   = "#ffffff",      -- ansi15

  comment       = "#6a6a6a",       -- mid gray
  border        = "#4a4a4a",       -- subtle
  cursor        = "#d97757",       -- Claude orange (the theme's brand)
  accent        = "#d97757",       -- same orange (the only warm one / focus)
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
    c.purple    = palette.magenta
    c.orange    = palette.accent          -- there's no orange in ANSI 16; the accent (Claude orange) is the only warm one

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#0d0d0d" }       -- minimal lift over #000
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

    -- Inline code: barely raised bg (ansi0) + desaturated green.
    local code_bg = "#1c1c1c"
    local code_fg = palette.green
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    -- Headings: orange (accent) → blue → green hierarchy (warm to cool).
    -- Only h1 uses the accent — minimalist restraint, the rest drop to cool hues.
    hl["@markup.heading.1.markdown"]   = { fg = palette.accent, bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.blue,   bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.green,  bold = true }

    hl["@markup.link.url"]   = { fg = palette.blue, underline = true }
    hl["@markup.link.label"] = { fg = palette.accent }
  end,
}
