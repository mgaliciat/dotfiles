-- ─── render-markdown.nvim ─────────────────────────────────────
-- Renders markdown in-buffer in normal mode: headings with icon
-- + color, code blocks with background, checkbox glyphs, bullets,
-- aligned pipe tables. When you enter insert it goes back to raw text.
--
-- Dependencies: nvim-treesitter with the `markdown` + `markdown_inline` parsers
-- (already installed in plugins/treesitter.lua).
--
-- Glyphs use a nerd font (your Ghostty already has it — Starship requires it).
--
-- Why this plugin and not `peek.nvim` / `markdown-preview.nvim` /
-- `leaf -w` in a split: in-place render avoids the context-switch. You edit in
-- insert (raw markdown), switch to normal and see it formatted without moving
-- pane. For "reading a big doc with a TOC", leaf is still the better option.

return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  keys = {
    { "<leader>cm",
      function() require("render-markdown").toggle() end,
      desc = "Toggle markdown render",
      ft = "markdown",
    },
  },
  opts = {
    file_types = { "markdown" },

    -- Headings: org-mode style with graduated icons. `sign = false` avoids
    -- the extra icon in the signcolumn (which we reserve for LSP/git).
    heading = {
      sign = false,
      icons = { "◉ ", "○ ", "✸ ", "✿ ", "◆ ", "▪ " },
      width = "block",     -- the heading background only covers the text, not the whole line
    },

    -- Code blocks: full background, language label on the left.
    -- `width = "block"` prevents the bg from stretching across the whole screen
    -- (which looks odd in wide splits).
    code = {
      style    = "full",
      width    = "block",
      position = "left",
      border   = "thick",
      language_pad = 1,
    },

    -- Bullets: visual hierarchy by nesting level.
    bullet = {
      icons = { "•", "◦", "▪", "▫" },
    },

    -- Checkboxes: nerd font glyphs + custom "in progress" (`[-]`, typical
    -- of many note-taking systems).
    checkbox = {
      unchecked = { icon = "󰄱 " },
      checked   = { icon = "󰱒 " },
      custom = {
        todo = { raw = "[-]", rendered = "󰥔 ", highlight = "DiagnosticWarn" },
      },
    },

    -- Horizontal lines `---` are shown as a full-width rule.
    dash = { width = "full" },

    -- `|...|` tables aligned with box-drawing borders.
    pipe_table = { style = "full" },

    -- Quote blocks `>` with a colored side bar.
    quote = { repeat_linebreak = true },
  },
}
