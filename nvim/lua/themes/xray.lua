-- ─── theme: xray ─────────────────────────────────────────────
-- Cross-stack mirror of the `xray` theme (same id in ghostty/themes/xray
-- and tmux/themes/xray.conf — one palette, three layers).
-- The palette of Ghostty's own `xray` dock icon (macos-icon = xray): a
-- monochrome PCB with a silver ghost. Grays sampled from the icon
-- (`XrayImage` in Ghostty.app's Assets.car, 1.3.1), not guessed:
--
--   #101010 board (canvas)          #202020 / #303030 traces
--   #4c4c4c chip legs / screws      #808080 · #a0a0a0 solder, silk
--   #cdcecf ghost body (fg)         #f0f0f0 ghost highlight
--   #a3b5c6 "film blue" accent — the icon's faint cool cast, pushed to usable
--
-- ANSI hues are kept but LOW-chroma ("under x-ray"): a grayscale editor
-- loses diffs and diagnostics, so each hue survives at ~40% saturation
-- (raised from ~30%: the first cut read as gray on gray).
--
-- tokyonight base: variant `night`.
-- bg_statusline = bg on purpose: the bar blends into the board instead of
-- floating as a lighter rectangle.

local palette = {
  bg            = "#101010",       -- the board
  bg_dark       = "#0a0a0a",       -- sidebars: a notch darker than the board
  bg_highlight  = "#303030",       -- selection bg (trace gray)
  bg_visual     = "#303030",
  bg_float      = "#181818",       -- popups: one step above the board
  bg_popup      = "#181818",
  bg_search     = "#404040",       -- search lighter than selection
  bg_sidebar    = "#0a0a0a",
  bg_statusline = "#101010",       -- blends into the board

  fg            = "#cdcecf",       -- ghost silver
  fg_dark       = "#a0a0a0",       -- silkscreen
  fg_gutter     = "#404040",       -- line numbers: visible, not shouting

  black         = "#202020",       -- ansi0
  red           = "#d06e6e",       -- ansi1
  green         = "#80bf80",       -- ansi2
  yellow        = "#d1b46c",       -- ansi3
  blue          = "#71a1c6",       -- ansi4
  magenta       = "#b188bc",       -- ansi5
  cyan          = "#75b9bf",       -- ansi6
  white         = "#cdcecf",       -- ansi7

  bright_black   = "#4c4c4c",      -- ansi8
  bright_red     = "#e37b7b",      -- ansi9
  bright_green   = "#96d096",      -- ansi10
  bright_yellow  = "#e4cd7c",      -- ansi11
  bright_blue    = "#8eb9dc",      -- ansi12
  bright_magenta = "#c79cd5",      -- ansi13
  bright_cyan    = "#8fd0d5",      -- ansi14
  bright_white   = "#f0f0f0",      -- ansi15

  comment       = "#707070",       -- solder gray, one step under the silkscreen
  border        = "#4c4c4c",       -- chip legs
  cursor        = "#a3b5c6",       -- film blue
  accent        = "#a3b5c6",       -- same — the only accent / focus
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
    c.orange    = palette.yellow          -- no warm accent in this palette: orange collapses onto the muted yellow

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    -- Diff BACKGROUNDS. tokyonight blends its own green2/red1/blue7 into the
    -- canvas, which lands teal (#243e4a) and wine (#4a272f) — loud blocks in a
    -- monochrome buffer. These are the board (#101010) with ~10% of each hue:
    -- a tint you read as green/red next to the fg colour, not a fill.
    -- Used by DiffAdd/DiffDelete/DiffChange/DiffText, hence by codediff's
    -- line tint (it derives its brighter character tint from these).
    c.diff = {
      add    = "#1a261a",
      delete = "#2a1a1a",
      change = "#262418",
      text   = "#3a3828",
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#181818" }       -- one step over the board
    hl.CursorLineNr = { fg = palette.accent, bold = true }
    hl.LineNr       = { fg = c.fg_gutter }

    hl.FloatBorder = { fg = palette.border, bg = c.bg_float }
    hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

    hl.TelescopeBorder       = { fg = palette.border, bg = c.bg_float }
    hl.TelescopePromptBorder = { fg = palette.accent, bg = c.bg_float }
    hl.TelescopeMatching     = { fg = palette.accent, bold = true }

    -- Gutter signs in the BRIGHT variants: the normals are tuned for text on
    -- the board, and a one-cell strip needs more contrast than a word does.
    -- *Nr paints the line number (gitsigns numhl); *Staged keeps the normal
    -- shade so staged reads as "already handled" next to unstaged.
    hl.GitSignsAdd          = { fg = palette.bright_green }
    hl.GitSignsChange       = { fg = palette.bright_yellow }
    hl.GitSignsDelete       = { fg = palette.bright_red }
    hl.GitSignsUntracked    = { fg = palette.bright_cyan }
    hl.GitSignsAddNr        = { fg = palette.bright_green,  bold = true }
    hl.GitSignsChangeNr     = { fg = palette.bright_yellow, bold = true }
    hl.GitSignsDeleteNr     = { fg = palette.bright_red,    bold = true }
    hl.GitSignsUntrackedNr  = { fg = palette.bright_cyan,   bold = true }
    hl.GitSignsStagedAdd    = { fg = palette.green }
    hl.GitSignsStagedChange = { fg = palette.yellow }
    hl.GitSignsStagedDelete = { fg = palette.red }
    hl.GitSignsStagedAddNr    = { fg = palette.green }
    hl.GitSignsStagedChangeNr = { fg = palette.yellow }
    hl.GitSignsStagedDeleteNr = { fg = palette.red }

    -- Inline code: trace-gray bg (ansi0) + the ghost highlight as fg — code
    -- reads as "etched", the brightest thing in a prose buffer.
    local code_bg = "#202020"
    local code_fg = palette.bright_white
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    -- Headings: brightness hierarchy, not hue — h1 is the ghost highlight,
    -- h2 the accent, h3 the steel blue. Monochrome first, colour second.
    hl["@markup.heading.1.markdown"]   = { fg = palette.bright_white, bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.accent,       bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.blue,         bold = true }

    hl["@markup.link.url"]   = { fg = palette.blue, underline = true }
    hl["@markup.link.label"] = { fg = palette.accent }
    -- (A Neogit block lived here until sep-2026; lazygit replaced it and
    --  takes its colours from lazygit/config.yml, not from this theme.)
  end,
}
