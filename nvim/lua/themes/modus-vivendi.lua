-- ─── theme: modus-vivendi ────────────────────────────────────
-- Port of Emacs's Modus Vivendi (Protesilaos Stavrou): pure white on pure
-- black, every accent at 7:1 or more. Mirror of the Ghostty theme
-- `modus-vivendi`. tokyonight base: variant `night`.
--
-- Hex verbatim from `modus-themes-vivendi-palette` in modus-themes.el; the
-- names in the comments are upstream's. Nothing is derived: the diff, search,
-- region and paren backgrounds are upstream's own entries too.
--
-- Roles are Modus's semantic mappings, which is what makes it look like Emacs:
--   keyword  magenta-cooler #b6a0ff   string   blue-warmer #79a8ff
--   type     cyan-cooler    #6ae4b9   fnname   magenta     #feacd0
--   variable cyan           #00d3d0   constant blue-cooler #00bcff
--   builtin  magenta-warmer #f78fe7   comment  fg-dim      #989898
-- Numbers, operators, punctuation and calls stay plain fg, as Emacs leaves them;
-- tokyonight colours all four, so they are reset below. Variables are cyan where
-- they are declared (parameters, properties) and plain fg where used.
--
-- Dark theme convention: the "bright" colors are LIGHTER than the normal ones.
--
-- tokyonight derives several slots from its own `night` palette BEFORE
-- on_colors runs (diff, rainbow, the terminal table, diagnostics, `black`), so
-- those are re-pointed below.

local palette = {
  bg          = "#000000",       -- bg-main
  bg_dark     = "#1e1e1e",       -- bg-dim — code bg, line-number column
  bg_highlight= "#2f3849",       -- bg-hl-line — cursorline
  bg_visual   = "#5a5a5a",       -- bg-region, fg on it 6.9:1
  bg_float    = "#1e1e1e",
  bg_popup    = "#1e1e1e",
  bg_search   = "#2266ae",       -- bg-cyan-intense (bg-search-lazy), 5.9:1
  bg_sidebar  = "#1e1e1e",
  bg_statusline = "#505050",     -- bg-mode-line-active, fg on it 8.1:1

  fg          = "#ffffff",       -- fg-main, 21:1
  fg_dark     = "#a6a6a6",       -- fg-term-white, 8.6:1
  fg_gutter   = "#989898",       -- fg-dim, the line numbers, 7.3:1

  black       = "#000000",
  red         = "#ff5f59",       -- red
  green       = "#44bc44",       -- green
  yellow      = "#d0bc00",       -- yellow
  blue        = "#2fafff",       -- blue
  magenta     = "#feacd0",       -- magenta (fnname)
  cyan        = "#00d3d0",       -- cyan (variable)
  white       = "#a6a6a6",

  bright_black   = "#595959",   -- ANSI 8 (3.0:1)
  bright_red     = "#ff6b55",   -- red-warmer
  bright_green   = "#00c06f",   -- green-cooler
  bright_yellow  = "#fec43f",   -- yellow-warmer
  bright_blue    = "#79a8ff",   -- blue-warmer (string)
  bright_magenta = "#b6a0ff",   -- magenta-cooler (keyword)
  bright_cyan    = "#6ae4b9",   -- cyan-cooler (type)
  bright_white   = "#ffffff",

  constant    = "#00bcff",       -- blue-cooler, 9.6:1
  builtin     = "#f78fe7",       -- magenta-warmer
  docstring   = "#9ac8e0",       -- cyan-faint
  preproc     = "#ff7f86",       -- red-cooler
  regexp      = "#00c06f",       -- green-cooler (rx-construct)
  orange      = "#db7b5f",       -- rust: Modus has no orange; its nearest named one

  comment     = "#989898",       -- fg-dim
  border      = "#646464",       -- border
  cursor      = "#ffffff",       -- fg-main
  accent      = "#00bcff",       -- blue-cooler, accent-0
}

-- bg-added / bg-removed / bg-changed / bg-changed-refine; fg on each 9.2:1+.
local diff = {
  add    = "#00381f",
  delete = "#4f1119",
  change = "#363300",
  text   = "#4a4a00",
}

local keyword = palette.bright_magenta
local str     = palette.bright_blue
local typ     = palette.bright_cyan
local fnname  = palette.magenta

return require("themes._base")({
  style = "night",
  palette = palette,
  transparent = false,

  -- Inline code: bg-dim + cyan-cooler (fg-prose-code), 13.4:1 on the canvas.
  code = { fg = palette.bright_cyan },

  on_colors = function(c)
    c.green1   = palette.bright_green
    c.orange   = palette.orange
    c.teal     = palette.bright_cyan
    c.dark3    = palette.border
    c.dark5    = palette.comment
    c.bg_dark1 = palette.bg_dark

    -- tokyonight paints its `black` as ink ON an accent (IncSearch, the
    -- statusline's mode block): the canvas.
    c.black = palette.bg

    c.diff = diff

    c.error   = palette.red
    c.warning = palette.bright_yellow   -- Modus `warning` is yellow-warmer
    c.info    = palette.bright_cyan     -- and `info` cyan-cooler
    c.hint    = palette.cyan
    c.todo    = palette.constant

    -- Modus's own rainbow-delimiters order (rainbow-0 is fg-main), as the
    -- nested braces in Emacs show it.
    c.rainbow = {
      palette.fg, "#ff66ff", "#00eff0", palette.bright_red,
      "#efef00", keyword, "#44df44", str,
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
    local fg = { fg = palette.fg }

    -- The line-number column sits on bg-dim, the current one on bg-active.
    hl.LineNr       = { fg = palette.fg_gutter, bg = palette.bg_dark }
    hl.CursorLineNr = { fg = palette.fg, bg = "#535353", bold = true }
    hl.SignColumn   = { bg = palette.bg_dark }
    hl.MatchParen   = { bg = "#2f7f9f", fg = palette.fg }      -- bg-paren-match
    hl.IncSearch    = { bg = "#7a6100", fg = palette.fg }      -- bg-yellow-intense
    hl.CurSearch    = { bg = "#7a6100", fg = palette.fg }
    hl.PmenuSel     = { bg = "#2f447f" }                       -- bg-completion
    hl.TelescopeMatching = { fg = palette.constant, bold = true }

    -- Keywords: one colour for all of them, as Modus has one face.
    for _, g in ipairs({
      "Keyword", "Statement", "Conditional", "Repeat", "Exception", "Include",
      "StorageClass", "Structure", "Label",
      "@keyword", "@keyword.function", "@keyword.return", "@keyword.operator",
      "@keyword.conditional", "@keyword.repeat", "@keyword.exception",
      "@keyword.import", "@keyword.modifier", "@keyword.type",
      "@keyword.coroutine", "@variable.builtin",
    }) do
      hl[g] = { fg = keyword }
    end

    hl.String              = { fg = str }
    hl["@string"]          = { fg = str }
    hl.Character           = { fg = str }
    hl["@character"]       = { fg = str }
    hl["@string.escape"]   = { fg = palette.regexp }
    hl["@string.regexp"]   = { fg = palette.regexp }
    hl["@string.documentation"]  = { fg = palette.docstring }
    hl["@comment.documentation"] = { fg = palette.docstring }

    hl.Type                  = { fg = typ }
    hl.Typedef               = { fg = typ }
    hl["@type"]              = { fg = typ }
    hl["@type.builtin"]      = { fg = typ }
    hl["@type.definition"]   = { fg = typ }
    hl["@constructor"]       = { fg = typ }

    -- Definitions are fnname; calls stay fg, as Emacs leaves them.
    hl.Function                 = { fg = fnname }
    hl["@function"]             = { fg = fnname }
    hl["@function.method"]      = { fg = fnname }
    hl["@function.call"]        = fg
    hl["@function.method.call"] = fg
    hl["@function.builtin"]     = { fg = palette.builtin }
    hl["@function.macro"]       = { fg = palette.preproc }

    hl.Identifier                = fg
    hl["@variable"]              = fg
    hl["@variable.member"]       = fg
    hl["@variable.parameter"]    = { fg = palette.cyan }
    hl["@property"]              = { fg = palette.cyan }

    hl.Constant              = { fg = palette.constant }
    hl["@constant"]          = { fg = palette.constant }
    hl["@constant.builtin"]  = { fg = palette.constant }
    hl.Boolean               = { fg = palette.constant }
    hl["@boolean"]           = { fg = palette.constant }
    hl["@module"]            = { fg = palette.constant }
    hl["@attribute"]         = { fg = palette.constant }
    hl.Number                = fg
    hl.Float                 = fg
    hl["@number"]            = fg
    hl["@number.float"]      = fg

    hl.PreProc               = { fg = palette.preproc }
    hl["@keyword.directive"] = { fg = palette.preproc }

    hl.Operator                    = fg
    hl["@operator"]                = fg
    hl.Delimiter                   = fg
    hl["@punctuation.delimiter"]   = fg
    hl["@punctuation.bracket"]     = fg
    hl["@punctuation.special"]     = fg

    -- Headings: fg-heading-1..3 (fg-main, yellow-faint, blue-faint).
    hl["@markup.heading.1.markdown"] = { fg = palette.fg,  bold = true }
    hl["@markup.heading.2.markdown"] = { fg = "#d2b580", bold = true }
    hl["@markup.heading.3.markdown"] = { fg = "#82b0ec", bold = true }

    hl["@markup.link.url"]   = { fg = str, underline = true }   -- fg-link
    hl["@markup.link.label"] = { fg = palette.cyan }               -- fg-link-symbolic
  end,
})
