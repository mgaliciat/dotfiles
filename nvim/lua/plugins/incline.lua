-- ─── incline.nvim ─────────────────────────────────────────────
-- Filename flotante en la esquina superior derecha de cada split.
-- Resuelve el problema clásico: el statusline (lualine) solo muestra
-- el path del split activo — en layouts con 3+ ventanas no sabés
-- qué archivo es cuál sin enfocarlo primero.
--
-- Colores: hardcoded a paleta solarized-osaka porque es el theme
-- activo (magenta500 + base04). Si cambiás a anthropic-dark u otro
-- via vim.g.theme, los colores del indicator van a quedar fuera de
-- paleta — tunealo acá o pasalo a derivar de highlight groups.

return {
  "b0o/incline.nvim",
  dependencies = {
    "craftzdog/solarized-osaka.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  event = "BufReadPre",
  priority = 1200,
  config = function()
    local ok, sol = pcall(require, "solarized-osaka.colors")
    local colors = ok and sol.setup() or {
      magenta500 = "#d33682",
      base03     = "#002b36",
      base04     = "#001e26",
      violet500  = "#6c71c4",
    }

    require("incline").setup({
      highlight = {
        groups = {
          InclineNormal   = { guibg = colors.magenta500, guifg = colors.base04 },
          InclineNormalNC = { guifg = colors.violet500,  guibg = colors.base03 },
        },
      },
      window = { margin = { vertical = 0, horizontal = 1 } },
      -- Oculta el indicator cuando el cursor está en su misma fila para
      -- que no tape texto.
      hide = { cursorline = true },
      render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
        if filename == "" then filename = "[No Name]" end
        if vim.bo[props.buf].modified then
          filename = "[+] " .. filename
        end
        local icon, color = require("nvim-web-devicons").get_icon_color(filename)
        return { { icon, guifg = color }, { " " }, { filename } }
      end,
    })
  end,
}
