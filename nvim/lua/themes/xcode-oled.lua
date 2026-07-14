-- ─── theme: xcode-oled ───────────────────────────────────────
-- Mirror of ghostty/themes/xcode-oled and tmux/themes/xcode-oled.conf.
-- Xcode "Default (Dark)" syntax over true black (#000000) for OLED.
--
-- The hex values are the ones Apple ships in the Default (Dark).xccolortheme plist
-- (see the Ghostty theme's header for the provenance and why the
-- VS Code ports are not a valid source). Only deviation: the bg, which in
-- Xcode is #1f1f24 and here is pure black.
--
-- Brand anchors:
--   #fc5fa3 pink keyword (cursor · the theme's most iconic color)
--   #9ef1dd aqua type    (accent: focus/interactive)
--   #fc6a5d salmon string · #d0bf69 gold number
--   #000000 true black bg · #ffffff fg (xcode.syntax.plain)
--
-- tokyonight base: variant `night`.
-- bg_statusline = #000000 is deliberate: on OLED the statusline blends into
-- the editor and avoids the "floating rectangle" of a bg different from Normal.

local palette = {
  bg            = "#000000",       -- true black OLED
  bg_dark       = "#0a0a0a",       -- minimal raise (sidebars)
  bg_highlight  = "#515b70",       -- DVTSourceTextSelectionColor (Apple)
  bg_visual     = "#515b70",
  bg_float      = "#0d0d0d",       -- popups: barely distinguishable from bg
  bg_popup      = "#0d0d0d",
  bg_search     = "#515b70",
  bg_sidebar    = "#0a0a0a",
  bg_statusline = "#000000",       -- blends into the editor on OLED

  fg            = "#ffffff",       -- xcode.syntax.plain
  fg_dark       = "#dfdfe0",
  fg_gutter     = "#424d5b",       -- DVTSourceTextInvisiblesColor: subtle but legible

  black         = "#1f1f24",       -- Xcode's own bg
  red           = "#fc6a5d",       -- string
  green         = "#67b7a4",       -- identifier.function (teal-green, "project")
  yellow        = "#d0bf69",       -- number
  blue          = "#41a1c0",       -- declaration.other
  magenta       = "#fc5fa3",       -- keyword
  cyan          = "#5dd8ff",       -- declaration.type
  white         = "#dfdfe0",

  -- Apple doesn't define brights. 10/11/12/15 are hex values of theirs (the "light"
  -- version of the same token); 9/13/14 are the normal one +0.08 lightness in HSL.
  bright_black   = "#6c7986",      -- comment
  bright_red     = "#fd8f85",      -- derived
  bright_green   = "#9ef1dd",      -- identifier.type (aqua)
  bright_yellow  = "#ffdb8b",      -- markup.aside.kind
  bright_blue    = "#5482ff",      -- url
  bright_magenta = "#fd87ba",      -- derived
  bright_cyan    = "#86e2ff",      -- derived
  bright_white   = "#ffffff",      -- plain

  comment       = "#6c7986",       -- xcode.syntax.comment
  border        = "#515b70",
  cursor        = "#fc5fa3",       -- pink keyword (the theme's brand)
  accent        = "#9ef1dd",       -- aqua type (focus/interactive)

  -- Outside the ANSI 16, but Xcode uses them a lot and tokyonight has a slot.
  purple        = "#d0a8ff",       -- identifier.type.system
  purple_deep   = "#a167e6",       -- identifier.function.system
  orange        = "#fd8f3f",       -- preprocessor / macro
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
    c.blue1     = palette.cyan
    c.blue2     = palette.blue
    c.blue5     = palette.cyan
    c.blue6     = palette.bright_cyan
    c.blue7     = palette.bright_blue
    c.cyan      = palette.cyan
    c.magenta   = palette.magenta
    c.magenta2  = palette.bright_magenta
    -- Xcode DOES have its own purple (the "system" identifiers), so
    -- there's no need to recycle the magenta here — other themes in the repo
    -- do, because their ANSI palette has no purple.
    c.purple    = palette.purple
    c.orange    = palette.orange

    c.git = {
      add    = palette.green,
      change = palette.yellow,
      delete = palette.red,
    }
    c.terminal_black = palette.bright_black
  end,

  on_highlights = function(hl, c)
    hl.CursorLine   = { bg = "#0d0d0d" }       -- minimal lift over #000
    hl.CursorLineNr = { fg = palette.cursor, bold = true }
    hl.LineNr       = { fg = c.fg_gutter }

    hl.FloatBorder = { fg = palette.border, bg = c.bg_float }
    hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

    hl.TelescopeBorder       = { fg = palette.border, bg = c.bg_float }
    hl.TelescopePromptBorder = { fg = palette.accent, bg = c.bg_float }
    hl.TelescopeMatching     = { fg = palette.bright_yellow, bold = true }

    hl.GitSignsAdd    = { fg = c.green }
    hl.GitSignsChange = { fg = c.yellow }
    hl.GitSignsDelete = { fg = c.red }

    -- Inline code: barely raised bg + aqua (Xcode's "type").
    local code_bg = "#1f1f24"                  -- Xcode's own bg used as the raised one
    local code_fg = palette.bright_green
    hl["@markup.raw"]                  = { bg = code_bg, fg = code_fg }
    hl["@markup.raw.markdown_inline"]  = { bg = code_bg, fg = code_fg }
    hl["@text.literal"]                = { bg = code_bg, fg = code_fg }
    hl["@text.literal.markdown_inline"]= { bg = code_bg, fg = code_fg }
    hl.markdownCode                    = { bg = code_bg, fg = code_fg }
    hl.markdownCodeDelimiter           = { fg = palette.fg_gutter }
    hl["@markup.raw.block"]            = { bg = code_bg }
    hl.markdownCodeBlock               = { bg = code_bg }

    -- Headings: pink → aqua → gold hierarchy (keyword, type, number).
    hl["@markup.heading.1.markdown"]   = { fg = palette.magenta,      bold = true }
    hl["@markup.heading.2.markdown"]   = { fg = palette.bright_green, bold = true }
    hl["@markup.heading.3.markdown"]   = { fg = palette.yellow,       bold = true }

    hl["@markup.link.url"]   = { fg = palette.bright_blue, underline = true }
    hl["@markup.link.label"] = { fg = palette.magenta }

    -- ─── syntax: Xcode's roles, not tokyonight's ───────────────
    -- THIS is the theme. Without this block tokyonight applies ITS semantics
    -- over our palette (String→green, Keyword→cyan) and you end up with a theme
    -- that has Xcode's colors but another editor's highlighting.
    -- Each group is tied to the equivalent token from Apple's plist.
    --
    -- Criteria in the two cases where treesitter and Xcode don't overlap:
    --   · @variable → plain fg. Xcode paints teal the identifiers
    --     its index resolves; treesitter paints ALL of them. Coloring every
    --     local would be far noisier than the real editor.
    --   · @operator and punctuation → plain fg, as in Xcode.
    local xc = {
      keyword   = palette.magenta,      -- xcode.syntax.keyword
      string    = palette.red,          -- xcode.syntax.string
      number    = palette.yellow,       -- xcode.syntax.number / .character
      comment   = palette.comment,      -- xcode.syntax.comment
      preproc   = palette.orange,       -- xcode.syntax.preprocessor / .identifier.macro
      typ       = palette.bright_green, -- xcode.syntax.identifier.type      (aqua, "project")
      typ_sys   = palette.purple,       -- xcode.syntax.identifier.type.system
      func      = palette.green,        -- xcode.syntax.identifier.function  (teal, "project")
      func_sys  = palette.purple_deep,  -- xcode.syntax.identifier.function.system
      attribute = "#bf8555",            -- xcode.syntax.attribute
      declared  = palette.cyan,         -- xcode.syntax.declaration.type
      plain     = palette.fg,           -- xcode.syntax.plain
    }

    -- Classic vim groups (used by the legacy syntax and several plugins).
    hl.Comment    = { fg = xc.comment, italic = true }
    hl.Keyword    = { fg = xc.keyword }
    hl.Statement  = { fg = xc.keyword }
    hl.Conditional= { fg = xc.keyword }
    hl.Repeat     = { fg = xc.keyword }
    hl.Exception  = { fg = xc.keyword }
    hl.Operator   = { fg = xc.plain }
    hl.String     = { fg = xc.string }
    hl.Character  = { fg = xc.number }
    hl.Number     = { fg = xc.number }
    hl.Float      = { fg = xc.number }
    hl.Boolean    = { fg = xc.func_sys }
    hl.Constant   = { fg = xc.func }
    hl.Identifier = { fg = xc.plain }
    hl.Function   = { fg = xc.func }
    hl.Type       = { fg = xc.typ }
    hl.StorageClass = { fg = xc.keyword }
    hl.Structure  = { fg = xc.typ }
    hl.PreProc    = { fg = xc.preproc }
    hl.Include    = { fg = xc.preproc }
    hl.Define     = { fg = xc.preproc }
    hl.Macro      = { fg = xc.preproc }
    hl.Special    = { fg = xc.number }

    -- Treesitter (what actually paints in this nvim).
    hl["@comment"]              = { fg = xc.comment, italic = true }
    hl["@keyword"]              = { fg = xc.keyword }
    hl["@keyword.function"]     = { fg = xc.keyword }
    hl["@keyword.operator"]     = { fg = xc.keyword }
    hl["@keyword.return"]       = { fg = xc.keyword }
    hl["@keyword.conditional"]  = { fg = xc.keyword }
    hl["@keyword.repeat"]       = { fg = xc.keyword }
    hl["@keyword.exception"]    = { fg = xc.keyword }
    hl["@keyword.import"]       = { fg = xc.preproc }
    hl["@keyword.directive"]    = { fg = xc.preproc }
    hl["@keyword.storage"]      = { fg = xc.keyword }
    hl["@string"]               = { fg = xc.string }
    hl["@string.escape"]        = { fg = xc.number }
    hl["@string.special"]       = { fg = xc.number }
    hl["@character"]            = { fg = xc.number }
    hl["@number"]               = { fg = xc.number }
    hl["@number.float"]         = { fg = xc.number }
    hl["@boolean"]              = { fg = xc.func_sys }
    hl["@constant"]             = { fg = xc.func }
    hl["@constant.builtin"]     = { fg = xc.func_sys }
    hl["@constant.macro"]       = { fg = xc.preproc }
    hl["@type"]                 = { fg = xc.typ }
    hl["@type.definition"]      = { fg = xc.declared }
    hl["@type.builtin"]         = { fg = xc.typ_sys }
    hl["@constructor"]          = { fg = xc.typ }
    hl["@function"]             = { fg = xc.func }
    hl["@function.call"]        = { fg = xc.func }
    hl["@function.method"]      = { fg = xc.func }
    hl["@function.method.call"] = { fg = xc.func }
    hl["@function.builtin"]     = { fg = xc.func_sys }
    hl["@function.macro"]       = { fg = xc.preproc }
    hl["@variable"]             = { fg = xc.plain }
    hl["@variable.builtin"]     = { fg = xc.func_sys }
    hl["@variable.parameter"]   = { fg = xc.plain }
    hl["@variable.member"]      = { fg = xc.func }
    hl["@property"]             = { fg = xc.func }
    hl["@field"]                = { fg = xc.func }
    hl["@attribute"]            = { fg = xc.attribute }
    hl["@module"]               = { fg = xc.typ }
    hl["@operator"]             = { fg = xc.plain }
    hl["@punctuation.bracket"]  = { fg = xc.plain }
    hl["@punctuation.delimiter"]= { fg = xc.plain }
    hl["@punctuation.special"]  = { fg = xc.plain }

    -- LSP semantic tokens: they win over treesitter when the server sends
    -- them, so without this a buffer with an active LSP reverts to
    -- tokyonight's colors and the theme looks different per filetype.
    hl["@lsp.type.class"]     = { fg = xc.typ }
    hl["@lsp.type.enum"]      = { fg = xc.typ }
    hl["@lsp.type.interface"] = { fg = xc.typ }
    hl["@lsp.type.struct"]    = { fg = xc.typ }
    hl["@lsp.type.type"]      = { fg = xc.typ }
    hl["@lsp.type.function"]  = { fg = xc.func }
    hl["@lsp.type.method"]    = { fg = xc.func }
    hl["@lsp.type.property"]  = { fg = xc.func }
    hl["@lsp.type.variable"]  = { fg = xc.plain }
    hl["@lsp.type.parameter"] = { fg = xc.plain }
    hl["@lsp.type.macro"]     = { fg = xc.preproc }
    hl["@lsp.type.keyword"]   = { fg = xc.keyword }
    hl["@lsp.type.string"]    = { fg = xc.string }
    hl["@lsp.type.number"]    = { fg = xc.number }
    hl["@lsp.type.comment"]   = { fg = xc.comment, italic = true }
  end,
}
