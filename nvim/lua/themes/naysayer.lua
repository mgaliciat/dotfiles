-- ─── theme: naysayer ─────────────────────────────────────────
-- Cross-stack mirror of the `naysayer` theme (same id in ghostty/themes/naysayer
-- and tmux/themes/naysayer.conf — one palette, three layers).
--
-- Jonathan Blow's editor colours (Emacs, later his own editor). He never shipped
-- a theme: the source of truth is his editor's colour-slot table, reverse-engineered
-- from his streams (https://vegard.wiki/w/Jon_Blow_emacs_colorscheme). The nvim
-- ports on GitHub (naysayer.vim, deepwater.nvim, …) each re-interpret it — we
-- mirror the table directly instead of inheriting someone's interpretation.
--
-- Anchors:
--   #052329 bg (deep teal — the signature; not gray, not blue)
--   #d0c0a0 fg (warm sand)
--   #40c040 comment — the BRIGHTEST thing on screen, inverting the usual
--           "comments are noise, dim them" convention. He reads his comments.
--   #90c090 cursor · #d8b488 statusline · #46494d line numbers (Ghost_Character)
--
-- Slots he has no colour for (red, blue, magenta) are derived on his own
-- 0x40/0x80/0xb0/0xc0/0xf0 grid — see ghostty/themes/naysayer for the reasoning.
--
-- tokyonight base: variant `night`.
-- No bold/italics in his setup; we keep bold only where nvim needs a structural
-- cue that colour alone can't carry (headings, cursorline number).

local palette = {
  bg            = "#052329",       -- Background
  bg_dark       = "#041b20",       -- derived: sidebars, one step down
  bg_highlight  = "#0010ff",       -- Highlight — pure blue, loud, authentic
  bg_visual     = "#0010ff",
  bg_float      = "#0a3038",       -- derived: popups sit between bg and Margin
  bg_popup      = "#0a3038",
  bg_search     = "#003a3a",       -- Highlight_White — already his "mark this" bg
  bg_sidebar    = "#041b20",
  bg_statusline = "#183848",       -- Margin — the bar's bg in his editor

  fg            = "#d0c0a0",       -- Default
  fg_dark       = "#a09880",       -- derived: dimmed Default
  fg_gutter     = "#46494d",       -- Ghost_Character — his slot for inert text

  black         = "#183848",       -- ansi0  Margin
  red           = "#c04040",       -- ansi1  derived (channel-swap of comment green)
  green         = "#40c040",       -- ansi2  Comment
  yellow        = "#ffbb00",       -- ansi3  Paste
  blue          = "#4080c0",       -- ansi4  derived
  magenta       = "#c040c0",       -- ansi5  derived
  cyan          = "#40b0a0",       -- ansi6  Str_Constant
  white         = "#d0c0a0",       -- ansi7  Default

  bright_black   = "#46494d",      -- ansi8  Ghost_Character
  bright_red     = "#f08080",      -- ansi9  derived
  bright_green   = "#b0ffb0",      -- ansi10 Preproc
  bright_yellow  = "#ffd040",      -- ansi11 derived
  bright_blue    = "#80b0f0",      -- ansi12 derived
  bright_magenta = "#f080f0",      -- ansi13 derived
  bright_cyan    = "#80f0e0",      -- ansi14 Int_Constant
  bright_white   = "#f0e8d0",      -- ansi15 derived

  comment       = "#40c040",       -- Comment — brightest on screen, on purpose
  border        = "#184d68",       -- Margin_Hover
  cursor        = "#90c090",       -- Cursor
  accent        = "#20d0e0",       -- Pop1 — his "stand out" slot
  bar           = "#d8b488",       -- Bar — statusline fg
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
    c.orange    = palette.bar             -- no orange in his palette; Bar (#d8b488) is the warmest slot he has

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#0a3038" }        -- one step over bg, same as floats
    hl.CursorLineNr = { fg = palette.bar, bold = true }
    hl.LineNr       = { fg = c.fg_gutter }

    hl.FloatBorder = { fg = palette.border, bg = c.bg_float }
    hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

    hl.TelescopeBorder       = { fg = palette.border, bg = c.bg_float }
    hl.TelescopePromptBorder = { fg = palette.accent, bg = c.bg_float }
    hl.TelescopeMatching     = { fg = palette.accent, bold = true }

    hl.GitSignsAdd    = { fg = c.green }
    hl.GitSignsChange = { fg = c.yellow }
    hl.GitSignsDelete = { fg = c.red }

    -- Inline code: Margin as the raised bg + Str_Constant teal, since a code
    -- span is a literal — same family as a string in his palette.
    local code_bg = "#183848"
    local code_fg = palette.cyan
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    -- Headings: Bar → Pop1 → Preproc. Warm sand for h1, then his two "notice
    -- this" slots — staying inside the palette instead of inventing a hierarchy.
    hl["@markup.heading.1.markdown"]   = { fg = palette.bar,          bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.accent,       bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.bright_green, bold = true }

    hl["@markup.link.url"]   = { fg = palette.cyan, underline = true }
    hl["@markup.link.label"] = { fg = palette.accent }
  end,
}
