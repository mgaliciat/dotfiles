-- ─── render-markdown.nvim ─────────────────────────────────────
-- Renderiza markdown in-buffer en modo normal: headings con icon
-- + color, code blocks con background, checkboxes glyph, bullets,
-- pipe tables alineadas. Al entrar en insert vuelve al texto crudo.
--
-- Dependencias: nvim-treesitter con parsers `markdown` + `markdown_inline`
-- (ya instalados en plugins/treesitter.lua).
--
-- Glyphs usan nerd font (tu Ghostty ya lo tiene — Starship lo requiere).
--
-- Por qué este plugin y no `peek.nvim` / `markdown-preview.nvim` /
-- `leaf -w` en split: render in-place evita context-switch. Editás en
-- insert (markdown crudo), pasás a normal y lo ves formateado sin moverte
-- de pane. Para "leer doc grande con TOC", leaf sigue siendo mejor opción.

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

    -- Headings: estilo org-mode con icons graduales. `sign = false` evita
    -- el icono extra en signcolumn (que reservamos para LSP/git).
    heading = {
      sign = false,
      icons = { "◉ ", "○ ", "✸ ", "✿ ", "◆ ", "▪ " },
      width = "block",     -- background del heading solo cubre el texto, no toda la línea
    },

    -- Code blocks: background full, label de lenguaje a la izquierda.
    -- `width = "block"` evita que el bg se extienda a toda la pantalla
    -- (que en splits anchos se ve raro).
    code = {
      style    = "full",
      width    = "block",
      position = "left",
      border   = "thick",
      language_pad = 1,
    },

    -- Bullets: jerarquía visual por nivel de anidación.
    bullet = {
      icons = { "•", "◦", "▪", "▫" },
    },

    -- Checkboxes: glyphs nerd font + custom "in progress" (`[-]` típico
    -- de muchos sistemas de notas).
    checkbox = {
      unchecked = { icon = "󰄱 " },
      checked   = { icon = "󰱒 " },
      custom = {
        todo = { raw = "[-]", rendered = "󰥔 ", highlight = "DiagnosticWarn" },
      },
    },

    -- Líneas horizontales `---` se muestran como rule full-width.
    dash = { width = "full" },

    -- Tablas `|...|` alineadas con bordes box-drawing.
    pipe_table = { style = "full" },

    -- Quote blocks `>` con barra lateral coloreada.
    quote = { repeat_linebreak = true },
  },
}
