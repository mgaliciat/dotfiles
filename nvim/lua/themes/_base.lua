-- ─── theme: _base ────────────────────────────────────────────
-- What every palette in lua/themes/ does the same way: map the palette onto
-- tokyonight's slots and paint the groups whose role does not change from one
-- theme to the next (cursorline, floats, the telescope frame, gitsigns, code).
-- A theme module passes its palette plus what it genuinely does differently,
-- and gets back the module shape colorscheme.lua documents.
--
-- Not a theme id: colorscheme.lua only ever requires `themes.<vim.g.theme>`,
-- and scripts/theme accepts an id only when ghostty/themes/<id> exists.
--
-- spec:
--   style, palette, transparent   passed through untouched
--   code = { bg, fg, delimiter }  inline/fenced markdown code, each optional
--                                 (bg_dark, accent, fg_gutter)
--   on_colors(c)                  runs AFTER the shared mapping, to re-point slots
--   on_highlights(hl, c)          runs AFTER the shared groups
--
-- on_highlights runs inside `:colorscheme`, outside colorscheme.lua's pcall
-- fallback, so nothing here may index a spec key a theme can leave out.

return function(spec)
  local palette = spec.palette
  local given   = spec.code or {}
  local code    = {
    bg        = given.bg        or palette.bg_dark,
    fg        = given.fg        or palette.accent,
    delimiter = given.delimiter or palette.fg_gutter,
  }

  return {
    style       = spec.style,
    palette     = palette,
    transparent = spec.transparent,

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
      c.green1    = palette.green
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

      c.git = {
        add    = palette.green,
        change = palette.yellow,
        delete = palette.red,
      }
      c.terminal_black = palette.bright_black

      if spec.on_colors then
        spec.on_colors(c)
      end
    end,

    on_highlights = function(hl, c)
      hl.CursorLine   = { bg = palette.bg_highlight }
      hl.CursorLineNr = { fg = palette.accent, bold = true }
      hl.LineNr       = { fg = c.fg_gutter }

      hl.FloatBorder = { fg = palette.border, bg = c.bg_float }
      hl.NormalFloat = { fg = c.fg, bg = c.bg_float }

      hl.TelescopeBorder       = { fg = palette.border, bg = c.bg_float }
      hl.TelescopePromptBorder = { fg = palette.accent, bg = c.bg_float }

      -- c.git, not c.green: a theme may re-point green at its strings (retta).
      hl.GitSignsAdd    = { fg = c.git.add }
      hl.GitSignsChange = { fg = c.git.change }
      hl.GitSignsDelete = { fg = c.git.delete }

      hl["@markup.raw"]                  = { bg = code.bg, fg = code.fg }
      hl["@markup.raw.markdown_inline"]  = { bg = code.bg, fg = code.fg }
      hl.markdownCode                    = { bg = code.bg, fg = code.fg }
      hl.markdownCodeDelimiter           = { fg = code.delimiter }
      hl["@markup.raw.block"]            = { bg = code.bg }
      hl.markdownCodeBlock               = { bg = code.bg }

      if spec.on_highlights then
        spec.on_highlights(hl, c)
      end
    end,
  }
end
